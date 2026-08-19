#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${REPORT_DIR:-$KERNEL_ROOT/marble-port/reports}"
INCLUDES="$REPORT_DIR/marble_dt_external_includes.txt"
PRESENT="$REPORT_DIR/marble_dt_bindings_present.tsv"
MISSING="$REPORT_DIR/marble_dt_bindings_missing.tsv"
SUMMARY="$REPORT_DIR/marble_dt_bindings_summary.tsv"

[[ -s "$INCLUDES" ]] || { printf 'Run marble_dt_closure.sh before binding analysis.\n' >&2; exit 1; }
: > "$PRESENT"
: > "$MISSING"

while IFS=$'\t' read -r kind binding; do
  [[ "$kind" == "external" ]] || continue
  if [[ -f "$KERNEL_ROOT/include/$binding" ]]; then
    printf '%s\tpresent\n' "$binding" >> "$PRESENT"
  else
    printf '%s\tmissing\n' "$binding" >> "$MISSING"
  fi
done < "$INCLUDES"

present_count=$(wc -l < "$PRESENT")
missing_count=$(wc -l < "$MISSING")
printf 'present\t%s\nmissing\t%s\n' "$present_count" "$missing_count" > "$SUMMARY"
printf 'Device Tree binding analysis: present=%s missing=%s\n' "$present_count" "$missing_count"
