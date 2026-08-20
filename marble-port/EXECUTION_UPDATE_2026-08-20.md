# تحديث تنفيذ marble — 20 أغسطس 2026

**المؤلف:** Manus AI
**الفرع المصدر:** `marble-6.18-full-port` عند الالتزام `32ffe3adde922d2b927c4849af186317d9dd8643`
**نطاق الجولة:** تأهيل بناء ساكن قابل لإعادة الإنتاج، تثبيت مراجع Xiaomi، وإعادة قياس Device Tree. لا يتضمن النطاق تغليف صور تفليش أو تفليش جهاز أو ادعاء نجاح إقلاع.

## الملخص التنفيذي

نجحت هذه الجولة في تحويل عائق بيئة البناء إلى **بناء AOSP تشخيصي كامل ناجح من شجرة نظيفة**، مع إنشاء `Image` و104 وحدات وBTF وDTB/DTBO. كما جُلبت مراجع Xiaomi الرسمية المثبتة لفرع `marble-s-oss` واستُخدمت لفحص closure وشجرة bindings وجرد فجوات النقل. اجتاز تحقق Device Tree الكامل جميع الأسقف المراجعة: `87/36/128/85` لتحذيرات البناء وDTB والـDTBO والـDTB المدمج على الترتيب.

> لا يثبت هذا النجاح قابلية التفليش أو الإقلاع على POCO F5. لا تزال عقود SPSS/GLINK وقنوات ADC وفجوات Kconfig/وحدات vendor وتوافق ABI/صور الروم واختبار الاسترداد على الجهاز حواجز صريحة.

| مجال القبول | النتيجة | الدليل |
|---|---|---|
| شجرة بناء نظيفة | ناجح | `source_tree_clean=yes` في metadata البناء. |
| بناء AOSP تشخيصي كامل | ناجح | `Image` و`vmlinux` و104 وحدات أُنتجت من الشجرة النظيفة. |
| BTF | ناجح | `pahole v1.31` قرأ `task_struct` من `vmlinux`. |
| DTB وDTBO | ناجح | `ukee.dtb` و`marble-sm7475-pm8008-overlay.dtbo` موجودان وغير فارغين. |
| دمج DTBO وفك المخرجات | ناجح ضمن السقف | الفاحص المدمج مرّ عند `87/36/128/85`. |
| تضمينات Device Tree | ناجح | 36 تضميناً محلياً و30 binding خارجياً؛ كل bindings موجودة. |
| مطابقة GLINK المستهدفة | ناجح ضمن النطاق | `dt-validate -l qcom,glink-edge` خرج بـ0؛ السجل يحوي فقط تجاهل schema عام غير متعلق بالعقدة. |
| توافق جهاز أو تفليش | غير منفذ/محجوب | لا ROM manifest أو ABI/vendor DLKM مثبت ولا جهاز/خطة استرداد مؤكدة. |

## بيئة التحقق وإعادة الإنتاج

بُني `pahole` محلياً من الوسم الرسمي `v1.31` لمشروع dwarves، ثم استُخدم غلاف محلي يثبت مسار المكتبات الديناميكية. يمثل ذلك استيفاء قيد BTF في سكربت البناء؛ ولا يحوّل أدوات المضيف العامة وحدها إلى سلسلة Android release مؤهلة.[1]

جرى البناء من worktree نظيف منفصل، مع:

```text
PAHOLE=/home/ubuntu/work/tools/pahole-v1.31 \
OUT_DIR=/home/ubuntu/work/Kernel-6.18-LTS-build/out/marble-aosp-diagnostic-local \
tools/build_marble_flavor.sh --flavor aosp --diagnostics diagnostic --root none --package none
```

| المخرج | الحجم أو القيمة | SHA-256 عند الاقتضاء |
|---|---:|---|
| `Image` | 46,086,656 بايت | `403cf2aee8a049feea0ad75df481a5715af3f3ec8be0b143d53e59f1a1522a33` |
| `ukee.dtb` | 378,971 بايت | `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0` |
| `marble-sm7475-pm8008-overlay.dtbo` | 68,967 بايت | `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba` |
| `vmlinux` | 233,344,896 بايت | أُنتج مع BTF قابل للقراءة. |
| وحدات kernel | 104 | أُنتجت ضمن البناء التشخيصي. |

## مراجع Xiaomi والتدقيق الساكن

ثُبّت مرجعان رسميان لـXiaomi على فرع `marble-s-oss`: مستودع Device Tree عند `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0`، ومستودع Kernel 5.10 عند `48952ed36228217531482b39d5bef13e7fd808ec`.[2] [3] استخدم الأول لفحص تضمينات DTS/DTSI/DTBO ومقارنة ملفات marble المنقولة، واستخدم الثاني لجرد إعدادات `marble_GKI.config` ووحدات `modules.list.msm.marble`.

| نتيجة الفحص المرجعي | العدد | الحكم |
|---|---:|---|
| ملفات include المحلية في closure | 36 | مغلقة في الشجرة الحالية. |
| `dt-bindings` الخارجية المطلوبة | 30 | موجودة كلها؛ المفقود `0`. |
| طلبات إعداد Xiaomi 5.10 | 429 | مرجع للمراجعة، لا للتمكين الآلي. |
| رموز موجودة اسمياً في ACK | 124 | تتطلب مراجعة للتبعيات والدلالة. |
| رموز غائبة اسمياً في ACK | 305 | فجوات نقل؛ لا يجوز نسخها أو تفعيلها آلياً. |
| وحدات Xiaomi المرجعية | 111 | تتطلب تدقيق ABI وvendor قبل أي دمج. |

