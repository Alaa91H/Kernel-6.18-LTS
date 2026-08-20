#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${OUT:-$KERNEL_ROOT/out/marble-diagnostic-config}"
CORE="$KERNEL_ROOT/arch/arm64/configs/marble_gki_6_18_core.config"
PROTO="$KERNEL_ROOT/arch/arm64/configs/marble_gki_6_18_proto.config"
DIAGNOSTIC="$KERNEL_ROOT/arch/arm64/configs/marble_gki_6_18_diagnostic.config"

rm -rf "$OUT"
make -s -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 gki_defconfig
"$KERNEL_ROOT/scripts/kconfig/merge_config.sh" -m -O "$OUT" "$OUT/.config" \
  "$CORE" "$PROTO" "$DIAGNOSTIC"
make -s -C "$KERNEL_ROOT" O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 olddefconfig

symbols=(
  DEBUG_INFO_BTF DEBUG_INFO_BTF_MODULES DYNAMIC_DEBUG
  FUNCTION_TRACER FUNCTION_GRAPH_TRACER FTRACE_SYSCALLS BOOTTIME_TRACING
  PSTORE PSTORE_RAM PSTORE_CONSOLE PSTORE_PMSG PSTORE_FTRACE
)

for symbol in "${symbols[@]}"; do
  grep -qx "CONFIG_${symbol}=y" "$OUT/.config" || {
    printf 'Required marble diagnostic symbol not enabled: %s\n' "$symbol" >&2
    exit 1
  }
done

printf 'Marble diagnostic configuration validation passed (%s symbols).\n' "${#symbols[@]}"
