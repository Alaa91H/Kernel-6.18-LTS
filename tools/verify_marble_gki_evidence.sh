#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Verify a portable, non-flashable Marble GKI source-build evidence archive.
# This verifier checks archive integrity, member-type policy, and recorded
# configuration metadata. It does not verify a GitHub attestation, establish
# artifact security, or prove
# device bootability, KMI compatibility, ROM compatibility, or hardware support.
set -euo pipefail

require_clean_source=false

usage()
{
	printf 'Usage: %s [--require-clean-source] <evidence.tar.gz> [evidence.tar.gz.sha256]\n' "$0" >&2
	exit 2
}

while (($# > 0)); do
	case "$1" in
		--require-clean-source)
			require_clean_source=true
			shift
			;;
		--)
			shift
			break
			;;
		-*)
			usage
			;;
		*)
			break
			;;
	esac
done

BUNDLE="${1:-}"
CHECKSUM="${2:-}"
[[ $# -le 2 ]] || usage

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
expected_entries=(
	effective.config
	build-metadata.txt
	build.log
	Image.sha256
	manifest.sha256
)
expected_metadata_keys=(
	build_timestamp_utc
	build_scope
	source_commit
	source_branch
	source_dirty
	kernel_release
	clang_version
	config_sha256
	image_sha256
	image_path
	modules_present
	dtbs_present
)

die()
{
	printf 'evidence verification failed: %s\n' "$*" >&2
	exit 1
}

metadata_value()
{
	local key="$1"
	awk -F= -v wanted="$key" '$1 == wanted { print substr($0, length(wanted) + 2); exit }' \
		"$stage/build-metadata.txt"
}

[[ -n "$BUNDLE" ]] || usage
[[ -s "$BUNDLE" ]] || die "evidence archive is missing or empty: $BUNDLE"
[[ "$BUNDLE" == *.tar.gz ]] || die "evidence archive must use a .tar.gz suffix: $BUNDLE"

if [[ -z "$CHECKSUM" ]]; then
	CHECKSUM="$BUNDLE.sha256"
fi
[[ -s "$CHECKSUM" ]] || die "evidence checksum is missing or empty: $CHECKSUM"

for tool in awk cmp grep mktemp sha256sum sort tar; do
	command -v "$tool" >/dev/null 2>&1 || die "required command is unavailable: $tool"
done

bundle_dir="$(cd "$(dirname "$BUNDLE")" && pwd -P)"
checksum_dir="$(cd "$(dirname "$CHECKSUM")" && pwd -P)"
checksum_name="$(basename "$CHECKSUM")"
[[ "$bundle_dir" == "$checksum_dir" ]] || \
	die 'evidence archive and checksum must be in the same directory'

(
	cd "$bundle_dir"
	sha256sum --strict -c "$checksum_name"
) || die 'external evidence checksum does not match the archive'

entry_list="$(mktemp)"
expected_list="$(mktemp)"
metadata_key_list="$(mktemp)"
expected_metadata_key_list="$(mktemp)"
stage="$(mktemp -d)"
cleanup()
{
	rm -f "$entry_list" "$expected_list" "$metadata_key_list" \
		"$expected_metadata_key_list"
	rm -rf "$stage"
}
trap cleanup EXIT

printf '%s\n' "${expected_entries[@]}" | LC_ALL=C sort > "$expected_list"
tar -tzf "$BUNDLE" | LC_ALL=C sort > "$entry_list"
cmp -s "$expected_list" "$entry_list" || die 'archive contents differ from the fixed evidence layout'
tar -tvzf "$BUNDLE" | awk 'NF == 0 || substr($1, 1, 1) != "-" { exit 1 }' || \
	die 'archive contains a non-regular member'

tar -xzf "$BUNDLE" --no-same-owner --no-same-permissions -C "$stage"

awk -F= 'NF < 2 || $1 !~ /^[a-z0-9_]+$/ { exit 1 } { print $1 }' \
	"$stage/build-metadata.txt" | LC_ALL=C sort > "$metadata_key_list" || \
	die 'build metadata contains a malformed record'
printf '%s\n' "${expected_metadata_keys[@]}" | LC_ALL=C sort > "$expected_metadata_key_list"
cmp -s "$expected_metadata_key_list" "$metadata_key_list" || \
	die 'build metadata does not match the fixed schema'

manifest_names="$(awk '{print $2}' "$stage/manifest.sha256")"
expected_manifest_names="$(printf '%s\n' effective.config build-metadata.txt build.log Image.sha256)"
[[ "$manifest_names" == "$expected_manifest_names" ]] || \
	die 'internal manifest has an unexpected file layout'
awk 'NF != 2 || $1 !~ /^[0-9a-f]{64}$/ { exit 1 }' "$stage/manifest.sha256" || \
	die 'internal manifest contains a malformed SHA-256 record'
(
	cd "$stage"
	sha256sum --strict -c manifest.sha256
) || die 'internal evidence manifest does not match the extracted files'

for symbol in "${required_symbols[@]}"; do
	grep -Fqx "${symbol}=y" "$stage/effective.config" || \
		die "required configuration symbol is not enabled: $symbol"
done
grep -Fqx '# CONFIG_DEBUG_INFO_BTF is not set' "$stage/effective.config" || \
	die 'evidence configuration does not preserve the disabled BTF policy'
! grep -Fqx 'CONFIG_DEBUG_INFO_BTF_MODULES=y' "$stage/effective.config" || \
	die 'evidence configuration enables prohibited BTF module support'

recorded_scope="$(metadata_value build_scope)"
recorded_commit="$(metadata_value source_commit)"
recorded_dirty="$(metadata_value source_dirty)"
recorded_config_hash="$(metadata_value config_sha256)"
recorded_image_hash="$(metadata_value image_sha256)"
recorded_release="$(metadata_value kernel_release)"
image_record_hash="$(awk 'NR == 1 { print $1 }' "$stage/Image.sha256")"

[[ "$recorded_scope" == 'source-build-only; not-flashable; no-device-validation' ]] || \
	die 'build metadata has an unexpected safety scope'
[[ "$recorded_commit" =~ ^[0-9a-f]{40}$ ]] || die 'build metadata has a malformed source commit'
[[ "$recorded_dirty" == true || "$recorded_dirty" == false ]] || \
	die 'build metadata has a malformed source-dirty value'
if [[ "$require_clean_source" == true && "$recorded_dirty" != false ]]; then
	die 'build metadata records a dirty source tree'
fi
[[ "$recorded_config_hash" =~ ^[0-9a-f]{64}$ ]] || \
	die 'build metadata has a malformed configuration SHA-256'
[[ "$recorded_image_hash" =~ ^[0-9a-f]{64}$ ]] || \
	die 'build metadata has a malformed image SHA-256'
[[ "$image_record_hash" =~ ^[0-9a-f]{64}$ ]] || \
	die 'recorded Image SHA-256 is malformed'
[[ -n "$recorded_release" ]] || die 'build metadata has an empty kernel release'

actual_config_hash="$(sha256sum "$stage/effective.config" | awk '{print $1}')"
[[ "$recorded_config_hash" == "$actual_config_hash" ]] || \
	die 'build metadata configuration SHA-256 does not match effective.config'
[[ "$recorded_image_hash" == "$image_record_hash" ]] || \
	die 'build metadata image SHA-256 does not match Image.sha256'

printf 'Evidence archive verification passed.\n'
printf 'source_commit=%s\n' "$recorded_commit"
printf 'kernel_release=%s\n' "$recorded_release"
printf 'image_sha256=%s\n' "$recorded_image_hash"
printf 'source_dirty=%s\n' "$recorded_dirty"
printf 'safety_scope=%s\n' "$recorded_scope"
