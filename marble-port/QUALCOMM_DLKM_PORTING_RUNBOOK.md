# دليل نقل Qualcomm وDLKM إلى marble 6.18

**النطاق:** POCO F5 / `marble` (SM7475) مع Evolution X 17 كمرجع artefacts فقط. هذا الدليل يشرح كيف تُنقل المصادر ووحدات vendor إلى Android Common Kernel 6.18؛ لا يجيز نسخ وحدات `.ko` أو DTB/DTBO أو firmware binary من ROM 5.10، ولا ينتج صورة قابلة للتفليش.

> **قاعدة لا تقبل الاستثناء:** وحدة بنيت لـ`5.10.256-gki-ge8fcf2558711` ليست مدخلاً صالحاً لنواة `6.18.32`. يجب بناء كل وحدة من مصدرها مجدداً مقابل `vmlinux` و`Module.symvers` وKMI الخاصين ببناء 6.18 نفسه. وجود اسم وحدة متماثل لا يثبت توافقاً.

إن Android GKI لا يَعِد باستقرار KMI بين فروع LTS أو إصدارات Android المختلفة؛ بل يقتصر الاستقرار على الفرع ونسخة Android نفسيهما وعلى configuration وtoolchain المقيدين. كما أن `CONFIG_MODVERSIONS` يمنع تحميل وحدة ذات CRC غير متطابق وقت التشغيل.[1] [2]

## 1. قفل عقد الإدخال قبل كتابة أي patch

أنشئ فرعاً مستقلاً، مثلاً `marble-6.18-port/<subsystem>`، ولا تخلط النقل مع تعديل عام في ACK. سجّل المرجعين بصيغة قابلة لإعادة الإنتاج: مصدر Qualcomm/Xiaomi 5.10 الذي أنتج وحدات Evolution X، والالتزام `android17-6.18-lts` الذي ستستهدفه. لا تستخدم manifests من إصدارات مختلفة أو blobs من ROM آخر.

| ملف العمل المطلوب | مصدر البيانات | حقول إلزامية | شرط القبول |
|---|---|---|---|
| `module-contract.tsv` | `vendor_dlkm` وfragment `dlkm` في `vendor_boot` | module، init-stage، `modules.load`، depends، vermagic، firmware، DT compatible، Kconfig، source path | كل وحدة من القائمتين مصنفة إلى **upstream / port / لا حاجة**. |
| `dt-contract.tsv` | DTB وDTBO الرسميان وDTS 6.18 | node، compatible، reg/interrupts/clocks/resets/icc، driver، selector | لا يوجد node مطلوب بلا driver أو binding. |
| `firmware-contract.tsv` | `vendor.img` فقط | path، SHA-256، driver requester، مرحلة التحميل، license | كل firmware مطلوب له driver 6.18 وموقع mount صحيح. |
| `kmi-contract.tsv` | مخرج 6.18 | symbol، namespace، exporter، consumers، CRC، justification | لا توجد وحدة vendor تعتمد رمزاً غير معتمد في KMI. |

يجب أن يبيّن العقد الحالي فجوة أساسية مثبتة: لدى ROM المرجعي 390 اسم وحدة فريد، منها 337 في ramdisk `dlkm` و97 في قائمة الإقلاع الأولية، في حين لا ينتج مرشح 6.18 العام إلا 104 وحدات. لذلك يبدأ النقل بوحدات الإقلاع المبكر، لا بالكاميرا أو الواجهة الرسومية.[3]

## 2. ترتيب نقل المسارات: الطبقات قبل المزايا

لا تُنقل 390 وحدة دفعة واحدة. اعمل في topic branch لكل طبقة مع سلسلة patches قابلة للمراجعة وbisect. يُحدد نجاح طبقةٍ ما بتحميل وحداتها من مصدر 6.18 وبسجل جهاز، لا بمجرد اجتياز `make`.

