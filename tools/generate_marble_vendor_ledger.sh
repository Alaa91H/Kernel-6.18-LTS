#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Generate a text-only candidate vendor-module ledger for marble.
#
# This tool NEVER reads module binary contents, copies proprietary artifacts,
# builds images, creates flash packages, or accesses a device.  A candidate
# source path is evidence for review only; it is not a binary-compatibility
# claim and must not be used to reuse a 5.10 module on a 6.18 kernel.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/generate_marble_vendor_ledger.sh \
    --xiaomi-root <public-xiaomi-kernel-tree> \
    [--ack-root <ack-port-tree>] \
    [--audit-dir <audit-report-directory>] \
    [--contract <module-porting-contract.tsv>] \
    [--output-dir <text-output-directory>]

Required input files in the audit directory:
  first_stage_load_filename_gaps.txt
  vendor_load_filename_gaps.txt

The default ACK root is the repository root.  The default audit and contract
paths are the committed Evolution X 17 ABI-audit inputs.  Output contains only
TSV/Markdown/text records and source-relative paths.
EOF
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
default_ack_root=$(cd -- "$script_dir/.." && pwd)
ack_root=$default_ack_root
xiaomi_root=
audit_dir="$ack_root/marble-port/reports/evolutionx17_rom_abi_audit"
contract="$ack_root/marble-port/reports/evolutionx17_module_porting_contract.tsv"
output_dir="$ack_root/marble-port/reports/marble_vendor_ledger_2026-08-22"

while (($#)); do
  case "$1" in
    --xiaomi-root)
      xiaomi_root=${2:?missing value for --xiaomi-root}
      shift 2
      ;;
    --ack-root)
      ack_root=${2:?missing value for --ack-root}
      shift 2
      ;;
    --audit-dir)
      audit_dir=${2:?missing value for --audit-dir}
      shift 2
      ;;
    --contract)
      contract=${2:?missing value for --contract}
      shift 2
      ;;
    --output-dir)
      output_dir=${2:?missing value for --output-dir}
      shift 2
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

if [[ -z "$xiaomi_root" ]]; then
  printf 'error: --xiaomi-root is required; do not infer a private or binary reference.\n' >&2
  exit 2
fi

for path in "$ack_root/.git" "$xiaomi_root/.git" \
  "$audit_dir/first_stage_load_filename_gaps.txt" \
  "$audit_dir/vendor_load_filename_gaps.txt" "$contract"; do
  if [[ ! -e "$path" ]]; then
    printf 'error: required path is absent: %s\n' "$path" >&2
    exit 2
  fi
done

ack_root=$(cd -- "$ack_root" && pwd)
xiaomi_root=$(cd -- "$xiaomi_root" && pwd)
audit_dir=$(cd -- "$audit_dir" && pwd)
contract=$(cd -- "$(dirname -- "$contract")" && pwd)/$(basename -- "$contract")
mkdir -p -- "$output_dir"
output_dir=$(cd -- "$output_dir" && pwd)

tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT

first_stage="$audit_dir/first_stage_load_filename_gaps.txt"
vendor_load="$audit_dir/vendor_load_filename_gaps.txt"
ledger_tsv="$output_dir/MARBLE_VENDOR_MODULE_LEDGER.tsv"
summary_md="$output_dir/MARBLE_VENDOR_MODULE_LEDGER_SUMMARY.md"
provenance_txt="$output_dir/LEDGER_INPUT_PROVENANCE.txt"

LC_ALL=C sort -u "$first_stage" > "$tmpdir/first-stage.sorted"
LC_ALL=C sort -u "$vendor_load" > "$tmpdir/vendor-load.sorted"
cat "$tmpdir/first-stage.sorted" "$tmpdir/vendor-load.sorted" | LC_ALL=C sort -u > "$tmpdir/modules.sorted"

# Existing contract records were deliberately kept as an input, not a source
# of truth.  The generated ledger verifies the named Makefile candidates exist
# in the respective checked-out public source trees.
declare -A contract_disposition=()
declare -A contract_reference=()
declare -A contract_target=()
while IFS=$'\t' read -r module _stages disposition reference target _rule; do
  [[ "$module" == "module" || -z "$module" ]] && continue
  contract_disposition["$module"]=$disposition
  contract_reference["$module"]=$reference
  contract_target["$module"]=$target
