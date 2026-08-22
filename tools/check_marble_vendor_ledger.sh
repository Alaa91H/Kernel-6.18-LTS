#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Validate the text-only marble vendor-module ledger.
#
# A zero exit status means the ledger is internally complete and honestly
# records its B0 state.  It does NOT mean B0 is green, the device can boot, or
# an image may be packaged.  Use --require-b0-green only in a later workflow
# that has independently supplied all required artifact and device evidence.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/check_marble_vendor_ledger.sh [--root <ack-tree>] [--ledger-dir <dir>] [--require-b0-green]

The checker uses only committed text reports.  It does not open a ROM/module
binary, run a build, create an image, or interact with a device.
EOF
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$script_dir/.." && pwd)
ledger_dir=
require_b0_green=no

while (($#)); do
  case "$1" in
    --root)
      root=${2:?missing value for --root}
      shift 2
      ;;
    --ledger-dir)
      ledger_dir=${2:?missing value for --ledger-dir}
      shift 2
      ;;
    --require-b0-green)
      require_b0_green=yes
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'error: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

root=$(cd -- "$root" && pwd)
audit_dir="$root/marble-port/reports/evolutionx17_rom_abi_audit"
ledger_dir=${ledger_dir:-"$root/marble-port/reports/marble_vendor_ledger_2026-08-22"}
ledger="$ledger_dir/MARBLE_VENDOR_MODULE_LEDGER.tsv"
provenance="$ledger_dir/LEDGER_INPUT_PROVENANCE.txt"
first_stage="$audit_dir/first_stage_load_filename_gaps.txt"
vendor_load="$audit_dir/vendor_load_filename_gaps.txt"

for path in "$ledger" "$provenance" "$first_stage" "$vendor_load"; do
  [[ -f "$path" ]] || { printf 'FAIL\trequired input is absent: %s\n' "$path" >&2; exit 2; }
done

failures=0
pass() { printf 'PASS\t%s\n' "$1"; }
fail() { printf 'FAIL\t%s\n' "$1" >&2; failures=$((failures + 1)); }

if grep -q $'\r' "$ledger" "$provenance"; then
  fail 'ledger/provenance contains carriage returns'
else
  pass 'ledger/provenance use LF line endings'
fi

header=$(sed -n '1p' "$ledger")
expected_header=$'module\tfirst_stage_gap\tvendor_load_gap\tfamily\tinput_disposition\txiaomi_candidate_makefiles\tack_candidate_makefiles\tack_kconfig_candidates\tack_kconfig_present\tlikely_dt_firmware_contract\tledger_disposition\tconfidence\tevidence\tb0_effect'
if [[ "$header" == "$expected_header" ]]; then
  pass 'ledger header matches the audited schema'
else
  fail 'ledger header differs from the audited schema'
fi

if awk -F '\t' 'NR > 1 && NF != 14 {bad++; printf "line %d has %d fields\n", NR, NF > "/dev/stderr"} END {exit bad ? 1 : 0}' "$ledger"; then
  pass 'every ledger record has exactly 14 TSV fields'
else
  fail 'one or more ledger records have an invalid TSV field count'
fi

if tail -n +2 "$ledger" | cut -f1 | LC_ALL=C sort | uniq -d | grep -q .; then
  fail 'duplicate module names exist in the ledger'
else
  pass 'module names are unique'
fi

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
LC_ALL=C sort -u "$first_stage" > "$work/first-stage"
LC_ALL=C sort -u "$vendor_load" > "$work/vendor-load"
cat "$work/first-stage" "$work/vendor-load" | LC_ALL=C sort -u > "$work/expected"
tail -n +2 "$ledger" | cut -f1 | LC_ALL=C sort -u > "$work/actual"
if diff -u "$work/expected" "$work/actual" > "$work/module-set.diff"; then
  pass "ledger covers all $(wc -l < "$work/expected") unique audited module gaps"
else
  fail "ledger module set differs from the audited gap union; see $work/module-set.diff"
fi

if awk -F '\t' '
  NR == FNR { first[$1] = 1; next }
  FILENAME == ARGV[2] { vendor[$1] = 1; next }
  FNR == 1 { next }
  {
    expected_first = ($1 in first ? "yes" : "no")
    expected_vendor = ($1 in vendor ? "yes" : "no")
    if ($2 != expected_first || $3 != expected_vendor) {
      printf "line %d %s: phase flags got %s/%s expected %s/%s\n", FNR, $1, $2, $3, expected_first, expected_vendor > "/dev/stderr"
      bad = 1
    }
  }
  END { exit bad ? 1 : 0 }
