#!/usr/bin/env python3
"""Inspect an Android update_engine payload without applying or executing it.

The tool parses only the CrAU header and DeltaArchiveManifest protobuf fields
needed for a static inventory. It does not write partition data, invoke update
engine, or load any payload content as code.

Usage:
    inspect_android_ota_payload.py PAYLOAD_BIN OUTPUT_DIRECTORY
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import sys
from collections import Counter

OPERATION_NAMES = {
    0: "REPLACE",
    1: "REPLACE_BZ",
    2: "MOVE",
    3: "BSDIFF",
    4: "SOURCE_COPY",
    5: "SOURCE_BSDIFF",
    6: "ZERO",
    7: "DISCARD",
    8: "REPLACE_XZ",
    9: "PUFFDIFF",
    10: "BROTLI_BSDIFF",
    11: "ZUCCHINI",
    12: "LZ4DIFF_BSDIFF",
    13: "LZ4DIFF_PUFFDIFF",
    14: "BROTLI_BROTLI",
    15: "PUFFDIFF_BSDIFF",
    16: "ZUCCHINI_BSDIFF",
    17: "LZ4DIFF",
}


def read_varint(data: bytes, pos: int) -> tuple[int, int]:
    value = 0
    shift = 0
    while pos < len(data):
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, pos
        shift += 7
        if shift > 70:
            raise ValueError("protobuf varint is too large")
    raise ValueError("truncated protobuf varint")


def parse_fields(data: bytes) -> list[tuple[int, int, object]]:
    fields: list[tuple[int, int, object]] = []
    pos = 0
    while pos < len(data):
        key, pos = read_varint(data, pos)
        number = key >> 3
        wire_type = key & 0x7
        if number == 0:
            raise ValueError("invalid protobuf field number 0")
        if wire_type == 0:
            value, pos = read_varint(data, pos)
        elif wire_type == 1:
            if pos + 8 > len(data):
                raise ValueError("truncated fixed64 protobuf field")
            value = data[pos : pos + 8]
            pos += 8
        elif wire_type == 2:
            length, pos = read_varint(data, pos)
            if pos + length > len(data):
                raise ValueError("truncated length-delimited protobuf field")
            value = data[pos : pos + length]
            pos += length
        elif wire_type == 5:
            if pos + 4 > len(data):
                raise ValueError("truncated fixed32 protobuf field")
            value = data[pos : pos + 4]
            pos += 4
        else:
            raise ValueError(f"unsupported protobuf wire type {wire_type}")
        fields.append((number, wire_type, value))
    return fields


def first_varint(fields: list[tuple[int, int, object]], number: int) -> int | None:
    for field_number, wire_type, value in fields:
        if field_number == number and wire_type == 0:
            return int(value)
    return None


def first_bytes(fields: list[tuple[int, int, object]], number: int) -> bytes | None:
    for field_number, wire_type, value in fields:
        if field_number == number and wire_type == 2:
            return bytes(value)
    return None


def all_bytes(fields: list[tuple[int, int, object]], number: int) -> list[bytes]:
    return [bytes(value) for field_number, wire_type, value in fields if field_number == number and wire_type == 2]


def extent_blocks(extent_data: bytes) -> int:
    fields = parse_fields(extent_data)
    return first_varint(fields, 2) or 0


def parse_partition(partition_data: bytes) -> dict[str, object]:
    fields = parse_fields(partition_data)
    raw_name = first_bytes(fields, 1)
    if raw_name is None:
        raise ValueError("partition update has no partition_name")
    name = raw_name.decode("utf-8", errors="strict")
    # AOSP PartitionUpdate: old_partition_info=6, new_partition_info=7,
    # operations=8. Fields 4 and 5 are postinstall filesystem/signatures.
    new_info_raw = first_bytes(fields, 7)
    new_size = None
    new_hash = None
    if new_info_raw is not None:
        new_info = parse_fields(new_info_raw)
        new_size = first_varint(new_info, 1)
        raw_hash = first_bytes(new_info, 2)
        new_hash = raw_hash.hex() if raw_hash else None

    operation_counts: Counter[str] = Counter()
    destination_blocks = 0
    data_bytes = 0
    operations = all_bytes(fields, 8)
    for operation_data in operations:
        operation = parse_fields(operation_data)
        type_code = first_varint(operation, 1)
        operation_counts[OPERATION_NAMES.get(type_code, f"UNKNOWN_{type_code}")] += 1
        # AOSP InstallOperation: data_length=3 and dst_extents=6.
        data_length = first_varint(operation, 3)
        if data_length:
            data_bytes += data_length
        for extent in all_bytes(operation, 6):
            destination_blocks += extent_blocks(extent)

    return {
        "name": name,
        "new_size": new_size,
        "new_sha256": new_hash,
        "operation_count": len(operations),
        "operation_types": dict(sorted(operation_counts.items())),
        "destination_blocks": destination_blocks,
        "operation_data_bytes": data_bytes,
    }


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {pathlib.Path(sys.argv[0]).name} PAYLOAD_BIN OUTPUT_DIRECTORY", file=sys.stderr)
        return 2
    payload_path = pathlib.Path(sys.argv[1]).resolve()
    output_dir = pathlib.Path(sys.argv[2]).resolve()
    if not payload_path.is_file():
        print(f"Payload not found: {payload_path}", file=sys.stderr)
        return 2

    with payload_path.open("rb") as stream:
        header = stream.read(24)
        if len(header) < 20 or header[:4] != b"CrAU":
            print("Input is not an Android CrAU payload", file=sys.stderr)
            return 1
        version = int.from_bytes(header[4:12], "big")
        manifest_size = int.from_bytes(header[12:20], "big")
        header_size = 20
        metadata_signature_size = 0
        if version >= 2:
            if len(header) < 24:
                print("Truncated CrAU v2 header", file=sys.stderr)
                return 1
            metadata_signature_size = int.from_bytes(header[20:24], "big")
            header_size = 24
        manifest = stream.read(manifest_size)
        if len(manifest) != manifest_size:
            print("Truncated payload manifest", file=sys.stderr)
            return 1

    manifest_fields = parse_fields(manifest)
    partitions = [parse_partition(blob) for blob in all_bytes(manifest_fields, 13)]
    if not partitions:
        print("No partition updates found in DeltaArchiveManifest", file=sys.stderr)
        return 1

    payload_size = payload_path.stat().st_size
    metadata_size = header_size + manifest_size + metadata_signature_size
    inventory = {
        "payload": str(payload_path),
        "payload_bytes": payload_size,
        "payload_sha256": hashlib.file_digest(payload_path.open("rb"), "sha256").hexdigest(),
        "format": "CrAU",
        "format_version": version,
        "manifest_bytes": manifest_size,
        "metadata_signature_bytes": metadata_signature_size,
        "metadata_bytes": metadata_size,
        "data_offset": metadata_size,
        "partition_count": len(partitions),
        "partitions": sorted(partitions, key=lambda item: str(item["name"])),
    }

    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / "payload_inventory.json").write_text(json.dumps(inventory, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    with (output_dir / "payload_partitions.tsv").open("w", encoding="utf-8") as report:
        report.write("partition\tnew_size_bytes\toperation_count\tdestination_blocks\toperation_data_bytes\toperation_types\tnew_sha256\n")
        for partition in inventory["partitions"]:
            report.write(
                "{name}\t{size}\t{ops}\t{blocks}\t{data}\t{types}\t{digest}\n".format(
                    name=partition["name"],
                    size=partition["new_size"] if partition["new_size"] is not None else "",
                    ops=partition["operation_count"],
                    blocks=partition["destination_blocks"],
                    data=partition["operation_data_bytes"],
                    types=",".join(f"{key}:{value}" for key, value in partition["operation_types"].items()),
                    digest=partition["new_sha256"] or "",
                )
            )
    print(json.dumps({key: inventory[key] for key in ("format_version", "payload_bytes", "partition_count", "metadata_bytes")}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
