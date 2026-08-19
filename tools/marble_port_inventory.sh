#!/usr/bin/env bash
set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFERENCE_ROOT="${REFERENCE_ROOT:-$(cd "$KERNEL_ROOT/../reference" && pwd)}"
XIAOMI_KERNEL="${XIAOMI_KERNEL:-$REFERENCE_ROOT/xiaomi-marble-5.10}"
XIAOMI_DT="${XIAOMI_DT:-$REFERENCE_ROOT/xiaomi-marble-devicetree}"
OUT_DIR="${OUT_DIR:-$KERNEL_ROOT/marble-port/reports}"
CONFIG_REF="$XIAOMI_KERNEL/arch/arm64/configs/vendor/marble_GKI.config"
MODULES_REF="$XIAOMI_KERNEL/modules.list.msm.marble"

for required in "$KERNEL_ROOT" "$XIAOMI_KERNEL" "$XIAOMI_DT" "$CONFIG_REF" "$MODULES_REF"; do
  if [[ ! -e "$required" ]]; then
    printf 'Missing required path: %s\n' "$required" >&2
    exit 1
  fi
done

mkdir -p "$OUT_DIR"
KCONFIG_SYMBOLS="$OUT_DIR/ack_kconfig_symbols.txt"
REQUESTS="$OUT_DIR/marble_gki_config_requests.tsv"
PRESENT="$OUT_DIR/marble_gki_config_present.tsv"
MISSING="$OUT_DIR/marble_gki_config_missing.tsv"
DT_FILES="$OUT_DIR/marble_dts_references.txt"
MODULE_SUMMARY="$OUT_DIR/marble_module_prefixes.tsv"
MODULE_CATEGORIES="$OUT_DIR/marble_module_categories.tsv"
CONFIG_CATEGORIES="$OUT_DIR/marble_gki_missing_categories.tsv"
REPORT="$OUT_DIR/INVENTORY.md"

find "$KERNEL_ROOT" \
  -path "$KERNEL_ROOT/.git" -prune -o \
  -path "$KERNEL_ROOT/out" -prune -o \
  -type f -name 'Kconfig*' -print0 \
  | xargs -0 grep -hE '^(config|menuconfig)[[:space:]]+[A-Za-z0-9_]+' \
  | awk '{print $2}' \
  | sort -u > "$KCONFIG_SYMBOLS"

awk '
  /^CONFIG_[A-Za-z0-9_]+=/{
    line=$0; sub(/^CONFIG_/, "", line); split(line, pair, "="); print pair[1] "\tenabled\t" $0
  }
  /^# CONFIG_[A-Za-z0-9_]+ is not set$/{
    line=$0; sub(/^# CONFIG_/, "", line); sub(/ is not set$/, "", line); print line "\tdisabled\t" $0
  }
' "$CONFIG_REF" | sort -u > "$REQUESTS"

: > "$PRESENT"
: > "$MISSING"
while IFS=$'\t' read -r symbol state original; do
  if grep -qx "$symbol" "$KCONFIG_SYMBOLS"; then
    printf '%s\t%s\t%s\n' "$symbol" "$state" "$original" >> "$PRESENT"
  else
    printf '%s\t%s\t%s\n' "$symbol" "$state" "$original" >> "$MISSING"
  fi
done < "$REQUESTS"

find "$XIAOMI_DT/qcom" -type f \( -name '*.dts' -o -name '*.dtsi' -o -name '*.dtso' \) -print \
  | while IFS= read -r file; do
      if grep -qiE 'marble|sm7475' "$file" || [[ "$(basename "$file")" =~ (marble|sm7475) ]]; then
        printf '%s\n' "${file#$XIAOMI_DT/}"
      fi
    done | sort -u > "$DT_FILES"