done < "$contract"

has_member() {
  local needle=$1 file=$2
  grep -Fqx -- "$needle" "$file"
}

family_for() {
  local module=$1
  case "$module" in
    *ufs*|*scsi*|*phy-qcom-qmp*|*pcie*|dwc3-msm.ko|usb_f_*|*usb*|*qcom_q6v5*)
      printf 'storage_usb'
      ;;
    *gpu*|*adreno*|*drm*|*dsi*|*display*|*msm_drm*|*synx*)
      printf 'display_gpu'
      ;;
    *cam*|camera.ko|*cci*|*csid*|*isp*|*actuator*|*ois*|*eeprom*)
      printf 'camera'
      ;;
    *touch*|*fts*|*goodix*|*focaltech*|*fpc*|*fingerprint*|*haptic*)
      printf 'touch_biometrics'
      ;;
    *clk*|*icc*|*interconnect*|*rpmh*|*regulator*|*pmic*|*bcl*|*thermal*|*bwmon*|*dcvs*|*devfreq*)
      printf 'power_clock_interconnect'
      ;;
    *adsp*|*cdsp*|*q6*|*glink*|*rpmsg*|*smem*|*spss*|*modem*|*ipa*|*cnss*|*wlan*|*qrtr*|*qmi*|*gh_*)
      printf 'qcom_vendor'
      ;;
    *)
      printf 'other'
      ;;
  esac
}

dependency_for() {
  local family=$1
  case "$family" in
    storage_usb)
      printf 'Review UFS/PHY/USB/PCIe DT nodes, regulators, clocks, resets, interconnects, IOMMU and any controller/PHY firmware contract.'
      ;;
    power_clock_interconnect)
      printf 'Review PMIC/RPMh/AOP, regulator, clock, interconnect and thermal DT nodes; verify firmware ownership and sequencing where applicable.'
      ;;
    qcom_vendor)
      printf 'Review SMEM, mailbox, interrupt, remoteproc and reserved-memory DT contracts; firmware plus userspace ABI is normally required.'
      ;;
    display_gpu)
      printf 'Review display/GPU DT, regulators, clocks, IOMMU, panel and firmware/userspace ABI contracts; defer from boot-critical scope.'
      ;;
    camera)
      printf 'Review camera DT, regulators, clocks, IOMMU, sensor EEPROM/calibration and proprietary camera-userspace contracts; defer from boot-critical scope.'
      ;;
    touch_biometrics)
      printf 'Review input/bus/IRQ/regulator DT contracts and proprietary HAL/TEE implications; defer unless an early-boot dependency is evidenced.'
      ;;
    *)
      printf 'No generic dependency conclusion is safe; inspect the candidate source, Kconfig, DTS references, firmware request paths and userspace ABI.'
      ;;
  esac
}

verify_paths() {
  local root=$1 list=$2 path result=() found=0
  if [[ "$list" == "-" || -z "$list" ]]; then
    printf '%s' '-'
    return
  fi
  IFS=';' read -r -a paths <<< "$list"
  for path in "${paths[@]}"; do
    [[ -z "$path" || "$path" == "-" ]] && continue
    if [[ -f "$root/$path" ]]; then
      result+=("$path")
      found=1
    else
      result+=("!missing:$path")
    fi
  done
  if ((found == 0)); then
    printf '%s' '-'
  else
    (IFS=';'; printf '%s' "${result[*]}")
  fi
}

