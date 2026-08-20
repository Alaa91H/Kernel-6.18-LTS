#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$KERNEL_ROOT/out/marble-dt-6.18}"
ARTIFACT_DIR="$OUT/arch/arm64/boot/dts/qcom"
LOG="$OUT/marble-dt-build.log"
BASE_ROUNDTRIP_LOG="$OUT/ukee-dtb-roundtrip.log"
OVERLAY_ROUNDTRIP_LOG="$OUT/marble-dtbo-roundtrip.log"
MERGED_ROUNDTRIP_LOG="$OUT/marble-merged-dtb-roundtrip.log"

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
printf 'Static Device Tree validation passed: artifacts are readable; build=%s base=%s overlay=%s merged=%s warnings.\n' \
  "$build_warnings" "$base_roundtrip_warnings" "$overlay_roundtrip_warnings" "$merged_roundtrip_warnings"
