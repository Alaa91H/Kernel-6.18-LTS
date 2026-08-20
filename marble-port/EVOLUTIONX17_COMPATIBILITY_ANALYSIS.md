# تحليل توافق Evolution X 17 مع marble GKI 6.18

**القرار الحالي:** لا يثبت ROM Evolution X 17 الحالي أي توافق ثنائي أو KMI مع مرشح Android Common Kernel 6.18.32. تبقى نواة 6.18 قابلة للبناء والتحليل الساكن، لكن **التغليف والتفليش محظوران** إلى أن تُنقل مسارات vendor المطلوبة إلى 6.18 وتُثبت على جهاز POCO F5 فعلي.

> لا يعني نجاح بناء `Image` أو وجود أربعة أسماء وحدات متطابقة أن نواة 6.18 صالحة لاستبدال kernel 5.10 في ROM. التحقق يعتمد على ABI وواجهة KMI وDevice Tree وramdisk وfirmware معاً، لا على الاسم أو الحجم.

## مقارنة ABI الفعلية

استخرجت قيم الإصدار من `boot.img` و`vendor_dlkm.img` الرسميين، ثم قارنت أسماء الوحدات مع مخرج `marble-aosp-diagnostic-none` من الالتزام المحلي. المرجع هو ROM `EvolutionX-17.0-20260812-marble-12.1-Official.zip` الموثق في جرد artefacts.[1]

| بند | Evolution X 17 الرسمي | مرشح marble 6.18 | الاستنتاج |
|---|---|---|---|
| kernel release | `5.10.256-gki-ge8fcf2558711` | `6.18.32-4k-marble-aosp-diagnostic-g5fa05535c108` | اختلاف رئيسي يمنع إعادة استخدام وحدات binary. |
| compiler المعلن داخل Image | Android Clang 21.0.0 / r563880c | Ubuntu Clang 18.1.3 | لا يوجد تطابق toolchain أو release. |
| vermagic vendor | `5.10.256-gki-ge8fcf2558711 SMP preempt mod_unload modversions aarch64` | `6.18.32-4k-marble-aosp-diagnostic-g5fa05535c108 SMP preempt mod_unload modversions aarch64` للوحدات المتداخلة اسمياً | `modversions` مفعّل، ولا توافق ABI. |
| وحدات `vendor_dlkm` الفريدة | 390 | 104 في البناء المرشح | ليس استبدالاً قابلاً للتحميل. |
| وحدات `dlkm` في vendor ramdisk | 337 | لا ramdisk DLKM 6.18 معتمد | بوابة early boot غير مستوفاة. |
| قائمة التحميل الأولية | 97 وحدة | 97 اسمًا غير مبني في المرشح | إقلاع vendor غير قابل للإثبات. |
| قائمة تحميل vendor DLKM | 289 وحدة | 285 اسمًا غير مبني | تحتاج porting أو بدائل مبنية من مصدر 6.18. |

يوضح بروتوكول Android OTA أن `vendor_boot` يمكن أن يحمل ramdisk fragments وأن payload يصف الأقسام والتجزئات والـhashes منفصلة؛ لذلك لا يصح وضع `Image` بديل في boot من دون بناء vendor ramdisk وDTB وAVB من عقد ROM نفسه.[2]

### أسماء الوحدات المتداخلة

ظهرت أربعة أسماء فقط في التقاطع الاسمي: `asix.ko` و`ax88179_178a.ko` و`zram.ko` و`zsmalloc.ko`. هذه نتيجة جرد أسماء لا أكثر. يحمل كل منها في 6.18 vermagic مختلفاً كلياً، ولذلك لا يُنسخ أي ملف `.ko` من ROM إلى النواة المرشحة.

| عائلة فجوة الاسم في reference | عدد الوحدات غير المبنية بالاسم | دلالة porting |
|---|---:|---|
| Qualcomm/vendor العام | 126 | IPC، DSP، WLAN، PM، modem، vendor hooks. |
| power/clock/interconnect | 25 | RPMh وclocks وpinctrl وregulator وinterconnect. |
| storage/USB | 24 | UFS/PHY وDWC3 وUSB functions. |
| touch/biometrics | 11 | Goodix/FPC/Xiaomi/touch controllers. |
| display/GPU | 9 | KGSL/SDE/display clocks/panel/HDMI. |
| camera | 3 | camera integration الخاصة بالمورّد. |
| أخرى | 188 | تشمل صوتاً وشبكات وتشخيصاً وميزات board-specific. |

هذه الأرقام تمثل **حداً أدنى** للفجوة؛ إذ لا تقيس الرموز أو الواجهات التي تغيرت أسماؤها أو انتقلت إلى built-in. لا يسمح التقرير بتفعيل Kconfig عشوائياً؛ فعدد كبير من خيارات Qualcomm المرجعية لا وجود له في ACK 6.18، ويستلزم source port لا fragment تهيئة فقط.