| الموجة | المسارات/العائلات المرجعية | العمل المطلوب في 6.18 | بوابة توقف |
|---|---|---|---|
| P0: منصة مبكرة | SPMI، PMIC، RPMh، regulator، pinctrl، GCC، interconnect/QNoC، SCM، SMEM، GLINK، QRTR، IOMMU، GIC | استبدل بما يوجد في ACK أولاً. انقل كود Qualcomm فقط إذا كان hardware-specific وغير موجود upstream؛ طابق clocks/regulators/interconnects مع DTS. | لا يمر أي driver إلى P1 إذا لم تنجح probe/defer ordering أو حصل SError/panic. |
| P1: التخزين والإقلاع | UFS/QMP PHY، `ufs_qcom`، crypto، nvmem، RTC، watchdog، reboot reason، memory dump | انقل driver+binding+DTS+Kconfig معاً. ثبّت UFS قبل `vendor_dlkm` لأن الأقسام تعتمد عليه. | ثلاثة إقلاعات واختبارات read/write بلا timeout أو I/O error. |
| P2: USB والطاقة الأساسية | DWC3، QMP USB PHY، role switch، charger/type-C إن وجد | راجع API التغييرات في extcon/type-C/PHY/runtime-PM بدلاً من cherry-pick أعمى. | ADB، نقل ملف، شحن، وOTG عند توفر العتاد. |
| P3: الاتصال والـDSP | CNSS/WLAN/BT، IPA، MHI، PIL/remoteproc، ADSP/CDSP، GPR/SPF | ابدأ بتبعيات IPC وremoteproc وfirmware loading؛ لا تبدأ بـWLAN UI. | لا modem/SSR loop، firmware authentic loading وسجل subsystem سليم. |
| P4: الإدخال والصوت | Goodix/FPC، codecs WCD/WSA، SoundWire، ASoC/LPASS | اعزل كل controller، ولا تُدخل ABI خاصاً داخل `struct` ACK إن أمكن. | touch events وصوت capture/playback بلا reset. |
| P5: العرض والـGPU | SDE/DRM، DSI/DP، KGSL أو البديل المعتمد، panel | port كبير مستقل؛ راجع dma-buf, sync fence, IOMMU, PM وDRM atomic APIs. | لوحة مستقرة ثم suspend/resume ثم GPU fault=0. |
| P6: الكاميرا والفيديو | CAMSS/CCI/CSID/CSIPHY/ICP/VFE/SFE/VIDC | افصل capture pipeline عن proprietary userspace؛ راجع ioctl/UAPI وmedia-controller وIOMMU. | camera HAL، preview/capture، video encode/decode وسجل ISP سليم. |

### قاعدة اختيار المصدر

ابدأ دائماً بالترتيب التالي: **ACK 6.18 الموجود → driver upstream حديث → code من Qualcomm 5.10 مع patch-port محدود**. لا تنقل شجرة `drivers/*` كاملة من 5.10؛ ستدخل عندئذٍ APIs وtypes قديمة وتكسر KMI بدلاً من إصلاحها. لكل patch، اربط commit المصدر بملف `PORTING_NOTES.md` واكتب سبب عدم صلاحية البديل upstream.

أثناء النقل، توقع تغييرات API في IRQ وGPIO descriptor وDMA/IOMMU وdma-buf وDRM وV4L2 وremoteproc وdev_pm_ops وclk/regulator و`proc_ops` وnetdev. الحل ليس compat header واسعاً؛ الحل هو تحويل كل caller إلى API 6.18 الدلالي ومراجعة ownership وlifetime وerror paths وruntime PM.

## 3. بناء KMI خاص بـ6.18 قبل بناء DLKM

أنشئ **baseline جديداً لـ6.18**؛ لا تحاول مقارنة ABI 5.10 بصفته baseline مقبولاً. تمثل قوائم symbols حدود KMI فقط، ويجب أن تستخدم وحدات vendor رموز KMI المعتمدة؛ يرفض GKI تحميل modules التي تحتاج رموزاً غير مسموح بها.[1] [2]

1. ابنِ ACK 6.18 باستخدام بيئة Android hermetic وClang المطابق لفرع ACK، لا Clang النظام عند اعتماد نتائج KMI. إبقاء Clang 18 المحلي مناسباً للتحقق التطويري، لكنه ليس دليلاً نهائياً على ABI الإنتاجي.
2. فعّل `CONFIG_MODVERSIONS=y` واحتفظ بـ`vmlinux` و`Module.symvers` و`.config` و`System.map` وrelease الكامل لكل build ID.
3. شغّل هدف ABI الرسمي/المكافئ الذي ينتج `.stg` وsymbol list؛ يوضح AOSP أن ABI tooling يقارن `vmlinux` ووحدات GKI عبر تمثيل STG وقوائم الرموز.[2]
4. أنشئ قائمة symbols مخصصة لـmarble، وليكن مثلاً `gki/aarch64/symbols/marble` أو المسار الذي يفرضه فرع 6.18. أضف رمزاً فقط بعد إثبات أن module 6.18 يحتاجه، وأنه `EXPORT_SYMBOL_GPL` أو export مسموح، وأن التوسعة لا تكسر ABI الموجود.
5. استخدم `KBUILD_SYMTYPES=1` أو المعادل في نظام بناء الفرع عند ظهور CRC mismatch. قارن ملف `.symtypes` للـexporter والـconsumer، لا تضع `EXPORT_SYMBOL` عشوائياً.
6. افشل CI عند: undefined symbols في modpost، namespace import مفقود، CRC مختلف، أو رمز مطلوب خارج symbol list، أو ABI diff غير مبرر.