مطابقة الملفات بيّنت أن `marble-pinctrl.dtsi` و`xiaomi-sm7475-common.dtsi` يطابقان مرجع Xiaomi حرفياً، وأن overlay PM8008 يطابق مرجعه أيضاً مع اختلاف امتداد الملف المحلي `.dtso`. أما الفروق في `marble-sm7475.dtsi` فهي إصلاحات سياق الحافلة الموثقة سابقاً لـQUP I²C/SPI وإضافات ADC bindings؛ لم تُضف هذه الجولة أي تعديل مصدر Device Tree جديد.

## إعادة قياس Device Tree

يوضح AOSP أن DTS تُترجم إلى DTB وأن DTO يُطبّق من bootloader فوق DTB مركزي، ولذلك فحصت الجولة القاعدة والـoverlay والـDTB المدمج، لا DTBO منفرداً فقط.[4]

| بوابة التحقق | النتيجة الفعلية | السقف المراجع | الحكم |
|---|---:|---:|---|
| تحذيرات بناء DTS/DTBO | 87 | 87 | ناجح |
| فك DTB القاعدة | 36 | 36 | ناجح |
| فك DTBO المفرد | 128 | 128 | ناجح |
| فك DTB المدمج | 85 | 85 | ناجح |

كما استخرج تدقيق السجل 87 تشخيص DTC خاماً. أكبر فئة هي `unit_address_vs_reg` بعدد 74، ويظهر تحذير واحد `reg_format` وتحذيران `avoid_default_addr_size` لعقدة `glink-edge` التابعة لـSPSS. لا تتطابق هذه الفئات الخام واحداً لواحد مع قياسات البوابات الأربع، ولذلك لا ينبغي استعمالها بديلاً عن فاحص البناء/الدمج.

## SPSS وGLINK: قرار عدم التعديل

تطابق تعريف `remoteproc-spss@1880000` وطفله `glink-edge` في `cape.dtsi` مع مرجع Xiaomi المثبت، بما يشمل الزوجين في `reg` و`reg-names = "qcom,spss-addr", "qcom,spss-size"`. كما أن عقدة SPSS النهائية في `ukee.dtsi` تبقي الحالة `disabled`. بحث مصدر ACK يُظهر أن `qcom_common.c` يبحث عن طفل باسم `glink-edge`، لكنه لا يثبت دلالة parser لخصائص SPSS الخاصة أو يبرر تغيير ترميز `reg`/`ranges`.

لذلك لم تُبدّل الخلايا إلى `2/2` ولم تُضف خصائص شكلية لإخماد التحذيرات. يلزم binding أو مصدر driver Qualcomm المطابق لعقد SPSS، ثم اختبار فعلي على الجهاز قبل أي تعديل. يتوافق هذا القرار مع قواعد Device Tree التي تجعل `#address-cells` و`#size-cells` و`reg` و`ranges` جزءاً من عقدة العتاد لا نصاً قابلاً للتجميل.[5]

## القيود والخطوات المطلوبة قبل الجهاز

البناء الناجح هو بوابة ساكنة فقط. لا توجد في الجولة الحالية صورة ROM أصلية موثقة، أو manifest لأقسام `boot`/`vendor_boot`/`dtbo`/`vendor_dlkm`، أو إثبات KMI/ABI لوحدات vendor، أو اختبار استرداد R1. كما لم تُعالج 305 فجوات Kconfig أو 111 وحدة مرجعية؛ فهي قائمة عمل تدقيقية وليست patch queue.

الخطوة الآلية التالية الآمنة هي إنشاء جدول مراجعة **`compatible → driver → CONFIG → ABI/vendor dependency`** للـDTB المدمج، مع إعطاء أولوية لعائلات التخزين والطاقة وremoteproc. أما أول خطوة على الجهاز فلا تبدأ إلا بعد استلام manifest لروم هدف واحد وصور أصلية قابلة للاسترداد وتأكيد وسيلة UART/`pstore`.

## الملفات الناتجة عن الجولة

| الملف | الغرض |
|---|---|
| `marble-port/reports/dtc_warnings_recheck_2026-08-20.tsv` | تشخيصات DTC الخام لإعادة بناء DT. |
| `marble-port/reports/dt_validate_glink_recheck_2026-08-20.log` | نتيجة فحص binding GLINK المعزول. |
| `marble-port/reports/marble_dt_include_closure.txt` | قائمة تضمينات Device Tree المحلية. |
| `marble-port/reports/marble_dt_external_includes.txt` | bindings الخارجية المستخدمة. |
| `marble-port/reports/marble_dt_bindings_summary.tsv` | النتيجة `30 present / 0 missing`. |
| `marble-port/reports/INVENTORY.md` | جرد Kconfig والوحدات والمراجع. |
| `marble-port/reports/execution_web_sources_2026-08-20.md` | سجل المصادر العلنية والالتزامات المثبتة. |

## المراجع

[1]: https://github.com/acmel/dwarves/tree/v1.31 "acmel/dwarves — v1.31"
[2]: https://github.com/MiCode/kernel_devicetree/tree/marble-s-oss "MiCode kernel_devicetree — marble-s-oss"
[3]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss "MiCode Xiaomi Kernel OpenSource — marble-s-oss"
[4]: https://source.android.com/docs/core/architecture/dto "Android Open Source Project — Device tree overlays"
[5]: https://devicetree-specification.readthedocs.io/en/latest/chapter2-devicetree-basics.html "Devicetree Specification — node names, cells, reg and ranges"
