#!/usr/bin/env bash
# Static ABI/DLKM inventory comparison between one extracted Evolution X OTA
# and one locally built marble 6.18 output. This tool never loads modules,
# copies binaries into an image, signs an image, or talks to a device.
#
# Usage:
#   audit_evolutionx17_rom_abi.sh ARTIFACT_DIRECTORY CANDIDATE_BUILD_OUTPUT REPORT_DIRECTORY
set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 ARTIFACT_DIRECTORY CANDIDATE_BUILD_OUTPUT REPORT_DIRECTORY" >&2
    exit 2
fi

ARTIFACT_DIRECTORY=$1
CANDIDATE_BUILD_OUTPUT=$2
REPORT_DIRECTORY=$3
REFERENCE_VENDOR_MODULES="$ARTIFACT_DIRECTORY/vendor_dlkm_inventory/modules.txt"
REFERENCE_RAMDISK_MODULES="$ARTIFACT_DIRECTORY/vendor_boot_dlkm_fragment/modules.txt"
REFERENCE_RAMDISK_LOAD="$ARTIFACT_DIRECTORY/vendor_boot_dlkm_fragment/modules.load"
REFERENCE_VENDOR_LOAD="$ARTIFACT_DIRECTORY/vendor_dlkm_inventory/modules.load"
REFERENCE_VENDOR_SUMMARY="$ARTIFACT_DIRECTORY/vendor_dlkm_inventory/summary.txt"
REFERENCE_BOOT_INSPECTION="$ARTIFACT_DIRECTORY/boot_artifact_inspection.json"
CANDIDATE_IMAGE="$CANDIDATE_BUILD_OUTPUT/arch/arm64/boot/Image"

for required in \
    "$REFERENCE_VENDOR_MODULES" "$REFERENCE_RAMDISK_MODULES" \
    "$REFERENCE_RAMDISK_LOAD" "$REFERENCE_VENDOR_LOAD" \
    "$REFERENCE_VENDOR_SUMMARY" "$REFERENCE_BOOT_INSPECTION" "$CANDIDATE_IMAGE"; do
    [[ -f $required ]] || { echo "Required input missing: $required" >&2; exit 2; }
done

mkdir -p "$REPORT_DIRECTORY"
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

sort -u "$REFERENCE_VENDOR_MODULES" > "$WORKDIR/reference_vendor_modules.txt"
sort -u "$REFERENCE_RAMDISK_MODULES" > "$WORKDIR/reference_ramdisk_modules.txt"
cat "$WORKDIR/reference_vendor_modules.txt" "$WORKDIR/reference_ramdisk_modules.txt" | sort -u > "$WORKDIR/reference_all_modules.txt"
find "$CANDIDATE_BUILD_OUTPUT" -type f -name '*.ko' -printf '%f\n' | sort -u > "$WORKDIR/candidate_modules.txt"

# Android module load manifests use bare module names. Normalize only the
# suffix, preserving all hyphens and underscores in module names.
sed -E '/^[[:space:]]*($|#)/d; s/[[:space:]]+$//; s/$/.ko/' "$REFERENCE_RAMDISK_LOAD" | sort -u > "$WORKDIR/reference_first_stage_load_modules.txt"
sed -E '/^[[:space:]]*($|#)/d; s/[[:space:]]+$//; s/$/.ko/' "$REFERENCE_VENDOR_LOAD" | sort -u > "$WORKDIR/reference_vendor_load_modules.txt"

comm -12 "$WORKDIR/reference_all_modules.txt" "$WORKDIR/candidate_modules.txt" > "$REPORT_DIRECTORY/module_filename_overlap.txt"
comm -23 "$WORKDIR/reference_all_modules.txt" "$WORKDIR/candidate_modules.txt" > "$REPORT_DIRECTORY/reference_module_filename_gaps.txt"
comm -23 "$WORKDIR/reference_first_stage_load_modules.txt" "$WORKDIR/candidate_modules.txt" > "$REPORT_DIRECTORY/first_stage_load_filename_gaps.txt"
comm -23 "$WORKDIR/reference_vendor_load_modules.txt" "$WORKDIR/candidate_modules.txt" > "$REPORT_DIRECTORY/vendor_load_filename_gaps.txt"