> لا تُعالج CRC mismatch بتعطيل `CONFIG_MODVERSIONS` أو بقص `vermagic`. هذا يحوّل حماية تحميل واضحة إلى احتمال crash صعب التشخيص. يشرح AOSP أن mismatch في `module_layout` أو رموز مماثلة يجب أن يفشل التحميل عمداً.[2]

## 4. تحويل كل وحدة Qualcomm إلى وحدة 6.18 قابلة للبناء

لكل module في `module-contract.tsv` نفذ الحلقة التالية، ولا تبدأ الحزمة التالية إلا بعد إغلاق جميع عناصر الحالية:

```text
1. حدّد source driver وKconfig وMakefile وDTS bindings والـfirmware المطلوبة.
2. قرر: upstream built-in / upstream module / vendor module جديد / غير مطلوب.
3. انقل patch صغيراً واحداً، ثم ابنِ kernel + M=<driver-dir> مع W=1 وLLVM.
4. أصلح modpost وsparse وC=1 حسب الإمكان؛ لا تخفِ التحذير بإضافة -Wno عامة.
5. راجع imports/exports وModule.symvers وCRC وKMI symbol list.
6. ابنِ .ko من O=<6.18 out> ذاته، ثم سجّل modinfo: vermagic، depends، firmware، signer.
7. طابق DTS node وresources؛ اختبر probe/defer/remove وruntime suspend على الجهاز.
8. أضف الوحدة إلى manifest وmodules.load فقط عند إثبات الحاجة ونجاح الخطوات السابقة.
```

### نقاط تقنية يجب تدقيقها في كل وحدة

| محور | الفحص التقني |
|---|---|
| Kconfig | `depends on` الصحيح، عدم إجبار framework عام vendor-only، وعدم duplicate symbol مع ACK. |
| Makefile | المخرج `.ko` يعاد بناؤه من `O=` نفسه، ولا توجد objects أو `Module.symvers` من 5.10. |
| KMI | `modpost` نظيف، namespaces مستوردة، CRC متسق، وكل export متطلب مدرج ومراجع. |
| Device Tree | كل clock/reset/regulator/ICC/IRQ/GPIO/IOMMU stream ID صالح لنسخة driver 6.18؛ لا تنقل phandle أو compatible بلا binding متوافق. |
| firmware | يطلبه driver بالاسم الصحيح بعد mount؛ SHA محفوظ خارج Git؛ لا يُعدّل binary firmware. |
| PM/error paths | `devm_*` وruntime-PM وwake IRQ وSSR/defer/remove تعمل؛ لا leaks ولا use-after-free. |
| userspace | أي UAPI/IOCTL أو sysfs/debugfs إضافي موثق ومختبر ضد HAL، ولا يُكسر ABI المستخدم. |

## 5. إعادة إنتاج DLKM: بناء جديد لا نسخ binary

تقسم AOSP الوحدات إلى GKI عامة ووحدات vendor hardware-specific. توضع modules المطلوبة في الإقلاع المبكر في `vendor_boot`، بينما يمكن وضع غير المبكرة في `vendor`/`vendor_dlkm`.[4] لا تستخدم `vendor_dlkm.img` المرجعي كقالب modules؛ استخدمه فقط لاستخراج ترتيب الاعتماد والأسماء والـfirmware والـload policy.

### 5.1 مرحلة staging

