#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Regression tests for verify_marble_gki_evidence.sh. The supplied bundle must
# already be valid. This test copies it into private temporary directories and
# proves that controlled malformed variants are rejected. It creates no kernel
# image and makes no device-support claim.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERIFIER="$ROOT/tools/verify_marble_gki_evidence.sh"
BUNDLE="${1:-}"
CHECKSUM="${2:-}"

usage()
{
	printf 'Usage: %s <evidence.tar.gz> [evidence.tar.gz.sha256]\n' "$0" >&2
	exit 2
}

fail()
{
	printf 'evidence verifier self-test failed: %s\n' "$*" >&2
	exit 1
}

expect_reject()
{
	local description="$1"
	shift
	if "$VERIFIER" "$@" >/dev/null 2>&1; then
		fail "verifier accepted invalid fixture: $description"
	fi
	printf 'Rejected invalid fixture: %s\n' "$description"
}

expect_reject_with_message()
{
	local description="$1"
	local expected_message="$2"
	local output
	shift 2
	if output="$("$VERIFIER" "$@" 2>&1)"; then
		fail "verifier accepted invalid fixture: $description"
	fi
	[[ "$output" == *"$expected_message"* ]] || \
		fail "verifier rejected fixture for an unexpected reason: $description"
	printf 'Rejected invalid fixture: %s\n' "$description"
}

[[ -n "$BUNDLE" ]] || usage
[[ -s "$BUNDLE" ]] || fail "evidence archive is missing or empty: $BUNDLE"
if [[ -z "$CHECKSUM" ]]; then
	CHECKSUM="$BUNDLE.sha256"
fi
[[ -s "$CHECKSUM" ]] || fail "evidence checksum is missing or empty: $CHECKSUM"
[[ -x "$VERIFIER" ]] || fail "verifier is unavailable or not executable: $VERIFIER"

for tool in basename cp ln mktemp rm sed sha256sum tar; do
	command -v "$tool" >/dev/null 2>&1 || fail "required command is unavailable: $tool"
done

work="$(mktemp -d)"
cleanup()
{
	rm -rf "$work"
}
trap cleanup EXIT

archive_name="$(basename "$BUNDLE")"
checksum_name="$(basename "$CHECKSUM")"

repack()
{
	local fixture_dir="$1"
	(
		cd "$fixture_dir/stage"
		tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
			-czf "$fixture_dir/$archive_name" \
			effective.config build-metadata.txt build.log Image.sha256 manifest.sha256
		sha256sum "$fixture_dir/$archive_name" > "$fixture_dir/$checksum_name"
	)
}

extract_bundle()
{
	local fixture_dir="$1"
	mkdir -p "$fixture_dir/stage"
	tar -xzf "$BUNDLE" --no-same-owner --no-same-permissions -C "$fixture_dir/stage"
}

"$VERIFIER" "$BUNDLE" "$CHECKSUM" >/dev/null
printf 'Accepted valid evidence bundle.\n'
"$VERIFIER" --require-clean-source "$BUNDLE" "$CHECKSUM" >/dev/null
printf 'Accepted valid evidence bundle in clean-source mode.\n'

corrupt="$work/corrupt"
mkdir -p "$corrupt"
cp "$BUNDLE" "$corrupt/$archive_name"
cp "$CHECKSUM" "$corrupt/$checksum_name"
printf 'controlled corruption\n' >> "$corrupt/$archive_name"
expect_reject 'external checksum mismatch' "$corrupt/$archive_name" "$corrupt/$checksum_name"

layout="$work/layout"
extract_bundle "$layout"
printf 'unexpected archive member\n' > "$layout/stage/unexpected.txt"
(
	cd "$layout/stage"
	tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
		-czf "$layout/$archive_name" \
		effective.config build-metadata.txt build.log Image.sha256 manifest.sha256 unexpected.txt
	sha256sum "$layout/$archive_name" > "$layout/$checksum_name"
)
expect_reject 'unexpected archive member' "$layout/$archive_name" "$layout/$checksum_name"

link="$work/link"
extract_bundle "$link"
rm "$link/stage/build.log"
ln -s effective.config "$link/stage/build.log"
(
	cd "$link/stage"
	sha256sum effective.config build-metadata.txt build.log Image.sha256 > manifest.sha256
)
repack "$link"
expect_reject_with_message 'symbolic-link archive member' 'archive contains a non-regular member' \
	"$link/$archive_name" "$link/$checksum_name"

metadata="$work/metadata"
extract_bundle "$metadata"
sed -i 's/^config_sha256=.*/config_sha256=0000000000000000000000000000000000000000000000000000000000000000/' \
	"$metadata/stage/build-metadata.txt"
(
	cd "$metadata/stage"
	sha256sum effective.config build-metadata.txt build.log Image.sha256 > manifest.sha256
)
repack "$metadata"
expect_reject 'metadata configuration checksum mismatch' \
	"$metadata/$archive_name" "$metadata/$checksum_name"

unknown_metadata="$work/unknown-metadata"
extract_bundle "$unknown_metadata"
printf 'unreviewed_key=value\n' >> "$unknown_metadata/stage/build-metadata.txt"
(
	cd "$unknown_metadata/stage"
	sha256sum effective.config build-metadata.txt build.log Image.sha256 > manifest.sha256
)
repack "$unknown_metadata"
expect_reject_with_message 'unexpected metadata key' \
	'build metadata does not match the fixed schema' \
	"$unknown_metadata/$archive_name" "$unknown_metadata/$checksum_name"

duplicate_metadata="$work/duplicate-metadata"
extract_bundle "$duplicate_metadata"
printf 'source_dirty=false\n' >> "$duplicate_metadata/stage/build-metadata.txt"
(
	cd "$duplicate_metadata/stage"
	sha256sum effective.config build-metadata.txt build.log Image.sha256 > manifest.sha256
)
repack "$duplicate_metadata"
expect_reject_with_message 'duplicate metadata key' \
	'build metadata does not match the fixed schema' \
	"$duplicate_metadata/$archive_name" "$duplicate_metadata/$checksum_name"

dirty="$work/dirty"
extract_bundle "$dirty"
sed -i 's/^source_dirty=false$/source_dirty=true/' "$dirty/stage/build-metadata.txt"
(
	cd "$dirty/stage"
	sha256sum effective.config build-metadata.txt build.log Image.sha256 > manifest.sha256
)
repack "$dirty"
expect_reject_with_message 'dirty source in clean-source mode' \
	'build metadata records a dirty source tree' --require-clean-source \
	"$dirty/$archive_name" "$dirty/$checksum_name"

printf 'Evidence verifier self-test passed.\n'