awk '
  /^[[:space:]]*#/ || /^[[:space:]]*$/ {next}
  {
    module=$1
    sub(/^.*\//, "", module)
    sub(/\.ko$/, "", module)
    prefix=module
    sub(/[-_].*$/, "", prefix)
    if (prefix == "") prefix="other"
    count[prefix]++
  }
  END { for (p in count) print p "\t" count[p] }
' "$MODULES_REF" | sort > "$MODULE_SUMMARY"

awk '
  function category(module) {
    if (module ~ /(ufs|cqhci|crypto-qti|hwkm)/) return "storage-and-crypto"
    if (module ~ /(rpmh|regulator|dcvs|cpufreq|bcl|thermal|cpu_hotplug|sched-walt|reboot|wdt)/) return "power-and-scheduling"
    if (module ~ /(icc|qnoc|bwmon|llcc|iommu|smmu|dma)/) return "interconnect-memory-and-iommu"
    if (module ~ /(clk|gcc|dispcc|pinctrl)/) return "clocks-and-pinctrl"
    if (module ~ /(smem|qcom_ipcc|ipc|gh_|qrtr|qcom_aoss|qcom_scm|qcom-pdc|qcom-pmu|pmu_)/) return "ipc-virtualization-and-firmware"
    if (module ~ /(cfg80211|mac80211|nfc|geni|qmp|spmi|rtc|hwid|metis|mi_schedule)/) return "peripherals-and-connectivity"
    if (module ~ /(minidump|memory_dump|mem-|mem_|rtb|logger|debug|hooks|rimps)/) return "diagnostics-and-vendor-hooks"
    return "other-vendor-modules"
  }
  /^[[:space:]]*#/ || /^[[:space:]]*$/ {next}
  {
    module=$1; sub(/^.*\//, "", module); sub(/\.ko$/, "", module)
    count[category(module)]++
  }
  END { for (c in count) print c "\t" count[c] }
' "$MODULES_REF" | sort > "$MODULE_CATEGORIES"

awk -F '\t' '
  function category(symbol) {
    if (symbol ~ /(KGSL|MSM_DRM|DRM_MSM|SDE|PANEL|DISPLAY)/) return "graphics-and-display"
    if (symbol ~ /(CAMERA|CAM_|MSM_CAMERA|ISP)/) return "camera"
    if (symbol ~ /(AUDIO|SND|WCD|SLIMBUS|SLIM_)/) return "audio"
    if (symbol ~ /(CNSS|WCNSS|WIFI|BLUETOOTH|BT_|NFC)/) return "wireless-and-peripherals"
    if (symbol ~ /(QTI_BATTERY|CHARGER|BCL|REGULATOR|CPUTEMP|COOLING|THERMAL|CPUFREQ|DCVS|PMIC|RPMH)/) return "power-and-thermal"
    if (symbol ~ /(UFS|SCSI|STORAGE|MMC)/) return "storage"
    if (symbol ~ /(MODEM|MDM|QMI|QRTR|GLINK|SUBSYS|PIL|REMOTE|SPSS|ADSP|CDSP)/) return "modem-dsp-and-remoteproc"
    if (symbol ~ /(MINIDUMP|RAMDUMP|PSTORE|QDSS|TRACE|DEBUG|LOG|HOOK|MEMORY_DUMP)/) return "diagnostics-and-vendor-hooks"
    if (symbol ~ /(IOMMU|SMMU|LLCC|DMA|INTERCONNECT|ICC|QOS|NOC)/) return "memory-and-interconnect"
    if (symbol ~ /^(QCOM|QTI|MSM|QPNP|QSEE|QSEECOM|QMP|GUNYAH|GH_)/) return "qualcomm-platform"
    return "other"
  }
  { count[category($1)]++ }
  END { for (c in count) print c "\t" count[c] }
' "$MISSING" | sort > "$CONFIG_CATEGORIES"

config_total=$(wc -l < "$REQUESTS")
config_present=$(wc -l < "$PRESENT")
config_missing=$(wc -l < "$MISSING")
dt_total=$(wc -l < "$DT_FILES")
module_total=$(grep -Ev '^[[:space:]]*(#|$)' "$MODULES_REF" | wc -l)

{
  printf '# جرد marble — مصدر Xiaomi 5.10 مقابل ACK 6.18\n\n'
  printf 'هذا التقرير مُنشأ آلياً. يقارن رموز `marble_GKI.config` في مصدر Xiaomi مع رموز Kconfig المتاحة في شجرة ACK الحالية، ويثبت مراجع Device Tree وقائمة وحدات vendor.\n\n'
  printf '| المجال | النتيجة | التفسير |\n|---|---:|---|\n'
  printf '| طلبات إعداد Xiaomi marble | %s | رموز Kconfig المذكورة في `marble_GKI.config`. |\n' "$config_total"
  printf '| رموز موجودة اسمياً في ACK | %s | قابلة للمراجعة يدوياً من حيث التبعيات والمعنى. |\n' "$config_present"
  printf '| رموز غائبة اسمياً من ACK | %s | لا يجوز تمريرها تلقائياً؛ تتطلب نقلاً أو بديلاً. |\n' "$config_missing"
  printf '| ملفات DTS/DTSI/DTBO المرتبطة بـ marble أو SM7475 | %s | مستخرجة من مستودع Xiaomi المنفصل للـDevice Tree. |\n' "$dt_total"
  printf '| وحدات قائمة marble | %s | وحدات مرجعية من `modules.list.msm.marble`. |\n\n' "$module_total"
  printf '\n## توزيع فجوات Kconfig حسب الطبقة\n\n| الطبقة | عدد الرموز الغائبة |\n|---|---:|\n'
  while IFS=$'\t' read -r category count; do printf '| `%s` | %s |\n' "$category" "$count"; done < "$CONFIG_CATEGORIES"
  printf '\n## ملفات Device Tree المرجعية\n\n'
  if [[ "$dt_total" -gt 0 ]]; then
    while IFS= read -r file; do printf -- '- `%s`\n' "$file"; done < "$DT_FILES"
  else
    printf 'لم يعثر الجرد على ملفات مطابقة؛ راجع مصدر Device Tree.\n'
  fi
  printf '\n## توزيع الوحدات حسب الطبقة الوظيفية\n\n| الطبقة | عدد الوحدات المرجعية |\n|---|---:|\n'
  while IFS=$'\t' read -r category count; do printf '| `%s` | %s |\n' "$category" "$count"; done < "$MODULE_CATEGORIES"
  printf '\n## توزيع الوحدات حسب البادئة الاسمية\n\n| البادئة | عدد الوحدات |\n|---|---:|\n'
  while IFS=$'\t' read -r prefix count; do printf '| `%s` | %s |\n' "$prefix" "$count"; done < "$MODULE_SUMMARY"
  printf '\n## الملفات الناتجة\n\n'
  printf '| الملف | الغرض |\n|---|---|\n'
  printf '| `marble_gki_config_present.tsv` | رموز إعداد مرجعية ما زالت موجودة اسمياً في ACK. |\n'
  printf '| `marble_gki_config_missing.tsv` | رموز مفقودة؛ تمثل فجوات نقل لا تُفعّل تلقائياً. |\n'
  printf '| `marble_gki_missing_categories.tsv` | توزيع فجوات Kconfig حسب الطبقة العتادية. |\n'
  printf '| `marble_dts_references.txt` | ملفات DTS/DTSI/DTBO المرجعية. |\n'
  printf '| `marble_module_categories.tsv` | توزيع أولي لوحدات vendor حسب الطبقة الوظيفية. |\n'
  printf '| `marble_module_prefixes.tsv` | توزيع أولي لوحدات vendor حسب البادئة الاسمية. |\n'
  printf '\n> الوجود الاسمي للرمز لا يثبت أن التعريف أو التبعية توافق 6.18. والغِياب لا يثبت استحالة النقل؛ إنه فقط يمنع النقل الآلي غير المراجع.\n'
} > "$REPORT"

printf 'Inventory written to %s\n' "$REPORT"