1. أنشئ `staging/vendor_dlkm/lib/modules/<release>/` و`staging/vendor_ramdisk_dlkm/lib/modules/<release>/` من مخرجات 6.18 فقط.
2. استخدم قوائم مرجعية مقتصرة على **modules التي أنجز porting لها**. لا تنسخ قائمة `modules.load` ذات 5.10 كما هي؛ أعد توليدها من dependency graph 6.18.
3. شغّل `depmod -b <staging-root> <release>` باستخدام `System.map` ومخرجات build نفسها لتوليد `modules.dep`, `modules.alias`, `modules.softdep`, و`modules.symbols`.
4. نفّذ فحصاً آلياً: كل اسم في `modules.load` موجود، وكل dependency في `modules.dep` موجود، ولا تشير قوائم staging إلى release 5.10، وكل `.ko` يحمل `vermagic` مساويًا تماماً لـ`6.18.32-…` المتوقع.
5. افصل وحدات الإقلاع المبكر بأصغر مجموعة ممكنة: storage/UFS، PMIC/clocks/ICC، IOMMU/SMEM، ثم ما يلزم لmount أو firmware المبكر. اترك WLAN/GPU/camera في `vendor_dlkm` ما لم يثبت أنها مطلوبة قبل mount.

### 5.2 vendor_boot header v4

`vendor_boot` في Android header v4 يضم vendor ramdisk table ويعرّف fragments من الأنواع `PLATFORM` و`RECOVERY` و`DLKM`؛ يسمح الجدول للـbootloader باختيار fragments ويحمّل DLKM مبكراً عند الحاجة.[5]

لـmarble، طابق الحقول الرسمية المستخرجة، لا تخمّنها:

| إعداد | قاعدة التنفيذ |
|---|---|
| `BOARD_BOOT_HEADER_VERSION` | يبقى `4` ما دام ROM المرجعي يستخدم header v4. |
| ضغط vendor ramdisk | LZ4 عندما تكون صورة GKI تستعمل ramdisk LZ4. |
| fragment type | `DLKM` لمجموعة modules المبكرة، وليس `PLATFORM` بالخطأ. |
| `board_id[0..15]` | انسخ selector من جدول ROM بعد توثيقه؛ مدخل marble المرجعي يشير إلى MSM ID `0x24f/0x10000`. لا تضع صفراً عاماً بلا اختبار. |
| `KERNEL_MODULE_DIRS` | يشير إلى staging directories لوحدات **6.18** فقط. |
| fstab/first-stage | يبقى في vendor ramdisk وفق عقد ROM، ويجب أن يركب `vendor_dlkm` قبل محاولة تحميل modules منه. |
| bootconfig | يُحفظ كما يقتضيه ROM؛ لا تحذف keys أو تغير load addresses. |

يصف AOSP المتغيرات اللازمة صراحةً: `BOARD_VENDOR_RAMDISK_FRAGMENTS`، و`BOARD_VENDOR_RAMDISK_FRAGMENT.<name>.KERNEL_MODULE_DIRS`، و`MKBOOTIMG_ARGS` التي تتضمن `--board_id*` و`--ramdisk_type`.[5]

### 5.3 vendor_dlkm image والسياسة الأمنية

ابنِ `vendor_dlkm.img` من staging 6.18 مع file contexts وfs_config وfstab وإعدادات init الخاصة بالروم. افحص سياسة SELinux ونقاط mount ومسارات `/vendor_dlkm/lib/modules` قبل اختبار التحميل. افحص `modinfo -F signer` و`sig_id` و`sig_key` في ROM المرجعي؛ إن كانت module signing enforced فأنشئ سلسلة توقيع جديدة صالحة وسياسة ثقة متطابقة أو استخدم المسار الرسمي للمشروع. لا تعطّل التحقق ولا تضع مفتاحاً خاصاً في Git.

## 6. Device Tree وDTBO: جزء من port وليس artefact منفصلاً

لا يكفي أن تنتج `marble-sm7475-pm8008-overlay.dtbo` الخام. يحتوي ROM المرجعي على حاوية `dt_table` بـ14 مدخلاً، بينما المنفذ الحالي FDT واحد؛ كما أن هناك 82 compatible strings مرجعية غير ظاهرة في DTB 6.18. لذلك:

