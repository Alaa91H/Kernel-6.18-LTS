#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="${1:-$KERNEL_ROOT/out/marble-dt-6.18/marble-dt-build.log}"
REPORT="${2:-$KERNEL_ROOT/marble-port/reports/dtc_warnings_current.tsv}"

[[ -f "$LOG" ]] || { printf 'Missing DTC build log: %s\n' "$LOG" >&2; exit 1; }
mkdir -p "$(dirname "$REPORT")"

{
  printf 'category\tsource\tlocation\tmessage\n'
  awk '
    /Warning \(/ {
      line = $0
      if (match(line, /Warning \(([^)]*)\): /)) {
        category = substr(line, RSTART + 9, RLENGTH - 12)
        prefix = substr(line, 1, RSTART - 3)
        message = substr(line, RSTART + RLENGTH)
        location = ""
        source = prefix
        if (match(prefix, /:[0-9]+(\.[0-9]+)?-[0-9]+(\.[0-9]+)?$/)) {
          location = substr(prefix, RSTART + 1)
          source = substr(prefix, 1, RSTART - 1)
        }
        gsub(/\t/, " ", message)
        printf "%s\t%s\t%s\t%s\n", category, source, location, message
      }
    }
  ' "$LOG"
} > "$REPORT"

printf 'DTC warning report: %s (%s diagnostics)\n' "$REPORT" "$(( $(wc -l < "$REPORT") - 1 ))"
