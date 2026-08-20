#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$KERNEL_ROOT/out/marble-core-config}"
FRAGMENT="$KERNEL_ROOT/arch/arm64/configs/marble_gki_6_18_core.config"

rm -rf "$OUT"
make -s -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 gki_defconfig

# Replace each fragment symbol rather than appending a duplicate assignment.
# This keeps the validator's generated .config diagnostic-clean while retaining
# the same olddefconfig resolution semantics as the flavor build.
tmp_config="$(mktemp)"
trap 'rm -f "$tmp_config"' EXIT
cp "$OUT/.config" "$tmp_config"
while IFS= read -r assignment; do
  [[ -z "$assignment" || "$assignment" == \#* ]] && continue
  symbol="${assignment%%=*}"
  grep -qE "^${symbol}=|^# ${symbol} is not set$" "$tmp_config" && \
    sed -i -E "/^${symbol}=/d; /^# ${symbol} is not set$/d" "$tmp_config"
  printf '%s\n' "$assignment" >> "$tmp_config"
done < "$FRAGMENT"
mv "$tmp_config" "$OUT/.config"
make -s -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig

symbols=(
  SCSI_UFSHCD SCSI_UFS_QCOM
  QCOM_RPMH QCOM_COMMAND_DB QCOM_RPMHPD REGULATOR_QCOM_RPMH
  USB_DWC3 PHY_QCOM_QMP OF_OVERLAY
  SPMI_MSM_PMIC_ARB QCOM_SPMI_ADC5 QCOM_SPMI_ADC_TM5
  HWSPINLOCK_QCOM QCOM_IPCC QCOM_SMEM QCOM_SMP2P
)

for symbol in "${symbols[@]}"; do
  grep -qx "CONFIG_${symbol}=y" "$OUT/.config" || {
    printf 'Required marble core symbol not enabled: %s\n' "$symbol" >&2
    exit 1
  }
done

printf 'Marble core GKI configuration validation passed (%s symbols).\n' "${#symbols[@]}"