1. انقل كل node على شكل **binding + driver + DTS** متزامنة. لا تضف compatible بلا driver، ولا driver بلا resources في DTS.
2. ابنِ matrix من 82 فجوة: camera، display، audio/DSP، ADSP، ثم صنف كل واحدة `not needed / upstream / ported / blocked`.
3. أنشئ `dt_table` عبر أدوات AOSP المناسبة من overlays 6.18، وبنفس entry order و`id/rev/custom` selector الذي يحتاجه bootloader؛ لا تمرر FDT واحداً مكان dtbo.img.
4. فك الحاوية الناتجة وافحص header وentry count وboard selectors، ثم فك كل entry بـDTC وقارن nodes/properties المهمة مع المرجع، لا hashes فقط.
5. اجعل DTC warnings بوابة مراجعة: أصلح فقط التحذير الذي تملك binding ودليل board له؛ لا تعدّل blob أو vendor DTS القديم لتصفير عدد تحذيرات.

## 7. بوابات الاختبار قبل أي تفليش

| بوابة | دليل التنفيذ | معيار النجاح | يمنع الانتقال إذا |
|---|---|---|---|
| S0: source | سلسلة commits صغيرة + license/SOB + mapping source | لا blobs ولا `.ko` 5.10 في الشجرة | patch واحد يجمع عدة subsystems أو يغير ABI بلا تحليل. |
| S1: build/KMI | build hermetic، W=1، modpost، ABI/STG، symbol list، `Module.symvers` | لا undefined/CRC/namespace/KMI failure | يوجد رمز غير مصرح أو ABI diff غير مبرر. |
| S2: staging | depmod و`modules.load` والتحقق من vermagic | كل `.ko` 6.18 واعتماداته مغلقة | أي ملف 5.10 أو dependency مفقود. |
| S3: image inspection | فك `vendor_boot`/`vendor_dlkm` الناتجين قراءة فقط | header v4، LZ4، fragment DLKM، board IDs، DTB/DTBO صحيحة | اختلاف size/table/load addresses/selector من العقد. |
| R1: recovery | استرداد ROM الأصلي مثبت على جهاز مفتوح bootloader | ROM الأصلي يقلع بعد اختبار الاستعادة | لا توجد خطة rollback أو السجل ناقص. |
| B1: early boot | أول إقلاع في مسار قابل للاسترداد، pstore/serial/adb | UFS وmount وinit وno panic | CRC/module load failure أو storage error أو SSR loop. |
| B2: stability | ثلاث دورات إقلاع/إيقاف، ثم P0→P6 تدريجياً | logs كاملة وpanic=0 لكل موجة | أي reboot غير مفسر يعيدك للموجة السابقة. |

استخدم نكهة `diagnostic` في B1/B2 فقط، لأنها تحتوي BTF وdynamic-debug وftrace وpstore. احفظ مع كل سجل: commit، `build-metadata.txt`، SHA-256 لـImage وvendor_boot/vendor_dlkm/dtbo، build fingerprint، serial، مستوى البطارية ودرجة الحرارة. لا تنتقل إلى display/camera قبل أن تصبح UFS والطاقة وUSB مستقرة.

## 8. أول backlog تنفيذي مقترح

1. **إنشاء `module-contract.tsv` آلياً** من 390 module و97 first-stage entries وربطها بمصدر Qualcomm 5.10 وKconfig وDTS وfirmware.
2. **إنشاء baseline KMI 6.18 hermetic** وحفظ `.stg` و`Module.symvers` وقائمة symbols الخاصة بـmarble في CI.
3. **P0/P1 فقط:** SPMI/PMIC/RPMh/clock/ICC/SMEM/IOMMU/UFS/QMP/reboot/watchdog. لا تبدأ GPU أو camera.
4. **بناء fragment DLKM 6.18 مصغّر** مع `depmod` وheader-v4 table وفحص ثابت، لكن دون توقيع/تفليش حتى R1.
5. **اختبار R1 ثم B1** على جهاز فعلي مع مسار استعادة موثق؛ ابدأ بالتخزين والـpstore قبل WLAN أو الصوت.
6. أعد فتح P2–P6 فقط بعد إغلاق بوابة B1 لكل dependency wave.

## المراجع

[1]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"
[2]: https://source.android.com/docs/core/architecture/kernel/abi-monitor "AOSP — Android kernel ABI monitoring"
[3]: ./EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md "تحليل artefacts Evolution X 17 ومرشح marble 6.18"
[4]: https://source.android.com/docs/core/architecture/kernel/modules "AOSP — Kernel modules overview"
[5]: https://source.android.com/docs/core/architecture/partitions/vendor-boot-partitions "AOSP — Vendor boot partitions"
