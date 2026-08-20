#!/usr/bin/env python3
"""Extract selected full-OTA partitions from an Android CrAU payload.

Safety properties:
* Only REPLACE, REPLACE_BZ and REPLACE_XZ are accepted.
* Delta/source operations are rejected rather than guessed.
* Output SHA-256 is verified against new_partition_info.hash.
* The program only writes ordinary image files; it never invokes update_engine,
  fastboot, a boot-image tool, or any executable stored in an OTA.

Usage:
    extract_android_ota_partitions.py PAYLOAD_BIN OUTPUT_DIRECTORY PARTITION [PARTITION ...]
"""
from __future__ import annotations

import bz2
import hashlib
import lzma
import os
import pathlib
import re
import sys

from inspect_android_ota_payload import OPERATION_NAMES, all_bytes, first_bytes, first_varint, parse_fields

BLOCK_SIZE_DEFAULT = 4096
SUPPORTED_TYPES = {0: "REPLACE", 1: "REPLACE_BZ", 8: "REPLACE_XZ"}
SAFE_PARTITION = re.compile(r"^[A-Za-z0-9_.-]+$")


def read_payload_metadata(payload_path: pathlib.Path) -> tuple[bytes, int, bytes, int]:
    with payload_path.open("rb") as stream:
        header = stream.read(24)
        if len(header) < 20 or header[:4] != b"CrAU":
            raise ValueError("input is not an Android CrAU payload")
        version = int.from_bytes(header[4:12], "big")
        manifest_size = int.from_bytes(header[12:20], "big")
        header_size = 20
        metadata_signature_size = 0
        if version >= 2:
            if len(header) < 24:
                raise ValueError("truncated CrAU v2 header")
            metadata_signature_size = int.from_bytes(header[20:24], "big")
            header_size = 24
        manifest = stream.read(manifest_size)
        if len(manifest) != manifest_size:
            raise ValueError("truncated payload manifest")
    return manifest, header_size + manifest_size + metadata_signature_size, header, version


def partition_updates(manifest: bytes) -> tuple[int, dict[str, bytes]]:
    fields = parse_fields(manifest)
    block_size = first_varint(fields, 3) or BLOCK_SIZE_DEFAULT
    updates: dict[str, bytes] = {}
    for update_blob in all_bytes(fields, 13):
        update_fields = parse_fields(update_blob)
        name_raw = first_bytes(update_fields, 1)
        if name_raw is None:
            raise ValueError("partition update lacks a name")
        name = name_raw.decode("utf-8", errors="strict")
        updates[name] = update_blob
    return block_size, updates


def extents(extent_messages: list[bytes]) -> list[tuple[int, int]]:
    result: list[tuple[int, int]] = []
    for raw in extent_messages:
        fields = parse_fields(raw)
        start = first_varint(fields, 1)
        count = first_varint(fields, 2)
        if start is None or count is None:
            raise ValueError("extent lacks start_block or num_blocks")
        result.append((start, count))
    return result


def inflate(type_code: int, compressed: bytes) -> bytes:
    if type_code == 0:
        return compressed
    if type_code == 1:
        return bz2.decompress(compressed)
    if type_code == 8:
        return lzma.decompress(compressed)
    raise ValueError(f"unsupported operation {OPERATION_NAMES.get(type_code, type_code)}")


def write_extent_data(output, payload: bytes, destination: list[tuple[int, int]], block_size: int) -> None:
    offset = 0
    for start_block, block_count in destination:
        extent_bytes = block_count * block_size
        chunk = payload[offset : offset + extent_bytes]
        output.seek(start_block * block_size)
        output.write(chunk)
        offset += len(chunk)
        # REPLACE operations may omit the zero tail of the final block range;
        # images are pre-truncated and thus preserve a zero-filled sparse tail.
        if len(chunk) < extent_bytes:
            break
    if offset != len(payload):
        raise ValueError("operation data exceeds declared destination extents")


def extract_partition(payload_path: pathlib.Path, output_dir: pathlib.Path, name: str, update_blob: bytes, block_size: int, data_offset: int) -> dict[str, object]:
    fields = parse_fields(update_blob)
    new_info = first_bytes(fields, 7)
    if new_info is None:
        raise ValueError(f"{name}: missing new_partition_info")
    new_info_fields = parse_fields(new_info)
    new_size = first_varint(new_info_fields, 1)
    expected_hash = first_bytes(new_info_fields, 2)
    if new_size is None or expected_hash is None:
        raise ValueError(f"{name}: incomplete new_partition_info")

    operations = all_bytes(fields, 8)
    output_path = output_dir / f"{name}.img"
    with payload_path.open("rb") as source, output_path.open("wb") as target:
        target.truncate(new_size)
        for index, operation_blob in enumerate(operations):
            operation = parse_fields(operation_blob)
            type_code = first_varint(operation, 1)
            if type_code not in SUPPORTED_TYPES:
                label = OPERATION_NAMES.get(type_code, f"UNKNOWN_{type_code}")
                raise ValueError(f"{name}: operation {index} is {label}, not a full-OTA replace operation")
            compressed_length = first_varint(operation, 3)
            relative_offset = first_varint(operation, 2)
            if compressed_length is None or relative_offset is None:
                raise ValueError(f"{name}: operation {index} lacks data offset or length")
            source.seek(data_offset + relative_offset)
            compressed = source.read(compressed_length)
            if len(compressed) != compressed_length:
                raise ValueError(f"{name}: truncated operation {index} blob")
            raw = inflate(type_code, compressed)
            write_extent_data(target, raw, extents(all_bytes(operation, 6)), block_size)
        target.flush()
        os.fsync(target.fileno())

    actual_hash = hashlib.file_digest(output_path.open("rb"), "sha256").digest()
    if actual_hash != expected_hash:
        output_path.unlink(missing_ok=True)
        raise ValueError(
            f"{name}: SHA-256 mismatch; expected {expected_hash.hex()}, got {actual_hash.hex()}"
        )
    return {
        "partition": name,
        "path": str(output_path),
        "bytes": new_size,
        "sha256": actual_hash.hex(),
        "operations": len(operations),
    }


def main() -> int:
    if len(sys.argv) < 4:
        print(f"Usage: {pathlib.Path(sys.argv[0]).name} PAYLOAD_BIN OUTPUT_DIRECTORY PARTITION [PARTITION ...]", file=sys.stderr)
        return 2
    payload_path = pathlib.Path(sys.argv[1]).resolve()
    output_dir = pathlib.Path(sys.argv[2]).resolve()
    wanted = sys.argv[3:]
    if not payload_path.is_file():
        print(f"payload not found: {payload_path}", file=sys.stderr)
        return 2
    if any(not SAFE_PARTITION.fullmatch(name) for name in wanted):
        print("unsafe partition name requested", file=sys.stderr)
        return 2

    manifest, data_offset, _, _ = read_payload_metadata(payload_path)
    block_size, updates = partition_updates(manifest)
    missing = [name for name in wanted if name not in updates]
    if missing:
        print(f"requested partitions absent from payload: {', '.join(missing)}", file=sys.stderr)
        return 1

    output_dir.mkdir(parents=True, exist_ok=True)
    for name in wanted:
        result = extract_partition(payload_path, output_dir, name, updates[name], block_size, data_offset)
        print("{partition}\t{bytes}\t{sha256}\t{path}".format(**result))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