' "$work/first-stage" "$work/vendor-load" "$ledger"; then
  pass 'first-stage and vendor-load flags exactly match their source lists'
else
  fail 'one or more phase flags differ from their audited source lists'
fi

if awk -F '\t' 'NR > 1 && $11 !~ /^(upstream|source-port|proprietary-blocked|defer\/disable)$/ {print "invalid ledger disposition on " $1 > "/dev/stderr"; bad=1} END {exit bad ? 1 : 0}' "$ledger"; then
  pass 'all rows use an approved ledger disposition'
else
  fail 'one or more rows use an unapproved ledger disposition'
fi

if awk -F '\t' 'NR > 1 && $12 !~ /^(medium|low|none)$/ {print "invalid confidence on " $1 > "/dev/stderr"; bad=1} END {exit bad ? 1 : 0}' "$ledger"; then
  pass 'all rows use an approved confidence value'
else
  fail 'one or more rows use an unapproved confidence value'
fi

if awk -F '\t' 'NR > 1 && $11 == "source-port" && ($6 == "-" || $7 == "-" || $8 == "-" || $6 ~ /!missing:/ || $7 ~ /!missing:/) {print "source-port lacks verified Xiaomi/ACK/Kconfig candidate on " $1 > "/dev/stderr"; bad=1} END {exit bad ? 1 : 0}' "$ledger"; then
  pass 'every source-port row, if present, has verified Xiaomi and ACK/Kconfig candidates'
else
  fail 'a source-port row lacks verified candidate evidence'
fi

if awk -F '\t' 'NR > 1 && $11 == "proprietary-blocked" && $14 !~ /^BLOCKED:/ {print "proprietary-blocked row does not explicitly block B0: " $1 > "/dev/stderr"; bad=1} END {exit bad ? 1 : 0}' "$ledger"; then
  pass 'every proprietary-blocked row explicitly blocks B0'
else
  fail 'a proprietary-blocked row fails to explicitly block B0'
fi

if awk -F '\t' 'NR > 1 && $2 == "yes" && $14 !~ /^BLOCKED:/ {print "first-stage row does not explicitly block B0: " $1 > "/dev/stderr"; bad=1} END {exit bad ? 1 : 0}' "$ledger"; then
  pass 'every first-stage gap explicitly blocks B0'
else
  fail 'a first-stage gap fails to explicitly block B0'
fi

if grep -Eqi '(^|[^[:alnum:]_.-])(copy|reuse|stage)[[:space:]]+(a[[:space:]]+)?5\.10[[:space:]]*(vendor )?\.ko' "$ledger" "$provenance"; then
  fail 'ledger proposes forbidden 5.10 module-binary copying/reuse'
else
  pass 'ledger/provenance contain no proposal to copy or reuse a 5.10 module binary'
fi

expected_hash=$(sha256sum "$ledger" | awk '{print $1}')
recorded_hash=$(awk -F '\t' '$1 == "LEDGER_SHA256" {print $2}' "$provenance")
if [[ -n "$recorded_hash" && "$recorded_hash" == "$expected_hash" ]]; then
  pass 'provenance ledger hash matches the current TSV'
else
  fail 'provenance ledger hash is missing or does not match the current TSV'
fi

if ((failures)); then
  printf 'RESULT\tLEDGER_INVALID\tfailures=%d\n' "$failures" >&2
  exit 1
fi

blocked=$(awk -F '\t' 'NR > 1 && $14 ~ /^BLOCKED:/ {n++} END {print n+0}' "$ledger")
source_port=$(awk -F '\t' 'NR > 1 && $11 == "source-port" {n++} END {print n+0}' "$ledger")
proprietary_blocked=$(awk -F '\t' 'NR > 1 && $11 == "proprietary-blocked" {n++} END {print n+0}' "$ledger")
printf 'RESULT\tLEDGER_VALID\trows=%s\tsource_port=%s\tproprietary_blocked=%s\tb0_rows_blocked=%s\n' \
  "$(( $(wc -l < "$ledger") - 1 ))" "$source_port" "$proprietary_blocked" "$blocked"
printf 'B0_STATUS\tBLOCKED\tThe ledger is internally valid, but it does not supply native modules, ramdisk/DTBO/firmware/AVB evidence, recovery rehearsal, or device logs.\n'

if [[ "$require_b0_green" == yes ]]; then
  printf 'FAIL\tB0 is deliberately blocked; --require-b0-green cannot pass with this evidence set.\n' >&2
  exit 1
fi
