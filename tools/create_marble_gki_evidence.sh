#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0
#
# Create a portable evidence bundle for the non-flashable Marble GKI prototype.
# The bundle intentionally excludes the kernel image, boot images, modules, and
# device artifacts. It provides configuration, build metadata, a build log, and
# verifiable SHA-256 checksums for source-build audit only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
OUT="${OUT_DIR:-$ROOT/out/marble-gki-6.18-prototype}"
EVIDENCE_DIR="${EVIDENCE_DIR:-$OUT/evidence}"
BUILD_LOG="${BUILD_LOG:?BUILD_LOG must point to the completed build log}"
IMAGE="$OUT/arch/arm64/boot/Image"
METADATA="$OUT/build-metadata.txt"
CONFIG="$OUT/.config"
BUNDLE_NAME="marble-gki-source-build-evidence.tar.gz"

require_file()
{
	test -s "$1" || {
		printf 'Required evidence input is missing or empty: %s\n' "$1" >&2
		exit 1
	}
}

for tool in tar sha256sum; do
	command -v "$tool" >/dev/null 2>&1 || {
		printf 'Missing required command: %s\n' "$tool" >&2
		exit 1
	}
done

for path in "$IMAGE" "$METADATA" "$CONFIG" "$BUILD_LOG"; do
	require_file "$path"
done

case "$EVIDENCE_DIR" in
	""|"/"|"$ROOT")
	printf 'Refusing unsafe evidence directory: %s\n' "$EVIDENCE_DIR" >&2
	exit 1
	;;
esac

stage="$(mktemp -d)"
cleanup()
{
	rm -rf "$stage"
}
trap cleanup EXIT

mkdir -p "$EVIDENCE_DIR"
cp "$CONFIG" "$stage/effective.config"
cp "$METADATA" "$stage/build-metadata.txt"
cp "$BUILD_LOG" "$stage/build.log"
sha256sum "$IMAGE" > "$stage/Image.sha256"
(
	cd "$stage"
	sha256sum effective.config build-metadata.txt build.log Image.sha256 \
		> manifest.sha256
)

bundle="$EVIDENCE_DIR/$BUNDLE_NAME"
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
	-czf "$bundle" -C "$stage" \
	effective.config build-metadata.txt build.log Image.sha256 manifest.sha256
(
	cd "$EVIDENCE_DIR"
	sha256sum "$BUNDLE_NAME" > "$BUNDLE_NAME.sha256"
)

printf 'Evidence bundle created: %s\n' "$bundle"
printf 'Evidence bundle checksum: %s\n' "$bundle.sha256"
