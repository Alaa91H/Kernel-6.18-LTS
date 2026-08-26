#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Build the intentionally non-flashable POCO F5 / marble GKI 6.18 prototype.
# This script validates source-build artifacts only. It must not be used to
# create, package, or flash boot, vendor_boot, DTBO, or recovery images.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
OUT="${OUT_DIR:-$ROOT/out/marble-gki-6.18-prototype}"
ARCH=arm64
JOBS="${JOBS:-$(nproc)}"
FRAGMENT="$ROOT/arch/arm64/configs/marble_gki_6_18_proto.config"
VERIFY_SCRIPT="$ROOT/tools/verify_marble_gki_prototype.sh"

require_command()
{
	command -v "$1" >/dev/null 2>&1 || {
		printf 'Missing required command: %s\n' "$1" >&2
		exit 1
	}
}

if [[ ! -f "$FRAGMENT" ]]; then
	printf 'Missing prototype configuration fragment: %s\n' "$FRAGMENT" >&2
	exit 1
fi

if [[ ! -x "$VERIFY_SCRIPT" ]]; then
	printf 'Missing or non-executable prototype verifier: %s\n' "$VERIFY_SCRIPT" >&2
	exit 1
fi

if [[ ! "$JOBS" =~ ^[1-9][0-9]*$ ]]; then
	printf 'JOBS must be a positive integer, got: %s\n' "$JOBS" >&2
	exit 1
fi

for tool in awk find git make sha256sum clang ld.lld llvm-ar llvm-nm llvm-objcopy; do
	require_command "$tool"
done

case "$OUT" in
	""|"/"|"$ROOT")
		printf 'Refusing unsafe output directory: %s\n' "$OUT" >&2
		exit 1
		;;
esac

rm -rf "$OUT"
mkdir -p "$OUT"

make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 gki_defconfig
"$ROOT/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" "$FRAGMENT"
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 \
	LOCALVERSION=-marble-gki6.18-prototype olddefconfig
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 \
	LOCALVERSION=-marble-gki6.18-prototype -j"$JOBS" Image modules dtbs

IMAGE="$OUT/arch/arm64/boot/Image"
if [[ ! -s "$IMAGE" ]]; then
	printf 'Expected kernel image was not produced: %s\n' "$IMAGE" >&2
	exit 1
fi

if git -C "$ROOT" diff --quiet && git -C "$ROOT" diff --cached --quiet; then
	source_dirty=false
else
	source_dirty=true
fi

{
	printf 'build_timestamp_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	printf 'build_scope=source-build-only; not-flashable; no-device-validation\n'
	printf 'source_commit=%s\n' "$(git -C "$ROOT" rev-parse HEAD)"
	printf 'source_branch=%s\n' "$(git -C "$ROOT" branch --show-current)"
	printf 'source_dirty=%s\n' "$source_dirty"
	printf 'kernel_release=%s\n' "$(make -s -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 kernelrelease)"
	printf 'clang_version=%s\n' "$(clang --version | head -n1)"
	printf 'config_sha256=%s\n' "$(sha256sum "$OUT/.config" | awk '{print $1}')"
	printf 'image_sha256=%s\n' "$(sha256sum "$IMAGE" | awk '{print $1}')"
	printf 'image_path=%s\n' "$IMAGE"
	printf 'modules_present=%s\n' "$(find "$OUT" -type f -name '*.ko' -print | wc -l | tr -d ' ')"
	printf 'dtbs_present=%s\n' "$(find "$OUT" -type f -name '*.dtb' -print | wc -l | tr -d ' ')"
} > "$OUT/build-metadata.txt"

OUT_DIR="$OUT" "$VERIFY_SCRIPT"
printf 'Build completed and prototype verification passed.\n'
printf 'Metadata: %s\n' "$OUT/build-metadata.txt"
