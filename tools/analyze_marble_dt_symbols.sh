#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_ROOT="${REFERENCE_ROOT:-$(cd "$KERNEL_ROOT/../reference" && pwd)}"
DT_ROOT="${XIAOMI_DT:-$REFERENCE_ROOT/xiaomi-marble-devicetree}"
REPORT_DIR="${REPORT_DIR:-$KERNEL_ROOT/marble-port/reports}"
CLOSURE="$REPORT_DIR/marble_dt_include_closure.txt"
REFERENCES="$REPORT_DIR/marble_dt_phandle_references.txt"
LOCAL_DEFINITIONS="$REPORT_DIR/marble_dt_local_labels.txt"
ACK_DEFINITIONS="$REPORT_DIR/ack_qcom_labels.txt"
RESOLVED_LOCAL="$REPORT_DIR/marble_dt_labels_resolved_local.tsv"
RESOLVED_ACK="$REPORT_DIR/marble_dt_labels_resolved_ack.tsv"
UNRESOLVED="$REPORT_DIR/marble_dt_labels_unresolved.tsv"
SUMMARY="$REPORT_DIR/marble_dt_labels_summary.tsv"

[[ -s "$CLOSURE" ]] || { printf 'Run marble_dt_closure.sh first.\n' >&2; exit 1; }

: > "$REFERENCES"
: > "$LOCAL_DEFINITIONS"
while IFS= read -r relative; do
  source="$DT_ROOT/qcom/$relative"
  [[ -f "$source" ]] || continue
  grep -oE '&[A-Za-z_][A-Za-z0-9_]*' "$source" | sed 's/^&//' >> "$REFERENCES" || true
  sed -nE 's/^[[:space:]]*((([A-Za-z_][A-Za-z0-9_]*):[[:space:]]*)+).*/\1/p' "$source" | grep -oE '[A-Za-z_][A-Za-z0-9_]*:' | sed 's/:$//' >> "$LOCAL_DEFINITIONS" || true
done < "$CLOSURE"
sort -u -o "$REFERENCES" "$REFERENCES"
sort -u -o "$LOCAL_DEFINITIONS" "$LOCAL_DEFINITIONS"

find "$KERNEL_ROOT/arch/arm64/boot/dts/qcom" -type f \( -name '*.dts' -o -name '*.dtsi' \) -print0 \
  | xargs -0 sed -nE 's/^[[:space:]]*((([A-Za-z_][A-Za-z0-9_]*):[[:space:]]*)+).*/\1/p' \
  | grep -oE '[A-Za-z_][A-Za-z0-9_]*:' \
  | sed 's/:$//' \
  | sort -u > "$ACK_DEFINITIONS"

: > "$RESOLVED_LOCAL"
: > "$RESOLVED_ACK"
: > "$UNRESOLVED"
while IFS= read -r label; do
  if grep -qx "$label" "$LOCAL_DEFINITIONS"; then
    printf '%s\tlocal-closure\n' "$label" >> "$RESOLVED_LOCAL"
  elif grep -qx "$label" "$ACK_DEFINITIONS"; then
    printf '%s\tack-qcom\n' "$label" >> "$RESOLVED_ACK"
  else
    printf '%s\tunresolved\n' "$label" >> "$UNRESOLVED"
  fi
done < "$REFERENCES"

printf 'references\t%s\nlocal\t%s\nack\t%s\nunresolved\t%s\n' \
  "$(wc -l < "$REFERENCES")" \
  "$(wc -l < "$RESOLVED_LOCAL")" \
  "$(wc -l < "$RESOLVED_ACK")" \
  "$(wc -l < "$UNRESOLVED")" > "$SUMMARY"
printf 'Device Tree label analysis written: %s\n' "$SUMMARY"
