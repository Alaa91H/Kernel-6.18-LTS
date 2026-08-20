#!/usr/bin/env bash
# Compare the public Evolution X marble kernel build contract with a locally
# built marble GKI configuration. This is a static inventory only: it never
# loads, signs, copies, or packages reference modules.
#
# Usage:
#   audit_evolutionx17_kernel_contract.sh REFERENCE_KERNEL_REPO BUILD_OUTPUT REPORT_DIR
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 REFERENCE_KERNEL_REPO BUILD_OUTPUT REPORT_DIR" >&2
    exit 2
fi

REFERENCE_KERNEL_REPO=$1
BUILD_OUTPUT=$2
REPORT_DIR=$3
CURRENT_CONFIG="$BUILD_OUTPUT/.config"

for required in "$REFERENCE_KERNEL_REPO/.git" "$CURRENT_CONFIG"; do
    [[ -e $required ]] || {
        echo "Required input is missing: $required" >&2
        exit 2
    }
done

mkdir -p "$REPORT_DIR"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

MARBLE_CONFIG_PATH='arch/arm64/configs/vendor/marble_GKI.config'
WAIPIO_CONFIG_PATH='arch/arm64/configs/vendor/waipio_GKI.config'
MODULE_LIST_PATH='modules.list.msm.waipio'

for path in "$MARBLE_CONFIG_PATH" "$WAIPIO_CONFIG_PATH" "$MODULE_LIST_PATH"; do
    git -C "$REFERENCE_KERNEL_REPO" cat-file -e "HEAD:$path" || {
        echo "Reference contract path is missing: $path" >&2
        exit 2
    }
done

reference_commit=$(git -C "$REFERENCE_KERNEL_REPO" rev-parse HEAD)
reference_date=$(git -C "$REFERENCE_KERNEL_REPO" show -s --format=%cI HEAD)
reference_version=$(git -C "$REFERENCE_KERNEL_REPO" show HEAD:Makefile | awk -F' = ' '
    /^VERSION = / { v=$2 }
    /^PATCHLEVEL = / { p=$2 }
    /^SUBLEVEL = / { s=$2 }
    END { if (v != "" && p != "" && s != "") print v "." p "." s }')

{
    printf 'reference_repository=%s\n' "$(git -C "$REFERENCE_KERNEL_REPO" remote get-url origin)"
    printf 'reference_commit=%s\n' "$reference_commit"
    printf 'reference_commit_date=%s\n' "$reference_date"
    printf 'reference_kernel_version=%s\n' "$reference_version"
    printf 'candidate_build_output=%s\n' "$BUILD_OUTPUT"
    printf 'candidate_config_sha256=%s\n' "$(sha256sum "$CURRENT_CONFIG" | awk '{print $1}')"
    printf 'candidate_kernel_release=%s\n' "$(sed -n 's/^CONFIG_LOCALVERSION=//p' "$CURRENT_CONFIG" | tr -d '"')"
    printf '%s\n' 'scope=Static inventory only. 5.10 reference modules must not be loaded by or packaged with the 6.18 candidate.'
} > "$REPORT_DIR/metadata.env"

{
    git -C "$REFERENCE_KERNEL_REPO" show "HEAD:$MARBLE_CONFIG_PATH"
    git -C "$REFERENCE_KERNEL_REPO" show "HEAD:$WAIPIO_CONFIG_PATH"
} | sed -n 's/^\(CONFIG_[A-Za-z0-9_]*\)=\([ym]\)$/\1\t\2/p' | sort -u > "$WORKDIR/reference_symbols.tsv"

printf 'symbol\treference_value\tcandidate_value\tstatus\n' > "$REPORT_DIR/config_comparison.tsv"
while IFS=$'\t' read -r symbol reference_value; do
    candidate_line=$(grep -E "^${symbol}=" "$CURRENT_CONFIG" || true)
    candidate_value=${candidate_line#*=}
    if [[ -z $candidate_line ]]; then
        status='missing'
    elif [[ $candidate_value == y || $candidate_value == m ]]; then
        status='enabled'
    else
        status='disabled'
    fi
    printf '%s\t%s\t%s\t%s\n' "$symbol" "$reference_value" "${candidate_value:-n}" "$status"
done < "$WORKDIR/reference_symbols.tsv" >> "$REPORT_DIR/config_comparison.tsv"

awk -F '\t' 'NR > 1 && $4 != "enabled" { print }' "$REPORT_DIR/config_comparison.tsv" > "$REPORT_DIR/config_gaps.tsv"

# The list below enumerates first-stage module filenames expected by the
# vendor 5.10 build. A same-name result means only that a locally built 6.18
# object exists; it is not an ABI assertion.
git -C "$REFERENCE_KERNEL_REPO" show "HEAD:$MODULE_LIST_PATH" | sort -u > "$WORKDIR/reference_first_stage_modules.txt"
find "$BUILD_OUTPUT" -type f -name '*.ko' -printf '%f\n' | sort -u > "$WORKDIR/candidate_modules.txt"

printf 'metric\tvalue\n' > "$REPORT_DIR/module_inventory_summary.tsv"
printf 'reference_first_stage_unique\t%s\n' "$(wc -l < "$WORKDIR/reference_first_stage_modules.txt")" >> "$REPORT_DIR/module_inventory_summary.tsv"
printf 'candidate_built_unique\t%s\n' "$(wc -l < "$WORKDIR/candidate_modules.txt")" >> "$REPORT_DIR/module_inventory_summary.tsv"
printf 'same_filename\t%s\n' "$(comm -12 "$WORKDIR/reference_first_stage_modules.txt" "$WORKDIR/candidate_modules.txt" | wc -l)" >> "$REPORT_DIR/module_inventory_summary.tsv"
printf 'reference_filename_not_built\t%s\n' "$(comm -23 "$WORKDIR/reference_first_stage_modules.txt" "$WORKDIR/candidate_modules.txt" | wc -l)" >> "$REPORT_DIR/module_inventory_summary.tsv"

comm -12 "$WORKDIR/reference_first_stage_modules.txt" "$WORKDIR/candidate_modules.txt" > "$REPORT_DIR/module_name_overlap.txt"
comm -23 "$WORKDIR/reference_first_stage_modules.txt" "$WORKDIR/candidate_modules.txt" > "$REPORT_DIR/reference_first_stage_module_name_gaps.txt"

printf 'Static Evolution X kernel-contract audit written to %s\n' "$REPORT_DIR"
