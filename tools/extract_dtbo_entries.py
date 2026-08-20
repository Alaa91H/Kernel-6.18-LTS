#!/usr/bin/env python3
"""Extract DTB blobs from an Android dt_table (DTBO) image for static review.

Usage:
    extract_dtbo_entries.py DTBO_IMAGE OUTPUT_DIRECTORY
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import struct
import sys

MAGIC = 0xD7B7AB1E


def be_u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {pathlib.Path(sys.argv[0]).name} DTBO_IMAGE OUTPUT_DIRECTORY", file=sys.stderr)
        return 2
    image = pathlib.Path(sys.argv[1]).resolve()
    output = pathlib.Path(sys.argv[2]).resolve()
    if not image.is_file():
        print(f"DTBO image not found: {image}", file=sys.stderr)
        return 2
    data = image.read_bytes()
    if len(data) < 32 or be_u32(data, 0) != MAGIC:
        print("input is not a dt_table image", file=sys.stderr)
        return 1
    total_size = be_u32(data, 4)
    entry_size = be_u32(data, 12)
    entry_count = be_u32(data, 16)
    entries_offset = be_u32(data, 20)
    if total_size > len(data) or entry_size < 32 or entries_offset + entry_size * entry_count > len(data):
        print("invalid dt_table bounds", file=sys.stderr)
        return 1

    output.mkdir(parents=True, exist_ok=True)
    inventory: list[dict[str, object]] = []
    for index in range(entry_count):
        offset = entries_offset + index * entry_size
        dt_size = be_u32(data, offset)
        dt_offset = be_u32(data, offset + 4)
        if dt_offset + dt_size > total_size:
            print(f"entry {index} exceeds dt_table bounds", file=sys.stderr)
            return 1
        blob = data[dt_offset : dt_offset + dt_size]
        path = output / f"entry-{index:02d}.dtb"
        path.write_bytes(blob)
        inventory.append(
            {
                "index": index,
                "path": str(path),
                "bytes": dt_size,
                "sha256": hashlib.sha256(blob).hexdigest(),
                "id": be_u32(data, offset + 8),
                "rev": be_u32(data, offset + 12),
            }
        )
    (output / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n", encoding="utf-8")
    print(f"extracted_entries={len(inventory)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
