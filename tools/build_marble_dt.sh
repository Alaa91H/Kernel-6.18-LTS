#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$KERNEL_ROOT/out/marble-dt-6.18}"
JOBS="${JOBS:-6}"
ARTIFACT_DIR="$OUT/arch/arm64/boot/dts/qcom"
LOG="$OUT/marble-dt-build.log"
MANIFEST="$OUT/marble-dt-artifacts.tsv"

mkdir -p "$OUT"
make -s -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 gki_defconfig
"$KERNEL_ROOT/scripts/config" --file "$OUT/.config" -e OF_OVERLAY
make -s -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig

set -o pipefail
rm -f "$ARTIFACT_DIR/ukee.dtb" "$ARTIFACT_DIR/marble-sm7475-pm8008-overlay.dtbo"
make -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 DTC_FLAGS="-@" -j"$JOBS" \
  qcom/ukee.dtb qcom/marble-sm7475-pm8008-overlay.dtbo 2>&1 | tee "$LOG"

: > "$MANIFEST"
for artifact in ukee.dtb marble-sm7475-pm8008-overlay.dtbo; do
  path="$ARTIFACT_DIR/$artifact"
  [[ -s "$path" ]] || { printf 'Missing expected artifact: %s\n' "$path" >&2; exit 1; }
  printf '%s\t%s\t%s\n' "$artifact" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')" >> "$MANIFEST"
done

warnings=$(grep -c 'Warning (' "$LOG" || true)
printf 'Built marble Device Tree artifacts. warnings=%s manifest=%s\n' "$warnings" "$MANIFEST"
