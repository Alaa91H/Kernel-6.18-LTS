# جرد marble — مصدر Xiaomi 5.10 مقابل ACK 6.18

هذا التقرير مُنشأ آلياً. يقارن رموز `marble_GKI.config` في مصدر Xiaomi مع رموز Kconfig المتاحة في شجرة ACK الحالية، ويثبت مراجع Device Tree وقائمة وحدات vendor.

| المجال | النتيجة | التفسير |
|---|---:|---|
| طلبات إعداد Xiaomi marble | 429 | رموز Kconfig المذكورة في `marble_GKI.config`. |
| رموز موجودة اسمياً في ACK | 124 | قابلة للمراجعة يدوياً من حيث التبعيات والمعنى. |
| رموز غائبة اسمياً من ACK | 305 | لا يجوز تمريرها تلقائياً؛ تتطلب نقلاً أو بديلاً. |
| ملفات DTS/DTSI/DTBO المرتبطة بـ marble أو SM7475 | 4 | مستخرجة من مستودع Xiaomi المنفصل للـDevice Tree. |
| وحدات قائمة marble | 111 | وحدات مرجعية من `modules.list.msm.marble`. |


## توزيع فجوات Kconfig حسب الطبقة

| الطبقة | عدد الرموز الغائبة |
|---|---:|
| `audio` | 1 |
| `camera` | 2 |
| `diagnostics-and-vendor-hooks` | 28 |
| `graphics-and-display` | 5 |
| `memory-and-interconnect` | 21 |
| `modem-dsp-and-remoteproc` | 19 |
| `other` | 100 |
| `power-and-thermal` | 28 |
| `qualcomm-platform` | 86 |
| `storage` | 4 |
| `wireless-and-peripherals` | 11 |

## ملفات Device Tree المرجعية

- `qcom/marble-pinctrl.dtsi`
- `qcom/marble-sm7475-pm8008-overlay.dts`
- `qcom/marble-sm7475.dtsi`
- `qcom/xiaomi-sm7475-common.dtsi`

## توزيع الوحدات حسب الطبقة الوظيفية

| الطبقة | عدد الوحدات المرجعية |
|---|---:|
| `clocks-and-pinctrl` | 10 |
| `diagnostics-and-vendor-hooks` | 10 |
| `interconnect-memory-and-iommu` | 14 |
| `ipc-virtualization-and-firmware` | 14 |
| `other-vendor-modules` | 15 |
| `peripherals-and-connectivity` | 14 |
| `power-and-scheduling` | 24 |
| `storage-and-crypto` | 10 |

## توزيع الوحدات حسب البادئة الاسمية

| البادئة | عدد الوحدات |
|---|---:|
| `arm` | 1 |
| `bcl` | 1 |
| `bwmon` | 1 |
| `c1dcvs` | 2 |
| `cfg80211` | 1 |
| `clk` | 3 |
| `cmd` | 1 |
| `cpu` | 1 |
| `cqhci` | 1 |
| `crypto` | 2 |
| `dcvs` | 1 |
| `debug` | 1 |
| `deferred` | 1 |
| `dispcc` | 2 |
| `dma` | 1 |
| `extend` | 1 |
| `gcc` | 2 |
| `gdsc` | 1 |
| `gh` | 7 |
| `hwid` | 1 |
| `hwkm` | 1 |
| `icc` | 3 |
| `iommu` | 1 |
| `kryo` | 1 |
| `llcc` | 1 |
| `mac80211` | 1 |
| `mem` | 4 |
| `memory` | 1 |
| `metis` | 1 |
| `mi` | 1 |
| `minidump` | 1 |
| `msm` | 5 |
| `nfc` | 1 |
| `ns` | 1 |
| `nvmem` | 1 |
| `phy` | 5 |
| `pinctrl` | 4 |
| `pmu` | 2 |
| `proxy` | 1 |
| `qcom` | 22 |
| `qnoc` | 3 |
| `qrtr` | 1 |
| `qti` | 2 |
| `reboot` | 1 |
| `regmap` | 1 |
| `rpmh` | 1 |
| `rtc` | 1 |
| `sched` | 2 |
| `secure` | 1 |
| `smem` | 1 |
| `socinfo` | 1 |
| `spmi` | 1 |
| `stub` | 1 |
| `thermal` | 1 |
| `tmecom` | 1 |
| `ufs` | 1 |
| `ufshcd` | 1 |

## الملفات الناتجة

| الملف | الغرض |
|---|---|
| `marble_gki_config_present.tsv` | رموز إعداد مرجعية ما زالت موجودة اسمياً في ACK. |
| `marble_gki_config_missing.tsv` | رموز مفقودة؛ تمثل فجوات نقل لا تُفعّل تلقائياً. |
| `marble_gki_missing_categories.tsv` | توزيع فجوات Kconfig حسب الطبقة العتادية. |
| `marble_dts_references.txt` | ملفات DTS/DTSI/DTBO المرجعية. |
| `marble_module_categories.tsv` | توزيع أولي لوحدات vendor حسب الطبقة الوظيفية. |
| `marble_module_prefixes.tsv` | توزيع أولي لوحدات vendor حسب البادئة الاسمية. |

> الوجود الاسمي للرمز لا يثبت أن التعريف أو التبعية توافق 6.18. والغِياب لا يثبت استحالة النقل؛ إنه فقط يمنع النقل الآلي غير المراجع.
