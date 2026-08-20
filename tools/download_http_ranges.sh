#!/usr/bin/env bash
# Download a public, immutable artifact in independent HTTP byte ranges.
# Usage: download_http_ranges.sh URL OUTPUT EXPECTED_BYTES [PARALLELISM]
set -euo pipefail

if [[ $# -lt 3 || $# -gt 4 ]]; then
    echo "Usage: $0 URL OUTPUT EXPECTED_BYTES [PARALLELISM]" >&2
    exit 2
fi

URL=$1
OUTPUT=$2
EXPECTED_BYTES=$3
PARALLELISM=${4:-8}

if ! [[ $EXPECTED_BYTES =~ ^[1-9][0-9]*$ && $PARALLELISM =~ ^[1-9][0-9]*$ ]]; then
    echo "EXPECTED_BYTES and PARALLELISM must be positive integers" >&2
    exit 2
fi

OUTDIR=$(dirname "$OUTPUT")
WORKDIR="${OUTPUT}.ranges"
mkdir -p "$OUTDIR" "$WORKDIR"

cleanup() {
    local status=$?
    if [[ $status -ne 0 ]]; then
        echo "Download incomplete; retained partial ranges in $WORKDIR" >&2
    fi
}
trap cleanup EXIT

pids=()
for ((i = 0; i < PARALLELISM; i++)); do
    start=$(( EXPECTED_BYTES * i / PARALLELISM ))
    end=$(( EXPECTED_BYTES * (i + 1) / PARALLELISM - 1 ))
    part="$WORKDIR/part-$(printf '%03d' "$i")"
    expected_part=$(( end - start + 1 ))

    if [[ -f $part ]] && [[ $(stat -c '%s' "$part") -eq $expected_part ]]; then
        echo "Range $i already complete: $start-$end"
        continue
    fi

    rm -f "$part"
    (
        curl -fL --retry 5 --retry-delay 3 --connect-timeout 30 \
            -A 'Mozilla/5.0' --range "$start-$end" \
            -o "$part" "$URL"
        actual=$(stat -c '%s' "$part")
        [[ $actual -eq $expected_part ]] || {
            echo "Range $i size mismatch: expected $expected_part, got $actual" >&2
            exit 1
        }
        echo "Range $i complete: $start-$end"
    ) &
    pids+=("$!")
done

for pid in "${pids[@]}"; do
    wait "$pid"
done

for ((i = 0; i < PARALLELISM; i++)); do
    part="$WORKDIR/part-$(printf '%03d' "$i")"
    [[ -f $part ]] || { echo "Missing $part" >&2; exit 1; }
done

cat "$WORKDIR"/part-* > "${OUTPUT}.tmp"
actual=$(stat -c '%s' "${OUTPUT}.tmp")
[[ $actual -eq $EXPECTED_BYTES ]] || {
    echo "Combined size mismatch: expected $EXPECTED_BYTES, got $actual" >&2
    exit 1
}
mv -f "${OUTPUT}.tmp" "$OUTPUT"
rm -rf "$WORKDIR"
printf 'Downloaded %s (%s bytes)\n' "$OUTPUT" "$actual"
