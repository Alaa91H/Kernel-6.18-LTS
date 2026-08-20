#!/usr/bin/env python3
"""Statically inspect Android boot, vendor_boot and DTBO container headers.

The tool only reads binary headers and records metadata in JSON. It does not
unpack ramdisks, execute files, sign images, or interact with a device.

Usage:
    inspect_android_boot_artifacts.py BOOT_IMG VENDOR_BOOT_IMG DTBO_IMG OUTPUT_JSON
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import struct
import sys

ANDROID_MAGIC = b"ANDROID!"
VENDOR_BOOT_MAGIC = b"VNDRBOOT"
DTBO_MAGIC = 0xD7B7AB1E


def align(value: int, boundary: int) -> int:
    return ((value + boundary - 1) // boundary) * boundary


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from("<I", data, offset)[0]


def u64(data: bytes, offset: int) -> int:
    return struct.unpack_from("<Q", data, offset)[0]


def be_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def clean_string(value: bytes) -> str:
    return value.split(b"\0", 1)[0].decode("utf-8", errors="replace")


def scan_kernel_versions(path: pathlib.Path) -> list[str]:
    marker = b"Linux version "
    versions: list[str] = []
    with path.open("rb") as stream:
        data = stream.read()
    start = 0
    while True:
        index = data.find(marker, start)
        if index < 0:
            break
        end = data.find(b"\0", index)
        if end < 0:
            end = min(len(data), index + 512)
        value = data[index:end].decode("utf-8", errors="replace")
        if value not in versions:
            versions.append(value)
        start = index + len(marker)
    return versions


def inspect_boot(path: pathlib.Path) -> dict[str, object]:
    with path.open("rb") as stream:
        header = stream.read(4096)
    if header[:8] != ANDROID_MAGIC:
        raise ValueError(f"{path}: unexpected boot magic {header[:8]!r}")
    kernel_size = u32(header, 8)
    ramdisk_size = u32(header, 12)
    os_version = u32(header, 16)
    header_size = u32(header, 20)
    header_version = u32(header, 40)
    command_line = clean_string(header[44 : 44 + 1536])
    signature_size = u32(header, 1580) if header_version >= 4 and len(header) >= 1584 else None
    page_size = 4096  # Android boot image v3/v4 definition.
    kernel_offset = page_size
    ramdisk_offset = align(kernel_offset + kernel_size, page_size)
    signature_offset = align(ramdisk_offset + ramdisk_size, page_size) if signature_size else None
    return {
        "type": "boot",
        "path": str(path),
        "bytes": path.stat().st_size,
        "sha256": hashlib.file_digest(path.open("rb"), "sha256").hexdigest(),
        "header_version": header_version,
        "header_size": header_size,
        "page_size": page_size,
        "kernel_size": kernel_size,
        "kernel_offset": kernel_offset,
        "ramdisk_size": ramdisk_size,
        "ramdisk_offset": ramdisk_offset,
        "signature_size": signature_size,
        "signature_offset": signature_offset,
        "os_version_raw": os_version,
        "command_line": command_line,
        "kernel_version_strings": scan_kernel_versions(path),
    }


def inspect_vendor_boot(path: pathlib.Path) -> dict[str, object]:
    with path.open("rb") as stream:
        header = stream.read(4096)
    if header[:8] != VENDOR_BOOT_MAGIC:
        raise ValueError(f"{path}: unexpected vendor_boot magic {header[:8]!r}")
    header_version = u32(header, 8)
    page_size = u32(header, 12)
    kernel_addr = u32(header, 16)
    ramdisk_addr = u32(header, 20)
    vendor_ramdisk_size = u32(header, 24)
    command_line = clean_string(header[28 : 28 + 2048])
    tags_addr = u32(header, 2076)
    product_name = clean_string(header[2080 : 2080 + 16])
    header_size = u32(header, 2096)
    dtb_size = u32(header, 2100)
    dtb_addr = u64(header, 2104)
    result: dict[str, object] = {
        "type": "vendor_boot",
        "path": str(path),
        "bytes": path.stat().st_size,
        "sha256": hashlib.file_digest(path.open("rb"), "sha256").hexdigest(),
        "header_version": header_version,
        "header_size": header_size,
        "page_size": page_size,
        "kernel_addr": kernel_addr,
        "ramdisk_addr": ramdisk_addr,
        "vendor_ramdisk_size": vendor_ramdisk_size,
        "command_line": command_line,
        "tags_addr": tags_addr,
        "product_name": product_name,
        "dtb_size": dtb_size,
        "dtb_addr": dtb_addr,
        "vendor_ramdisk_offset": page_size,
        "dtb_offset": align(page_size + vendor_ramdisk_size, page_size),
    }
    if header_version >= 4:
        table_size = u32(header, 2112)
        entry_count = u32(header, 2116)
        entry_size = u32(header, 2120)
        bootconfig_size = u32(header, 2124)
        table_offset = align(result["dtb_offset"] + dtb_size, page_size)
        entries: list[dict[str, object]] = []
        with path.open("rb") as stream:
            stream.seek(table_offset)
            table = stream.read(table_size)
        for index in range(entry_count):
            offset = index * entry_size
            if offset + min(entry_size, 108) > len(table) or entry_size < 108:
                raise ValueError(f"{path}: invalid vendor ramdisk table entry {index}")
            entries.append(
                {
                    "index": index,
                    "size": u32(table, offset),
                    "offset": u32(table, offset + 4),
                    "type": u32(table, offset + 8),
                    "name": clean_string(table[offset + 12 : offset + 44]),
                    "board_id": [u32(table, offset + 44 + (item * 4)) for item in range(16)],
                }
            )
        result.update(
            {
                "vendor_ramdisk_table_size": table_size,
                "vendor_ramdisk_table_offset": table_offset,
                "vendor_ramdisk_table_entry_count": entry_count,
                "vendor_ramdisk_table_entry_size": entry_size,
                "bootconfig_size": bootconfig_size,
                "bootconfig_offset": align(table_offset + table_size, page_size),
                "vendor_ramdisk_entries": entries,
            }
        )
    return result


def inspect_dtbo(path: pathlib.Path) -> dict[str, object]:
    with path.open("rb") as stream:
        header = stream.read(32)
    # dt_table headers and entries are stored in big-endian byte order.
    if len(header) < 32 or be_u32(header, 0) != DTBO_MAGIC:
        raise ValueError(f"{path}: not a dt_table DTBO image")
    total_size = be_u32(header, 4)
    header_size = be_u32(header, 8)
    entry_size = be_u32(header, 12)
    entry_count = be_u32(header, 16)
    entries_offset = be_u32(header, 20)
    page_size = be_u32(header, 24)
    version = be_u32(header, 28)
    entries: list[dict[str, int]] = []
    with path.open("rb") as stream:
        stream.seek(entries_offset)
        table = stream.read(entry_size * entry_count)
    for index in range(entry_count):
        offset = index * entry_size
        if offset + 32 > len(table):
            raise ValueError(f"{path}: truncated DTBO entry {index}")
        entries.append(
            {
                "index": index,
                "dt_size": be_u32(table, offset),
                "dt_offset": be_u32(table, offset + 4),
                "id": be_u32(table, offset + 8),
                "rev": be_u32(table, offset + 12),
                "custom_0": be_u32(table, offset + 16),
                "custom_1": be_u32(table, offset + 20),
                "custom_2": be_u32(table, offset + 24),
                "custom_3": be_u32(table, offset + 28),
            }
        )
    return {
        "type": "dtbo",
        "path": str(path),
        "bytes": path.stat().st_size,
        "sha256": hashlib.file_digest(path.open("rb"), "sha256").hexdigest(),
        "total_size": total_size,
        "header_size": header_size,
        "entry_size": entry_size,
        "entry_count": entry_count,
        "entries_offset": entries_offset,
        "page_size": page_size,
        "version": version,
        "entries": entries,
    }


def main() -> int:
    if len(sys.argv) != 5:
        print(f"Usage: {pathlib.Path(sys.argv[0]).name} BOOT_IMG VENDOR_BOOT_IMG DTBO_IMG OUTPUT_JSON", file=sys.stderr)
        return 2
    boot, vendor_boot, dtbo, output = (pathlib.Path(value).resolve() for value in sys.argv[1:])
    result = {
        "boot": inspect_boot(boot),
        "vendor_boot": inspect_vendor_boot(vendor_boot),
        "dtbo": inspect_dtbo(dtbo),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
