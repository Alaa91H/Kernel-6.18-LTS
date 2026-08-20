#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$KERNEL_ROOT/out/marble-dt-6.18}"
ARTIFACT_DIR="$OUT/arch/arm64/boot/dts/qcom"
LOG="$OUT/marble-dt-build.log"
BASE_ROUNDTRIP_LOG="$OUT/ukee-dtb-roundtrip.log"
OVERLAY_ROUNDTRIP_LOG="$OUT/marble-dtbo-roundtrip.log"
MERGED_ROUNDTRIP_LOG="$OUT/marble-merged-dtb-roundtrip.log"
# Default budgets are the reviewed baseline, not a waiver. Set all values to
# zero only after the corresponding source/binding fixes are proven.
MAX_BUILD_WARNINGS="${MARBLE_DTC_MAX_BUILD_WARNINGS:-129}"
MAX_BASE_WARNINGS="${MARBLE_DTC_MAX_BASE_WARNINGS:-53}"
MAX_OVERLAY_WARNINGS="${MARBLE_DTC_MAX_OVERLAY_WARNINGS:-154}"
MAX_MERGED_WARNINGS="${MARBLE_DTC_MAX_MERGED_WARNINGS:-103}"

"$KERNEL_ROOT/tools/build_marble_dt.sh"

for artifact in ukee.dtb marble-sm7475-pm8008-overlay.dtbo; do
  path="$ARTIFACT_DIR/$artifact"
  [[ -s "$path" ]] || { printf 'Missing artifact: %s\n' "$path" >&2; exit 1; }
  case "$artifact" in
    ukee.dtb) roundtrip_log="$BASE_ROUNDTRIP_LOG" ;;
    marble-sm7475-pm8008-overlay.dtbo) roundtrip_log="$OVERLAY_ROUNDTRIP_LOG" ;;
  esac
  "$OUT/scripts/dtc/dtc" -I dtb -O dts "$path" >/dev/null 2>"$roundtrip_log"
done

merged="$ARTIFACT_DIR/ukee-marble-merged.dtb"
"$OUT/scripts/dtc/fdtoverlay" -i "$ARTIFACT_DIR/ukee.dtb" -o "$merged" \
  "$ARTIFACT_DIR/marble-sm7475-pm8008-overlay.dtbo"
"$OUT/scripts/dtc/dtc" -I dtb -O dts "$merged" >/dev/null 2>"$MERGED_ROUNDTRIP_LOG"

build_warnings=$(grep -c 'Warning (' "$LOG" || true)
base_roundtrip_warnings=$(grep -c 'Warning (' "$BASE_ROUNDTRIP_LOG" || true)
overlay_roundtrip_warnings=$(grep -c 'Warning (' "$OVERLAY_ROUNDTRIP_LOG" || true)
merged_roundtrip_warnings=$(grep -c 'Warning (' "$MERGED_ROUNDTRIP_LOG" || true)
for pair in \
  "build:$build_warnings:$MAX_BUILD_WARNINGS" \
  "base:$base_roundtrip_warnings:$MAX_BASE_WARNINGS" \
  "overlay:$overlay_roundtrip_warnings:$MAX_OVERLAY_WARNINGS" \
  "merged:$merged_roundtrip_warnings:$MAX_MERGED_WARNINGS"; do
  IFS=: read -r label actual maximum <<<"$pair"
  [[ "$maximum" =~ ^[0-9]+$ ]] || { printf 'Invalid %s warning budget: %s\n' "$label" "$maximum" >&2; exit 2; }
  if (( actual > maximum )); then
    printf 'Device Tree warning budget exceeded: %s=%s > %s\n' "$label" "$actual" "$maximum" >&2
    exit 1
  fi
done
printf 'Static Device Tree validation passed: artifacts are readable; build=%s/%s base=%s/%s overlay=%s/%s merged=%s/%s warnings.\n' \
  "$build_warnings" "$MAX_BUILD_WARNINGS" "$base_roundtrip_warnings" "$MAX_BASE_WARNINGS" \
  "$overlay_roundtrip_warnings" "$MAX_OVERLAY_WARNINGS" "$merged_roundtrip_warnings" "$MAX_MERGED_WARNINGS"
