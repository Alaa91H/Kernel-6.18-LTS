#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_ROOT="${REFERENCE_ROOT:-$(cd "$KERNEL_ROOT/../reference" && pwd)}"
DT_ROOT="${XIAOMI_DT:-$REFERENCE_ROOT/xiaomi-marble-devicetree}"
OUT_DIR="${OUT_DIR:-$KERNEL_ROOT/marble-port/reports}"
DT_QCOM="$DT_ROOT/qcom"
OUT="$OUT_DIR/marble_dt_include_closure.txt"
EXTERNAL="$OUT_DIR/marble_dt_external_includes.txt"

if [[ ! -d "$DT_QCOM" ]]; then
  printf 'Missing Xiaomi Device Tree qcom directory: %s\n' "$DT_QCOM" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
: > "$OUT"
: > "$EXTERNAL"

declare -A seen
walk() {
  local relative="$1"
  local source="$DT_QCOM/$relative"
  local include

  [[ -n "${seen[$relative]:-}" ]] && return
  seen[$relative]=1

  if [[ ! -f "$source" ]]; then
    printf 'missing-local\t%s\n' "$relative" >> "$EXTERNAL"
    return
  fi

  printf '%s\n' "$relative" >> "$OUT"
  while IFS= read -r include; do
    if [[ "$include" =~ ^\"(.+)\"$ ]]; then
      walk "${BASH_REMATCH[1]}"
    elif [[ "$include" =~ ^\<(.+)\>$ ]]; then
      printf 'external\t%s\n' "${BASH_REMATCH[1]}" >> "$EXTERNAL"
    fi
  done < <(sed -nE 's/^[[:space:]]*#include[[:space:]]+([^[:space:]]+).*/\1/p' "$source")
}

# يربط Makefile الرسمي للـDevice Tree هذا الـoverlay بقاعدة ukee.dtb.
walk "ukee.dts"
walk "marble-sm7475.dtsi"
walk "marble-sm7475-pm8008-overlay.dts"
sort -u -o "$OUT" "$OUT"
sort -u -o "$EXTERNAL" "$EXTERNAL"
printf 'Device Tree closure written to %s\n' "$OUT"