nearest_kconfig() {
  local makefiles=$1 makefile dir candidate result=()
  [[ "$makefiles" == "-" || -z "$makefiles" ]] && { printf '%s' '-'; return; }
  IFS=';' read -r -a paths <<< "$makefiles"
  for makefile in "${paths[@]}"; do
    [[ "$makefile" == !missing:* || "$makefile" == "-" ]] && continue
    dir=$(dirname -- "$makefile")
    while [[ "$dir" != "." && "$dir" != "/" ]]; do
      candidate="$ack_root/$dir/Kconfig"
      if [[ -f "$candidate" ]]; then
        result+=("$dir/Kconfig")
        break
      fi
      dir=$(dirname -- "$dir")
    done
  done
  if ((${#result[@]} == 0)); then
    printf '%s' '-'
  else
    printf '%s\n' "${result[@]}" | LC_ALL=C sort -u | paste -sd ';' -
  fi
}

classify() {
  local input_disposition=$1 reference=$2 target=$3
  case "$input_disposition" in
    built_6_18_module|ack_source_candidate)
      if [[ "$target" != "-" ]]; then
        printf 'upstream'
      else
        printf 'defer/disable'
      fi
      ;;
    reference_source_only)
      if [[ "$reference" != "-" && "$target" != "-" ]]; then
        printf 'source-port'
      else
        printf 'defer/disable'
      fi
      ;;
    built_6_18_builtin)
      printf 'defer/disable'
      ;;
    unmapped|*)
      printf 'proprietary-blocked'
      ;;
  esac
}

confidence_for() {
  local disposition=$1 reference=$2 target=$3 kconfig=$4
  case "$disposition" in
    upstream)
      [[ "$target" != "-" && "$kconfig" != "-" ]] && printf 'medium' || printf 'low'
      ;;
    source-port)
      [[ "$reference" != "-" && "$target" != "-" && "$kconfig" != "-" ]] && printf 'medium' || printf 'low'
      ;;
    defer/disable)
      [[ "$reference" != "-" || "$target" != "-" ]] && printf 'low' || printf 'none'
      ;;
    *)
      printf 'none'
      ;;
  esac
}

printf 'module\tfirst_stage_gap\tvendor_load_gap\tfamily\tinput_disposition\txiaomi_candidate_makefiles\tack_candidate_makefiles\tack_kconfig_candidates\tack_kconfig_present\tlikely_dt_firmware_contract\tledger_disposition\tconfidence\tevidence\tb0_effect\n' > "$ledger_tsv"

while IFS= read -r module; do
  first_stage_flag=no
  vendor_load_flag=no
  has_member "$module" "$tmpdir/first-stage.sorted" && first_stage_flag=yes
  has_member "$module" "$tmpdir/vendor-load.sorted" && vendor_load_flag=yes

  input_disposition=${contract_disposition[$module]:-unmapped}
  reference=$(verify_paths "$xiaomi_root" "${contract_reference[$module]:--}")
  target=$(verify_paths "$ack_root" "${contract_target[$module]:--}")
  kconfigs=$(nearest_kconfig "$target")
  kconfig_present=no
  [[ "$kconfigs" != "-" ]] && kconfig_present=yes
  family=$(family_for "$module")
  dependencies=$(dependency_for "$family")
  ledger_disposition=$(classify "$input_disposition" "$reference" "$target")
  confidence=$(confidence_for "$ledger_disposition" "$reference" "$target" "$kconfigs")

  if [[ "$ledger_disposition" == "source-port" ]]; then
    evidence='Existing contract plus verified public Xiaomi and ACK Makefile candidates; port and native build review still required.'
  elif [[ "$ledger_disposition" == "upstream" ]]; then
    evidence='Existing contract identifies an ACK candidate; native configuration, module form, KMI and load-order validation still required.'
  elif [[ "$ledger_disposition" == "defer/disable" ]]; then
    evidence='A public candidate is incomplete for a 6.18 vendor-load plan; do not stage a 5.10 binary or silently omit a required early-load item.'
  else
    evidence='No verified public source candidate was recorded by the existing contract; this is an unresolved blocker, not proof that the artifact is proprietary.'
  fi

  if [[ "$first_stage_flag" == yes ]]; then
    b0_effect='BLOCKED: first-stage filename gap requires a reviewed native 6.18 replacement and load-order evidence.'
  else
    b0_effect='BLOCKED: vendor-load filename gap requires disposition, native build/configuration evidence, and dependency review.'
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$module" "$first_stage_flag" "$vendor_load_flag" "$family" "$input_disposition" \
    "$reference" "$target" "$kconfigs" "$kconfig_present" "$dependencies" \
    "$ledger_disposition" "$confidence" "$evidence" "$b0_effect" >> "$ledger_tsv"
done < "$tmpdir/modules.sorted"

