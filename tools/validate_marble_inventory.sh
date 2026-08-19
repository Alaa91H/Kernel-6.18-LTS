#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_ROOT="${REFERENCE_ROOT:-$(cd "$KERNEL_ROOT/../reference" && pwd)}"
REPORT_DIR="${REPORT_DIR:-$KERNEL_ROOT/marble-port/reports}"
MODULES_REF="${MODULES_REF:-$REFERENCE_ROOT/xiaomi-marble-5.10/modules.list.msm.marble}"

required_reports=(
  marble_gki_config_requests.tsv
  marble_gki_config_present.tsv
  marble_gki_config_missing.tsv
  marble_gki_missing_categories.tsv
  marble_module_categories.tsv
  marble_dt_include_closure.txt
  marble_dt_external_includes.txt
  marble_dt_bindings_present.tsv
  marble_dt_bindings_missing.tsv
  marble_dt_bindings_summary.tsv
)

for report in "${required_reports[@]}"; do
  [[ -e "$REPORT_DIR/$report" ]] || { printf 'Missing report: %s\n' "$report" >&2; exit 1; }
done
[[ -s "$MODULES_REF" ]] || { printf 'Missing module reference: %s\n' "$MODULES_REF" >&2; exit 1; }

requests=$(wc -l < "$REPORT_DIR/marble_gki_config_requests.tsv")
present=$(wc -l < "$REPORT_DIR/marble_gki_config_present.tsv")
missing=$(wc -l < "$REPORT_DIR/marble_gki_config_missing.tsv")
category_total=$(awk -F '\t' '{sum+=$2} END{print sum+0}' "$REPORT_DIR/marble_gki_missing_categories.tsv")
modules=$(grep -Ev '^[[:space:]]*(#|$)' "$MODULES_REF" | wc -l)
module_category_total=$(awk -F '\t' '{sum+=$2} END{print sum+0}' "$REPORT_DIR/marble_module_categories.tsv")
dt_local=$(wc -l < "$REPORT_DIR/marble_dt_include_closure.txt")
dt_external=$(wc -l < "$REPORT_DIR/marble_dt_external_includes.txt")
dt_bindings_present=$(wc -l < "$REPORT_DIR/marble_dt_bindings_present.tsv")
dt_bindings_missing=$(wc -l < "$REPORT_DIR/marble_dt_bindings_missing.tsv")

[[ $((present + missing)) -eq "$requests" ]] || { printf 'Kconfig accounting mismatch: %s + %s != %s\n' "$present" "$missing" "$requests" >&2; exit 1; }
[[ "$category_total" -eq "$missing" ]] || { printf 'Missing Kconfig category mismatch: %s != %s\n' "$category_total" "$missing" >&2; exit 1; }
[[ "$module_category_total" -eq "$modules" ]] || { printf 'Module category mismatch: %s != %s\n' "$module_category_total" "$modules" >&2; exit 1; }
[[ "$dt_local" -gt 0 && "$dt_external" -gt 0 ]] || { printf 'Device Tree closure is unexpectedly empty.\n' >&2; exit 1; }
[[ $((dt_bindings_present + dt_bindings_missing)) -eq "$dt_external" ]] || { printf 'Device Tree binding accounting mismatch: %s + %s != %s\n' "$dt_bindings_present" "$dt_bindings_missing" "$dt_external" >&2; exit 1; }

git -C "$KERNEL_ROOT" diff --check
printf 'Inventory validation passed: config=%s (present=%s, missing=%s), modules=%s, DTS local=%s, DTS external=%s (bindings present=%s, missing=%s)\n' \
  "$requests" "$present" "$missing" "$modules" "$dt_local" "$dt_external" "$dt_bindings_present" "$dt_bindings_missing"
