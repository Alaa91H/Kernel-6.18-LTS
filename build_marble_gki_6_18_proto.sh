#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${OUT_DIR:-$ROOT/out/marble-gki-6.18-prototype}"
ARCH=arm64
JOBS="${JOBS:-$(nproc)}"
CORE_FRAGMENT="$ROOT/arch/arm64/configs/marble_gki_6_18_core.config"
PROTO_FRAGMENT="$ROOT/arch/arm64/configs/marble_gki_6_18_proto.config"

for fragment in "$CORE_FRAGMENT" "$PROTO_FRAGMENT"; do
  if [[ ! -f "$fragment" ]]; then
    printf 'Missing marble configuration fragment: %s\n' "$fragment" >&2
    exit 1
  fi
done

rm -rf "$OUT"
mkdir -p "$OUT"

make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 gki_defconfig
"$ROOT/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" \
  "$CORE_FRAGMENT" "$PROTO_FRAGMENT"
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 \
  LOCALVERSION=-marble-gki6.18-prototype olddefconfig
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 \
  LOCALVERSION=-marble-gki6.18-prototype -j"$JOBS" Image modules
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 DTC_FLAGS="-@" -j"$JOBS" \
  qcom/ukee.dtb qcom/marble-sm7475-pm8008-overlay.dtbo

IMAGE="$OUT/arch/arm64/boot/Image"
if [[ ! -s "$IMAGE" ]]; then
  printf 'Expected kernel image was not produced: %s\n' "$IMAGE" >&2
  exit 1
fi

{
  printf 'source_commit=%s\n' "$(git -C "$ROOT" rev-parse HEAD)"
  printf 'source_branch=%s\n' "$(git -C "$ROOT" branch --show-current)"
  printf 'config_fragments=%s,%s\n' "$(basename "$CORE_FRAGMENT")" "$(basename "$PROTO_FRAGMENT")"
  printf 'kernel_release=%s\n' "$(make -s -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 kernelrelease)"
  printf 'image_sha256=%s\n' "$(sha256sum "$IMAGE" | awk '{print $1}')"
  printf 'image_path=%s\n' "$IMAGE"
  printf 'modules_present=%s\n' "$(find "$OUT" -type f -name '*.ko' | wc -l)"
  printf 'dtbs_present=%s\n' "$(find "$OUT" -type f -name '*.dtb' | wc -l)"
} > "$OUT/build-metadata.txt"

printf 'Build completed successfully.\n'
printf 'Metadata: %s\n' "$OUT/build-metadata.txt"
