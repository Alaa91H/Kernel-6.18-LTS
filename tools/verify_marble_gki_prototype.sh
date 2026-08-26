#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Verify the artifacts emitted by build_marble_gki_6_18_proto.sh.
# This validator intentionally checks source-build provenance only. It does not
# establish bootability, ROM compatibility, KMI compatibility, or device support.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT="${OUT_DIR:-$ROOT/out/marble-gki-6.18-prototype}"
CONFIG="$OUT/.config"
IMAGE="$OUT/arch/arm64/boot/Image"
METADATA="$OUT/build-metadata.txt"

required_symbols=(
	CONFIG_SERIAL_QCOM_GENI
	CONFIG_SERIAL_QCOM_GENI_CONSOLE
	CONFIG_SCSI_UFSHCD
	CONFIG_SCSI_UFSHCD_PLATFORM
	CONFIG_REMOTEPROC
	CONFIG_REMOTEPROC_CDEV
	CONFIG_RPMSG_CHAR
	CONFIG_ANDROID_BINDER_IPC
	CONFIG_ANDROID_BINDERFS
)

die()
{
	printf 'verification failed: %s\n' "$*" >&2
	exit 1
}

metadata_value()
{
	local key="$1"
	awk -F= -v wanted="$key" '$1 == wanted { print substr($0, length(wanted) + 2); exit }' "$METADATA"
}

[[ -d "$OUT" ]] || die "output directory does not exist: $OUT"
[[ -f "$CONFIG" ]] || die "missing merged configuration: $CONFIG"
[[ -s "$IMAGE" ]] || die "missing or empty kernel Image: $IMAGE"
[[ -s "$METADATA" ]] || die "missing build metadata: $METADATA"

for symbol in "${required_symbols[@]}"; do
	grep -Fqx "${symbol}=y" "$CONFIG" || die "required symbol is not enabled: $symbol"
done

grep -Fqx '# CONFIG_DEBUG_INFO_BTF is not set' "$CONFIG" || \
	die 'prototype policy requires CONFIG_DEBUG_INFO_BTF to remain disabled'
! grep -Fqx 'CONFIG_DEBUG_INFO_BTF_MODULES=y' "$CONFIG" || \
	die 'prototype policy requires CONFIG_DEBUG_INFO_BTF_MODULES to remain disabled'

recorded_image_path="$(metadata_value image_path)"
recorded_hash="$(metadata_value image_sha256)"
recorded_release="$(metadata_value kernel_release)"
recorded_modules="$(metadata_value modules_present)"
recorded_dtbs="$(metadata_value dtbs_present)"

[[ "$recorded_image_path" == "$IMAGE" ]] || die 'metadata image path does not match the output directory'
[[ "$recorded_hash" =~ ^[0-9a-f]{64}$ ]] || die 'metadata image SHA-256 is malformed'
[[ -n "$recorded_release" ]] || die 'metadata kernel release is empty'
[[ "$recorded_modules" =~ ^[0-9]+$ ]] || die 'metadata module count is malformed'
[[ "$recorded_dtbs" =~ ^[0-9]+$ ]] || die 'metadata DTB count is malformed'

actual_hash="$(sha256sum "$IMAGE" | awk '{print $1}')"
actual_modules="$(find "$OUT" -type f -name '*.ko' -print | wc -l | tr -d ' ')"
actual_dtbs="$(find "$OUT" -type f -name '*.dtb' -print | wc -l | tr -d ' ')"

[[ "$recorded_hash" == "$actual_hash" ]] || die 'kernel Image SHA-256 does not match metadata'
[[ "$recorded_modules" == "$actual_modules" ]] || die 'module count does not match metadata'
[[ "$recorded_dtbs" == "$actual_dtbs" ]] || die 'DTB count does not match metadata'

printf 'Prototype build verification passed.\n'
printf 'kernel_release=%s\n' "$recorded_release"
printf 'image_sha256=%s\n' "$actual_hash"
printf 'modules_present=%s\n' "$actual_modules"
printf 'dtbs_present=%s\n' "$actual_dtbs"
printf 'safety_scope=source-build-only; not flashable; no device validation\n'
