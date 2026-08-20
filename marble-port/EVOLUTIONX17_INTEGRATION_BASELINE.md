# خط أساس تكامل Evolution X 17 لجهاز marble

**الحالة:** أدلة مصدر ثابتة مكتملة؛ جرد ملف ROM الرسمي الثنائي ما زال قيد الاستلام، ولذلك فإن إنشاء `boot.img` أو `vendor_boot.img` أو تفليش أي مخرج **محظور**. هذا المستند ليس اعتماد توافق إقلاع.

## نطاق الدليل

يستهدف هذا الخط الأساس جهاز **POCO F5 / Redmi Note 12 Turbo (`marble`)** وإصدار Evolution X 12.1 المبني على Android 17. صفحة الجهاز الرسمية تسجل `marble` ضمن أجهزة Android 17، ويُعامل رابط ROM الرسمي المسجل في تقرير الاكتشاف كمدخل غير منفذ حتى يكتمل التحقق من البصمة والمحتويات.[1]

| عنصر الدليل | المصدر المثبت | الالتزام / النسخة | الغرض |
|---|---|---:|---|
| شجرة جهاز Evolution X | `Evolution-X-Devices/device_xiaomi_marble` | `a8d866758688862bcff9c5d9b2ff3ba00fc9b549`، 2026-06-25 | تعريف الجهاز وخصائص `marble`. |
| الشجرة المشتركة | `Evolution-X-Devices/device_xiaomi_sm8450-common` | `b73b209ae0ec6858a03117e89b4705174bd1fcac`، 2026-06-29 | عقد صور الإقلاع، DLKM وVINTF. |
| مصدر kernel المرجعي | `Evolution-X-Devices/kernel_xiaomi_sm8450` | `e8fcf25587112c854814dbe399a99110d18c82de`، 2026-07-03 | مرجع تهيئة vendor 5.10 وقوائم الوحدات، لا مصدر قابل للخلط مع 6.18. |
| artefacts 5.10 القديمة المنشورة | `Evolution-X-Devices/device_xiaomi_marble-kernel` | `03dda81f521cf7ab016ef8558b3f9d67d0fdaf79`، 2024-03-19 | مرجع تاريخي لبنية DLKM فقط؛ ليس مرجع ABI لـEvolution X 17. |
| مرشح 6.18 المحلي | `android17-6.18-lts` عند `4e44babe3f67` | Linux 6.18.32 | النواة العامة محل الاختبار. |

> **قاعدة ABI:** وحدات 5.10 الثنائية لا تُحمّل، ولا تُنسخ، ولا تُوقّع، ولا تُغلف مع نواة 6.18. تطابق الاسم لا يثبت توافق ABI أو KMI.

## عقد Evolution X المستخرج من المصدر

تستورد شجرة `marble` شجرة `sm8450-common`. ينص تكوينها على `TARGET_KERNEL_SOURCE := kernel/xiaomi/sm8450` مع `gki_defconfig` وأجزاء `waipio_GKI.config` و`xiaomi_GKI.config` و`marble_GKI.config` و`debugfs.config`.[2] يوضح ذلك أن هدف Evolution X الحالي مبني حول مجموعة تعريفات Qualcomm/Xiaomi vendor 5.10، وليس حول Android Common Kernel 6.18.

| مجال | عقد Evolution X المعلن | أثره على 6.18 العامة |
|---|---|---|
| الإقلاع | Boot header v4، `Image`، وDTB مضمّن في boot. | يجب استخراج `boot.img` الفعلي للتحقق من page size، ramdisk وcmdline؛ لا يجوز تخمينها. |
| Device Tree | GKI مفعّل، دمج DTBs لـQCOM، و`TARGET_NEEDS_DTBOIMAGE := true`. | يلزم مقارنة `dtbo.img` الحقيقي مع DTBO المبني لـmarble بعد استلام ROM. |
| A/B | تتضمن قائمة OTA: `boot` و`dtbo` و`vendor_boot` و`vendor_dlkm` إضافة إلى الأقسام الديناميكية. | يفرض جرد صور متسق من **البناء نفسه** قبل أي تغليف. |
| vendor ramdisk | fragment باسم `dlkm`؛ قوائم تحميل مرحلتين. | وحدات المرحلة الأولى ضرورية للإقلاع، ولا يمكن تبديلها بوحدات 5.10 عند اختبار 6.18. |
| vendor DLKM | `vendor_dlkm` ext4 وقائمة وحدات خاصة. | يتطلب بدائل 6.18 مبنية من المصدر أو تجميد استخدام النواة العامة حتى تتوفر طبقة vendor ملائمة. |
| AVB | AVB مفعّل وvbmeta system منفصل. | لا توجد مفاتيح أو سياسة قبول مكتملة؛ لذلك يبقى التغليف مرفوضاً. |

## نتيجة التدقيق الثابت

