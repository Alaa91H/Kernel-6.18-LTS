#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$KERNEL_ROOT/out/marble-dt-6.18}"
ARTIFACT_DIR="$OUT/arch/arm64/boot/dts/qcom"
LOG="$OUT/marble-dt-build.log"

"$KERNEL_ROOT/tools/build_marble_dt.sh"

for artifact in ukee.dtb marble-sm7475-pm8008-overlay.dtbo; do
  path="$ARTIFACT_DIR/$artifact"
  [[ -s "$path" ]] || { printf 'Missing artifact: %s\n' "$path" >&2; exit 1; }
  "$OUT/scripts/dtc/dtc" -I dtb -O dts "$path" >/dev/null
done

merged="$ARTIFACT_DIR/ukee-marble-merged.dtb"
"$OUT/scripts/dtc/fdtoverlay" -i "$ARTIFACT_DIR/ukee.dtb" -o "$merged" \
  "$ARTIFACT_DIR/marble-sm7475-pm8008-overlay.dtbo"
"$OUT/scripts/dtc/dtc" -I dtb -O dts "$merged" >/dev/null 2>/dev/null

warnings=$(grep -c 'Warning (' "$LOG" || true)
printf 'Static Device Tree validation passed: base, overlay, and merged DTB are readable; DTC warnings=%s.\n' "$warnings"