## Device Tree وDTBO

يحمل `vendor_boot.img` في ROM DTB فعلياً بحجم FDT منطقي `481,891` بايت ضمن منطقة DTB محجوزة حجمها `5,745,935` بايت. المخرج المحلي `ukee.dtb` FDT منطقي حجمه `379,047` بايت. اختلاف البصمة والحجم متوقع، ولا يعتبر بمفرده فشلاً، لكنه يمنع قبول التطابق دون تحليل محتوى.

| مقياس DTB الأساسي | Evolution X 17 | marble 6.18 | القراءة |
|---|---:|---:|---|
| compatible strings فريدة | 306 | 228 | الأساس المحلي يغطي جزءاً كبيراً فقط. |
| compatible strings مشتركة | 224 | — | تداخل بنيوي، وليس توافق driver. |
| strings مرجعية لا تظهر محلياً | 82 | — | فجوات حقيقية مرشحة للفحص. |
| DTBO الرسمي | dt_table، 14 مدخلاً، حجم منطقي 4,299,397 بايت | overlay FDT خام واحد، 68,799 بايت | لا يمكن استبدال الحاوية الرسمية بالـoverlay الخام. |
| مدخل DTBO ذو إشارات `marble/ukee` | `entry-03`، MSM ID `0x24f/0x10000` | لا يحتوي عقد التغليف الحالية selector مكافئاً | يلزم بناء حاوية DTBO مضبوطة بعد اختبار selector. |

تتركز الـ82 compatible المرجعية غير الظاهرة في مرشح 6.18 حول camera (`cam-*`, `csiphy`, `vfe`, `sfe`)، display (`dsi`, `dp`, `sde`)، audio/DSP (`lpass`, `msm-*`, `wcd/wsa`, `spf/gpr`) وadsp. وهي تتسق مع فشل توافر DLKM المقابل، وتمنع اعتبار DTB/DTBO الحاليين مكافئين وظيفياً.

> **التحذيرات:** تفكيك DTB/DTBO الرسمي باستخدام DTC يُظهر تحذيرات متعلقة بعقد vendor legacy، ولا يحولها هذا التدقيق إلى أخطاء في المخرج المحلي. سيظل تصنيف تحذيرات البناء في `DT_WARNING_CLASSIFICATION.md` مستقلاً عن artefact ROM؛ لا تُعدّل blobs ROM لتسكيت التحذيرات.

## KMI والسياسات المحجوبة

لا يحتوي ROM الوارد على قائمة ABI/KMI نصية تصلح كمرجع 6.18. لا توجد `system_dlkm` في manifest هذا البناء، بينما توجد `vendor_dlkm` وfragment `dlkm` في `vendor_boot`. لذلك تكون الحالة كما يلي:

| بوابة | الحالة | الشرط للانتقال |
|---|---|---|
| KMI baseline | **غير متاح** | بناء قائمة ABI 6.18 خاصة بالمشروع أو مصدر KMI معتمد. |
| vendor ramdisk | **غير متوافق** | بناء fragment 6.18 بمسارات وحدات مبنية ومحمّلة ومختبرة. |
| vendor DLKM | **غير متوافق** | porting لمصادر الوحدات أو بدائل upstream متطابقة وظيفياً. |
| DTB/DTBO | **غير مكافئ** | اختيار board صحيح، حاوية DTBO موثقة ومقارنة nodes/properties لا مجرد strings. |
| AVB/boot packaging | **محظور** | سياسة مفاتيح ومؤشر rollback وإثبات device acceptance. |
| اختبار الجهاز | **غير منفذ** | POCO F5 متصل، recovery path، logs واسترداد مثبتة. |

## مخرجات قابلة لإعادة الإنتاج

يُشغل التدقيق من مخرجات موجودة فقط ولا يلمس الصور أو الوحدات:

```bash
./tools/audit_evolutionx17_rom_abi.sh \
  /path/to/evolutionx17-marble-artefacts \
  out/marble-aosp-diagnostic-none \
  marble-port/reports/evolutionx17_rom_abi_audit
```

وتوجد النتائج المفصلة في `marble-port/reports/evolutionx17_rom_abi_audit/` و`marble-port/reports/evolutionx17_dtbo_comparison/`. لا تحفظ صور ROM أو firmware أو وحدات binary في Git.

## المراجع

[1]: https://evolution-x.org/devices/marble "Evolution X — marble device page"
[2]: https://android.googlesource.com/platform/system/update_engine/+/HEAD/update_metadata.proto "AOSP update_engine OTA payload format"