شُغلت `tools/audit_evolutionx17_kernel_contract.sh` على مخرج `marble-aosp-diagnostic-none` ونفّذت مقارنة تهيئة وأسماء فقط. استُخدمت التهيئتان `marble_GKI.config` و`waipio_GKI.config` من مرجع Evolution X 5.10.256، ثم قورنتا مع `.config` المرشح 6.18. لا يحول هذا التدقيق الاختلافات إلى طلبات تفعيل تلقائية لأن رموز vendor قد لا تكون موجودة أصلاً في Android Common Kernel 6.18.

| مقياس | النتيجة | القراءة الصحيحة |
|---|---:|---|
| رموز مرجع 5.10 الفعالة | 344 | عقد قدرات vendor تاريخي/مرجعي. |
| رموز ظاهرة كـ enabled في مرشح 6.18 | 9 | ليست دليلاً على تكافؤ العتاد. |
| رموز مفقودة أو معطلة في المقارنة الاسمية | 335 | فجوات متوقعة بين شجرة Qualcomm/Xiaomi 5.10 وACK 6.18؛ تحتاج porting حقيقياً أو بدائل upstream. |
| وحدات مرحلة أولى فريدة في المرجع | 97 | تعتمد على ABI وواجهات 5.10 الخاصة بالمورّد. |
| ملفات `.ko` فريدة مبنية في مرشح 6.18 | 104 | مخرجات ACK عامة وليست بديلاً اسميّاً للوحدات المرجعية. |
| تداخل أسماء وحدات المرحلة الأولى | 0 | **ليس** دليلاً على عيب تغليف؛ بل تأكيد أن الاستبدال الثنائي غير صالح. |

أبرز عائلات الفجوات هي Qualcomm clocks/interconnect/RPMh، UFS وUSB PHY، CNSS/WLAN، display/KGSL/camera/audio، DSP/ADSP وIPA/MHI، الطاقة والحرارة وإدخال اللمس. هذه النتيجة تتسق مع تدقيق فجوات vendor العام في `MEDIA_VENDOR_GAPS.md`، وتحوّل بوابة الاختبار من «بناء Image» إلى «نقل تفرعات vendor أو التحقق من دعم upstream الفعلي».

## artefact ROM الرسمي وحالته

تم تعريف مدخل ROM الرسمي في `manifests/evolutionx-17.env.example` وفي `reports/evolutionx17_source_discovery.md`. لا يحفظ المستودع ROM أو الصور المستخرجة أو firmware أو مفاتيح AVB. بعد اكتمال التنزيل، تكون خطوات الاستلام حصراً كما يلي:

| بوابة | الدليل المطلوب | قرار الأهلية |
|---|---|---|
| I0 — سلامة ZIP | حجم متوقع، SHA-256 محلي و`unzip -t`. | الفشل يوقف التحليل. |
| I1 — جرد الصور | أسماء وأحجام وبصمات `boot` و`vendor_boot` و`dtbo` و`vendor_dlkm` و`system_dlkm` إن وجدت. | لا تغليف قبل اكتمالها. |
| I2 — الهوية | fingerprint وbuild ID وتاريخ البناء وAVB من البناء نفسه. | يملأ manifest خارج Git. |
| I3 — ABI/DT | إصدار kernel، vermagic، قوائم modules، overlay وDTB/DTBO. | لا يُعتمد أي تطابق اسمي بدلاً من ABI. |
| I4 — الجهاز | إثبات recovery والإقلاع والسجل والاسترداد من POCO F5 حقيقي. | وحده يسمح بتحديث حالة قبول الجهاز. |

## قرار التكامل الحالي

**لا توافق ثنائي مثبت بين Evolution X 17 المرجعي 5.10.256 والنواة العامة 6.18.32.** النواة 6.18 تبقى نواة بحث/porting عامة صالحة للبناء الثابت، بينما يحتاج هدف Evolution X إما نقل تعريفات المورّد ومصادرها إلى 6.18 مع KMI/DT/firmware متطابقة، أو بديل upstream موثق لكل مسار عتادي حرج. لن يتم تضمين وحدات المرجع 5.10 في أي مخرج 6.18.

توجد فجوة اتساق صغيرة يجب حلها في مرحلة إعداد النكهة: نموذج manifest يحمل `ROM_FLAVOR=evolutionx-17`، في حين أن قائمة قبول `--flavor` في نص البناء الحالي تقتصر على `aosp|xiaomi`. تعديل القبول إلى `evolutionx-17` هو تعديل metadata فقط، وسيتم تنفيذه مع اختبار بناء مستقل بعد اكتمال بوابات الاستلام والتحليل، من دون أن يرفع الحظر عن التغليف.

## المراجع

[1]: https://evolution-x.org/devices/marble "صفحة Evolution X الرسمية لجهاز marble"
[2]: https://github.com/Evolution-X-Devices/device_xiaomi_sm8450-common/blob/main/BoardConfigCommon.mk "Evolution X sm8450-common BoardConfigCommon.mk"
[3]: https://github.com/Evolution-X-Devices/device_xiaomi_marble "Evolution X marble device tree"
[4]: https://github.com/Evolution-X-Devices/kernel_xiaomi_sm8450 "Evolution X Xiaomi SM8450 kernel source"
[5]: https://github.com/Evolution-X-Devices/device_xiaomi_marble-kernel "Evolution X marble kernel artefact tree"
