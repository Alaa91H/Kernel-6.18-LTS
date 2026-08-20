#!/usr/bin/env python3
"""Generate a static module-porting contract for marble.

The tool compares module *names* from a reference ROM inventory against source
Makefiles in a reference kernel tree and the target ACK tree.  It does not
load, copy, sign, extract, or package modules.  Source matches are candidates
for human review only; a same name never implies KMI/ABI compatibility.
"""
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path
from typing import Iterable


def existing_directory(value: str) -> Path:
    path = Path(value).resolve()
    if not path.is_dir():
        raise argparse.ArgumentTypeError(f"not a directory: {path}")
    return path


def existing_file(value: str) -> Path:
    path = Path(value).resolve()
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"not a file: {path}")
    return path


def clean_module_name(value: str) -> str:
    name = value.strip()
    if not name or name.startswith("#"):
        return ""
    name = name.rsplit("/", 1)[-1]
    return name if name.endswith(".ko") else f"{name}.ko"


def read_module_lists(paths: Iterable[Path]) -> dict[str, set[str]]:
    stages: dict[str, set[str]] = {}
    for path in paths:
        stage = path.stem
        for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
            module = clean_module_name(raw)
            if module:
                stages.setdefault(module, set()).add(stage)
    return stages


def makefile_index(root: Path, modules: Iterable[str]) -> dict[str, list[str]]:
    """Index matching Makefiles once for all requested module names."""
    patterns = {
        module: re.compile(
            rf"(?<![A-Za-z0-9_-]){re.escape(module.removesuffix('.ko'))}"
            rf"(?:\.o|[-_][A-Za-z0-9_.-]+\.o)?(?![A-Za-z0-9_-])"
        )
        for module in modules
    }
    matches: dict[str, list[str]] = {module: [] for module in patterns}
    for makefile in root.rglob("Makefile"):
        try:
            content = makefile.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        relative = str(makefile.relative_to(root))
        for module, pattern in patterns.items():
            if pattern.search(content):
                matches[module].append(relative)
    return {module: sorted(paths) for module, paths in matches.items()}


def built_module_names(directory: Path) -> set[str]:
    return {path.name for path in directory.rglob("*.ko") if path.is_file()}


def builtin_module_names(directory: Path) -> set[str]:
    modules_builtin = directory / "modules.builtin"
    if not modules_builtin.is_file():
        return set()
    return {Path(line.strip()).name for line in modules_builtin.read_text(encoding="utf-8", errors="replace").splitlines() if line.strip().endswith(".ko")}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--reference-root", required=True, type=existing_directory)
    parser.add_argument("--target-root", required=True, type=existing_directory)
    parser.add_argument("--candidate-output", required=True, type=existing_directory)
    parser.add_argument("--module-list", required=True, action="append", type=existing_file,
                        help="Reference module list; repeat for each loading stage.")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    module_stages = read_module_lists(args.module_list)
    candidate_modules = built_module_names(args.candidate_output)
    candidate_builtin = builtin_module_names(args.candidate_output)
    reference_index = makefile_index(args.reference_root, module_stages)
    target_index = makefile_index(args.target_root, module_stages)

    rows: list[dict[str, str]] = []
    for module in sorted(module_stages):
        reference_sources = reference_index[module]
        target_sources = target_index[module]
        if module in candidate_modules:
            disposition = "built_6_18_module"
        elif module in candidate_builtin:
            disposition = "built_6_18_builtin"
        elif target_sources:
            disposition = "ack_source_candidate"
        elif reference_sources:
            disposition = "reference_source_only"
        else:
            disposition = "unmapped"
        rows.append({
            "module": module,
            "loading_stages": ",".join(sorted(module_stages[module])),
            "disposition": disposition,
            "reference_makefiles": ";".join(reference_sources) or "-",
            "target_makefiles": ";".join(target_sources) or "-",
            "review_rule": "same module name is not ABI compatibility; rebuild and validate KMI before staging",
        })

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=list(rows[0]) if rows else ["module"],
            delimiter="\t",
            lineterminator="\n",
        )
        writer.writeheader()
        writer.writerows(rows)

    counts: dict[str, int] = {}
    for row in rows:
        counts[row["disposition"]] = counts.get(row["disposition"], 0) + 1
    summary = args.output.with_suffix(args.output.suffix + ".summary")
    with summary.open("w", encoding="utf-8") as handle:
        handle.write(f"unique_reference_modules={len(rows)}\n")
        for key in sorted(counts):
            handle.write(f"{key}={counts[key]}\n")
        handle.write("policy=no binary module reuse; every staged module must be rebuilt against one 6.18 output and KMI baseline\n")
    print(f"Porting contract: {args.output} ({len(rows)} unique reference modules)")
    print(f"Summary: {summary}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
