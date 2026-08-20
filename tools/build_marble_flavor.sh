#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# Build a source-only marble GKI artifact. This script never flashes or signs images.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCH=arm64
JOBS="${JOBS:-$(nproc)}"
PAHOLE_TOOL="${PAHOLE:-pahole}"
FLAVOR=aosp
ROOT_MODE=none
DIAGNOSTICS=release
PACKAGE=none

usage() {
  cat <<'EOF'
Usage: tools/build_marble_flavor.sh [options]

Options:
  --flavor aosp|xiaomi|evolutionx-17
                                Target ROM integration provenance (default: aosp)
  --root none|ksu-next|apatch   Root policy (default: none)
  --diagnostics release|diagnostic
                                Kernel diagnostics profile (default: release)
  --package none|boot           Packaging mode (default: none)
  --help                        Show this help

The script builds Image, modules, ukee.dtb, and marble DTBO only.  Selecting
evolutionx-17 changes provenance metadata only; it never imports ROM binaries.
Packaging is refused until a reviewed ROM manifest and hardware/KMI acceptance
evidence exist.
EOF
}

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

while (($#)); do
  case "$1" in
    --flavor) FLAVOR="${2:-}"; shift 2 ;;
    --root) ROOT_MODE="${2:-}"; shift 2 ;;
    --diagnostics) DIAGNOSTICS="${2:-}"; shift 2 ;;
    --package) PACKAGE="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
done

case "$FLAVOR" in aosp|xiaomi|evolutionx-17) ;; *) fail "Unsupported flavor: $FLAVOR" ;; esac
case "$DIAGNOSTICS" in release|diagnostic) ;; *) fail "Unsupported diagnostics profile: $DIAGNOSTICS" ;; esac
case "$PACKAGE" in none|boot) ;; *) fail "Unsupported package mode: $PACKAGE" ;; esac

case "$ROOT_MODE" in
  none) ;;
  ksu-next)
    fail "KernelSU Next upstream support ends at Linux 6.6; it is not integrated into this 6.18 build."
    ;;
  apatch)
    fail "APatch upstream support ends at Linux 6.12; it is not integrated into this 6.18 build."
    ;;
  *) fail "Unsupported root mode: $ROOT_MODE" ;;
esac

[[ "$PACKAGE" == none ]] || fail "boot packaging is blocked: provide a reviewed ROM manifest and pass KMI and device acceptance first."

CORE="$ROOT/arch/arm64/configs/marble_gki_6_18_core.config"
PROTO="$ROOT/arch/arm64/configs/marble_gki_6_18_proto.config"
DIAGNOSTIC="$ROOT/arch/arm64/configs/marble_gki_6_18_diagnostic.config"
for fragment in "$CORE" "$PROTO"; do
  [[ -f "$fragment" ]] || fail "Missing configuration fragment: $fragment"
done
if [[ "$PAHOLE_TOOL" == */* ]]; then
  [[ -x "$PAHOLE_TOOL" ]] || fail "Configured pahole is not executable: $PAHOLE_TOOL"
else
  command -v "$PAHOLE_TOOL" >/dev/null || fail "Configured pahole is not in PATH: $PAHOLE_TOOL"
fi
if [[ "$DIAGNOSTICS" == diagnostic ]]; then
  [[ -f "$DIAGNOSTIC" ]] || fail "Missing diagnostic fragment: $DIAGNOSTIC"
fi

OUT="${OUT_DIR:-$ROOT/out/marble-${FLAVOR}-${DIAGNOSTICS}-${ROOT_MODE}}"
rm -rf "$OUT"
mkdir -p "$OUT"

make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 PAHOLE="$PAHOLE_TOOL" gki_defconfig
fragments=("$CORE" "$PROTO")
if [[ "$DIAGNOSTICS" == diagnostic ]]; then
  fragments+=("$DIAGNOSTIC")
fi

# Apply fragments in order, replacing prior assignments for each symbol.  This
# retains normal fragment precedence (diagnostic over proto) without emitting
# duplicate-assignment diagnostics for settings already selected by GKI.
merge_fragment() {
  local fragment line symbol
  fragment="$1"
  while IFS= read -r line; do
    if [[ "$line" =~ ^(CONFIG_[A-Za-z0-9_]+)= ]]; then
      symbol="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^\#\ (CONFIG_[A-Za-z0-9_]+)\ is\ not\ set$ ]]; then
      symbol="${BASH_REMATCH[1]}"
    else
      continue
    fi
    sed -i -E "/^${symbol}=/d; /^# ${symbol} is not set$/d" "$OUT/.config"
    printf '%s\n' "$line" >> "$OUT/.config"
  done < "$fragment"
}
for fragment in "${fragments[@]}"; do
  merge_fragment "$fragment"
done
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 PAHOLE="$PAHOLE_TOOL" \
  LOCALVERSION="-marble-${FLAVOR}-${DIAGNOSTICS}" olddefconfig
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 PAHOLE="$PAHOLE_TOOL" \
  LOCALVERSION="-marble-${FLAVOR}-${DIAGNOSTICS}" -j"$JOBS" Image modules
make -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 PAHOLE="$PAHOLE_TOOL" DTC_FLAGS="-@" -j"$JOBS" \
  qcom/ukee.dtb qcom/marble-sm7475-pm8008-overlay.dtbo

IMAGE="$OUT/arch/arm64/boot/Image"
[[ -s "$IMAGE" ]] || fail "Expected Image was not produced: $IMAGE"

{
  printf 'source_commit=%s\n' "$(git -C "$ROOT" rev-parse HEAD)"
  printf 'source_tree_clean=%s\n' "$([[ -z "$(git -C "$ROOT" status --porcelain)" ]] && printf yes || printf no)"
  printf 'rom_flavor=%s\n' "$FLAVOR"
  printf 'root_mode=%s\n' "$ROOT_MODE"
  printf 'diagnostics=%s\n' "$DIAGNOSTICS"
  printf 'package=%s\n' "$PACKAGE"
  printf 'kernel_release=%s\n' "$(make -s -C "$ROOT" O="$OUT" ARCH="$ARCH" LLVM=1 LLVM_IAS=1 PAHOLE="$PAHOLE_TOOL" kernelrelease)"
  printf 'pahole=%s\n' "$PAHOLE_TOOL"
  printf 'pahole_version=%s\n' "$("$PAHOLE_TOOL" --version | head -1)"
  printf 'image_sha256=%s\n' "$(sha256sum "$IMAGE" | awk '{print $1}')"
  printf 'modules_present=%s\n' "$(find "$OUT" -type f -name '*.ko' | wc -l)"
  printf 'ukee_dtb_sha256=%s\n' "$(sha256sum "$OUT/arch/arm64/boot/dts/qcom/ukee.dtb" | awk '{print $1}')"
  printf 'marble_dtbo_sha256=%s\n' "$(sha256sum "$OUT/arch/arm64/boot/dts/qcom/marble-sm7475-pm8008-overlay.dtbo" | awk '{print $1}')"
} > "$OUT/build-metadata.txt"

printf 'Build completed successfully.\nMetadata: %s\n' "$OUT/build-metadata.txt"