{
  printf 'ACK_COMMIT\t%s\n' "$(git -C "$ack_root" rev-parse HEAD)"
  printf 'XIAOMI_KERNEL_COMMIT\t%s\n' "$(git -C "$xiaomi_root" rev-parse HEAD)"
  printf 'FIRST_STAGE_INPUT\t%s\n' "${first_stage#$ack_root/}"
  printf 'VENDOR_LOAD_INPUT\t%s\n' "${vendor_load#$ack_root/}"
  printf 'CONTRACT_INPUT\t%s\n' "${contract#$ack_root/}"
  printf 'FIRST_STAGE_GAPS\t%s\n' "$(wc -l < "$tmpdir/first-stage.sorted")"
  printf 'VENDOR_LOAD_GAPS\t%s\n' "$(wc -l < "$tmpdir/vendor-load.sorted")"
  printf 'UNIQUE_GAPS\t%s\n' "$(wc -l < "$tmpdir/modules.sorted")"
  printf 'LEDGER_SHA256\t%s\n' "$(sha256sum "$ledger_tsv" | awk '{print $1}')"
  printf 'SCOPE\ttext-only source-candidate inventory; no ROM, module binary, firmware, image, package, key, or device operation was used\n'
} > "$provenance_txt"

{
  cat <<'EOF'
# Marble Vendor Module Candidate Ledger

**Status:** generated static evidence; not a boot or compatibility result.

This report classifies every filename gap reported by the existing Evolution X 17 ABI audit. It verifies only whether public-source Makefile candidates named by the earlier contract are present in the supplied Xiaomi 5.10 and ACK 6.18 trees. It does not compare binaries, preserve a 5.10 ABI, prove a matching Kconfig symbol, resolve every firmware dependency, or authorize a boot-image package.

| Metric | Value |
|---|---:|
EOF
  printf '| First-stage filename gaps | %s |\n' "$(wc -l < "$tmpdir/first-stage.sorted")"
  printf '| Vendor-load filename gaps | %s |\n' "$(wc -l < "$tmpdir/vendor-load.sorted")"
  printf '| Unique filename gaps | %s |\n' "$(wc -l < "$tmpdir/modules.sorted")"
  printf '| Ledger rows | %s |\n' "$(( $(wc -l < "$ledger_tsv") - 1 ))"
  printf '| ACK revision | `%s` |\n' "$(git -C "$ack_root" rev-parse HEAD)"
  printf '| Xiaomi kernel revision | `%s` |\n' "$(git -C "$xiaomi_root" rev-parse HEAD)"
  printf '\n## Disposition Summary\n\n| Ledger disposition | Count | Static meaning |\n|---|---:|---|\n'
  tail -n +2 "$ledger_tsv" | cut -f11 | LC_ALL=C sort | uniq -c | LC_ALL=C sort -k2 | \
    awk '{count=$1; $1=""; sub(/^ /, ""); disposition=$0; meaning=""; if (disposition=="upstream") meaning="ACK candidate exists; native configuration/build and KMI review remain."; else if (disposition=="source-port") meaning="Both source candidates exist; port review remains."; else if (disposition=="defer/disable") meaning="No native vendor-load plan is evidenced."; else meaning="Unresolved public-source candidate; blocks B0."; printf "| %s | %s | %s |\n", disposition, count, meaning}'
  cat <<'EOF'

## Reading Rules

The `ack_kconfig_present` column means that a nearby Kconfig file exists for the target Makefile path; it does **not** assert that a module-specific symbol is enabled or that its value is correct. The `likely_dt_firmware_contract` column is an intentionally conservative review prompt rather than an inferred hardware fact. A `proprietary-blocked` disposition means no verified public candidate is recorded in this input set; it does not establish that the module is definitely proprietary.

Every row retains a **BLOCKED** B0 effect. The required next evidence remains a native 6.18 configuration and build plan, vendor ramdisk/load-order plan, DTB/DTBO container evidence, firmware and userspace-ABI evidence, AVB/recovery evidence, and only then controlled device logs. No 5.10 module may be copied into this plan.

See `LEDGER_INPUT_PROVENANCE.txt` for exact inputs and the ledger hash. The TSV is the normative machine-readable record.
EOF
} > "$summary_md"

printf 'Generated %s\nGenerated %s\nGenerated %s\n' "$ledger_tsv" "$summary_md" "$provenance_txt"