awk -F= '/^vermagic=/{print $2}' "$REFERENCE_VENDOR_SUMMARY" | sort -u > "$WORKDIR/reference_vermagic.txt"
strings "$CANDIDATE_IMAGE" | grep -E -m 1 '^Linux version ' | sed 's/[[:space:]]*$//' > "$WORKDIR/candidate_linux_version.txt" || true

{
    printf 'reference_boot_kernel_version='
    python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["boot"]["kernel_version_strings"][1])' "$REFERENCE_BOOT_INSPECTION" 2>/dev/null || true
    printf 'reference_vermagic='; paste -sd ',' "$WORKDIR/reference_vermagic.txt"
    printf 'candidate_image_sha256='; sha256sum "$CANDIDATE_IMAGE" | awk '{print $1}'
    printf 'candidate_linux_version='; cat "$WORKDIR/candidate_linux_version.txt"
    printf '%s\n' 'verdict=Reference 5.10 modules are ABI-incompatible with the candidate 6.18 image and must not be loaded or packaged.'
} > "$REPORT_DIRECTORY/metadata.env"

printf 'metric\tvalue\n' > "$REPORT_DIRECTORY/module_summary.tsv"
printf 'reference_vendor_dlkm_unique\t%s\n' "$(wc -l < "$WORKDIR/reference_vendor_modules.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'reference_vendor_boot_dlkm_unique\t%s\n' "$(wc -l < "$WORKDIR/reference_ramdisk_modules.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'reference_unique_union\t%s\n' "$(wc -l < "$WORKDIR/reference_all_modules.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'reference_first_stage_load_unique\t%s\n' "$(wc -l < "$WORKDIR/reference_first_stage_load_modules.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'reference_vendor_load_unique\t%s\n' "$(wc -l < "$WORKDIR/reference_vendor_load_modules.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'candidate_built_unique\t%s\n' "$(wc -l < "$WORKDIR/candidate_modules.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'same_filename\t%s\n' "$(wc -l < "$REPORT_DIRECTORY/module_filename_overlap.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'reference_filename_not_built\t%s\n' "$(wc -l < "$REPORT_DIRECTORY/reference_module_filename_gaps.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'first_stage_load_filename_not_built\t%s\n' "$(wc -l < "$REPORT_DIRECTORY/first_stage_load_filename_gaps.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"
printf 'vendor_load_filename_not_built\t%s\n' "$(wc -l < "$REPORT_DIRECTORY/vendor_load_filename_gaps.txt")" >> "$REPORT_DIRECTORY/module_summary.tsv"

# Classify gaps deterministically by the leading vendor subsystem token. This
# is triage only, not a claim that same-name modules would be ABI compatible.
awk '
function family(name) {
  if (name ~ /^(msm|qcom|qti|qca|cnss|icnss|ipa|mhi|qrtr|glink|smp2p|adsp|cdsp|q6|wcd|wsa|swr|snd|audio|spf|gpr|slim)/) return "qcom_vendor";
  if (name ~ /^(cam|csiphy|camera)/) return "camera";
  if (name ~ /^(msm_drm|msm_kgsl|gpucc|dispcc|videocc|panel|hdmi|lt9611)/) return "display_gpu";
  if (name ~ /^(goodix|fpc|xiaomi|focaltech|synaptics|fts|atmel)/) return "touch_biometrics";
  if (name ~ /^(clk|gcc|rpmh|icc|qnoc|pinctrl|regulator|pmic|bcl|bwmon)/) return "power_clock_interconnect";
  if (name ~ /^(phy|ufs|dwc3|usb|ehset)/) return "storage_usb";
  return "other";
}
{ count[family($0)]++ }
END { for (entry in count) print entry "\t" count[entry] }
' "$REPORT_DIRECTORY/reference_module_filename_gaps.txt" | sort > "$REPORT_DIRECTORY/module_gap_families.tsv"

printf 'Static Evolution X ROM ABI audit written to %s\n' "$REPORT_DIRECTORY"
