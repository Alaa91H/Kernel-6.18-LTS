# تحقق بناء marble — AOSP diagnostic

## النتيجة

نجح بناء نكهة `aosp` التشخيصية من شجرة Git نظيفة عند الالتزام `5fa05535c1085fd078b81593d17c476b230189a1`. وضع البناء هو `root_mode=none` و`package=none`، ولذلك لا يمثل الناتج حزمة تفليش أو ادعاء توافق مع ROM محدد.

| بند التحقق | النتيجة |
|---|---|
| Image ARM64 | ناجح؛ الحجم `45,885,952` بايت؛ SHA-256 `ecfbb59f8b7d045e92e3b7858032ab245f94dd74be73985011b57155f5d72509`. |
| الوحدات | ناجح؛ `104` ملفات `.ko`. |
| ukee.dtb | ناجح؛ SHA-256 `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8`. |
| marble DTBO | ناجح؛ SHA-256 `8644bb0525008aa3ffe94394c17d6c1b95a1155b86ec73986feeeb4f93cd6ce9`. |
| BTF في `vmlinux` | ناجح؛ قطاعات `.BTF` و`.BTF_ids` موجودة، واستخرج `pahole -F btf -C task_struct` تعريفاً صالحاً. |
| تهيئة الأساس | نجحت؛ `11` رمزاً لمسارات marble الأساسية. |
| تهيئة التشخيص | نجحت؛ `12` رمزاً لـBTF وdynamic-debug وftrace وpstore. |
| DTB/DTBO/الدمج | ناجح؛ جميع القطع قابلة للقراءة والـoverlay قابل للدمج. |

## تحقق نكهة Xiaomi release

نجح أيضاً بناء نكهة `xiaomi` بوضع `release` من شجرة Git نظيفة عند الالتزام `b5c3866ff10651d74a8525729e83d969d1904c69`. هذه النكهة تثبت عمل مسار اختيار Xiaomi وأتمتة المخرجات، لكنها **ليست** إثبات توافق مع MIUI/HyperOS أو أي ROM Xiaomi لأن صور vendor والـfirmware وABI المتطابقة لم تُدمج بعد.

| بند التحقق | النتيجة |
|---|---|
| Image ARM64 | ناجح؛ الحجم `36,489,728` بايت؛ SHA-256 `4fc8442447ba3766ada9b43810c9197547dab1b4cc54eea05298b0624a058257`. |
| الوحدات | ناجح؛ `104` ملفات `.ko`. |
| ukee.dtb وmarble DTBO | ناجحان؛ البصمتان مطابقتان لمخرجات النكهة التشخيصية لأن Device Tree لا يتغير باختيار وسم ROM. |
| طبقة root | `none`؛ لا توجد طبقة KernelSU Next أو APatch مدمجة. |
| BTF/التشخيص | هذه نكهة release؛ لا تفعل ملف التشخيص ولا تستخدمها كبديل عن تحقق BTF التشخيصي أعلاه. |

## تحقق نكهة Evolution X 17 التشخيصية

نجح بناء نكهة `evolutionx-17` من شجرة Git نظيفة عند الالتزام `292a8b56c6f0264741ba551a58bdf5c614b323c7`، باستخدام `PAHOLE=/home/ubuntu/tools/dwarves-install/bin/pahole` بالإصدار `v1.31`. النكهة تغير وسم المنشأ فقط؛ لا تستورد binaries من ROM ولا تنشئ `boot.img` أو `vendor_boot.img`.

| بند التحقق | النتيجة |
|---|---|
| Image ARM64 | ناجح؛ الحجم `45,885,952` بايت؛ SHA-256 `cb6646c0ceba72426fd04ee74a09a78fd71d9047832112deb93b9a6f4d6cfa9a`. |
| kernel release | `6.18.32-4k-g292a8b56c6f0`. |
| الوحدات | ناجح؛ `104` ملفات `.ko`. |
| ukee.dtb | ناجح؛ الحجم `379,047` بايت؛ SHA-256 `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8`. |
| marble DTBO | ناجح؛ الحجم `68,799` بايت؛ SHA-256 `8644bb0525008aa3ffe94394c17d6c1b95a1155b86ec73986feeeb4f93cd6ce9`. |
| BTF | ناجح؛ قبل `pahole -F btf` ملف `vmlinux`. |
| فحص config | ناجح؛ 11 رمز أساس و12 رمزاً تشخيصياً. |
| `package=none` و`root=none` | مفروضان؛ لم يُنتج أي artefact تفليش. |
| اختبارات حواجز الأمان | رفض `ksu-next` و`apatch` و`--package boot` صراحةً مع exit code `2`؛ السجل في `reports/evolutionx17_safety_guard_tests.txt`. |

> لا يفتح هذا النجاح بوابة التغليف: ROM Evolution X 17 المستخرج يستخدم kernel `5.10.256-gki` ووحدات `vendor_dlkm` و`vendor_boot` غير المتوافقة ABI مع 6.18. تراجع [`EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md`](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md) قبل أي خطوة تخص صورة إقلاع.

## إعادة التحقق بعد تفعيل P0 upstream

أضيفت طبقة P0 ضيقة ومثبتة بالعقد الموجودة في `cape.dtsi`: `QCOM_IPCC` و`HWSPINLOCK_QCOM` و`QCOM_SMEM` و`QCOM_SMP2P`. بُنيت النكهات الثلاث من الالتزام النظيف `343b9da858dd`، وتحققت كل الرموز الأربعة في `.config` ومؤشرات الوحدات المضمنة. التغيير يبني أساس IPC/SMEM فقط؛ لا ينقل DLKM vendor أو يتجاوز حكم عدم توافق ABI مع Evolution X 17.

| النكهة | النتيجة | Image | الوحدات | BTF | SHA-256 للـImage |
|---|---|---:|---:|---|---|
| `aosp` / `diagnostic` | ناجح | 46,021,120 بايت | 104 | صالح عبر `pahole v1.31` | `60c8d77bfb7d16ac75c375f29c2d15ff8e237604dfa84ab79bf090ea1e5e8f0c` |
| `xiaomi` / `release` | ناجح | 36,559,360 بايت | 104 | غير مطلوب في release | `d6c1c60330b9dd1451ddb0b4d51ffe916c83bfed0fce2433e4bc2b952d9ffd23` |
| `evolutionx-17` / `diagnostic` | ناجح | 46,021,120 بايت | 104 | صالح عبر `pahole v1.31` | `bf0f6d639bb71e58b333cc97e627a2148f4a0af420c85136827580e82144d3c7` |

بلغت كل النكهات `6.18.32-4k-g343b9da858dd`، وبقي `root=none` و`package=none`. تضبط `tools/validate_marble_dt_build.sh` الآن سقف التحذيرات المراجع (`129/53/154/103` للبناء/DTB/DTBO/DTB المدمج) وترفض أي تراجع؛ القياس الفعلي بعد P0 هو `129/53/153/102`، أي لا تحذيرات جديدة.

> **قرار الجاهزية:** البناء وBTF وP0 static-success، لكن معيار «0 تحذير و0 خطأ» لم يتحقق: توجد 129 رسالة DTC في build محدد، و386 وحدة مرجعية من Evolution X 17 لا يمكن إعادة استخدامها. لا تُنتج صورة إقلاع ولا يُفعل DLKM أو تفليش حتى نقل bindings/drivers vendor المتبقية وإنشاء KMI baseline واختبار POCO F5 فعلياً.

## إعادة التحقق بعد موجة P1

أضيف `CONFIG_SPMI_MSM_PMIC_ARB=y` بعد إثبات أن عقدتي `spmi0_bus` و`spmi1_bus` في `cape.dtsi` تستعملان `qcom,spmi-pmic-arb` المطابق مباشرةً لجدول ACK 6.18. بُنيت النكهات الثلاث من الشجرة النظيفة عند الالتزام `85ee72eaa3b3`، وتأكدت كل نكهة من الرمز في `.config` ومن المسار المضمن `kernel/drivers/spmi/spmi-pmic-arb.ko` في `modules.builtin`. لا يثبت ذلك probe عتادياً؛ فاختبار PMIC وADC ما زال يتطلب POCO F5 حقيقياً.

| النكهة | Image SHA-256 | الوحدات | BTF | المصدر |
|---|---|---:|---|---|
| `aosp` / `diagnostic` | `4c5f8dd5c8c223a5478511d1fd1dcb3d5040194c58e6d56fa81b62b50f111c0f` | 104 | صالح عبر `pahole v1.31` | `85ee72eaa3b3` نظيف |
| `xiaomi` / `release` | `7779d62e5fca1b8cd6ef46dbf1e8c71f5c9b1f9e9fbcd2dbee2440850b6125f0` | 104 | غير مطلوب في release | `85ee72eaa3b3` نظيف |
| `evolutionx-17` / `diagnostic` | `bb9d43c0ecd10aaffd5e4710e44933489ea5ebbe5159741d142d1500a4111b80` | 104 | صالح عبر `pahole v1.31` | `85ee72eaa3b3` نظيف |

نجح فحص ABI/DLKM الثابت مجدداً: المرجع يحوي 390 وحدة فريدة، منها 386 غير مبنية بالاسم في المخرج، و97 فجوة تحميل مرحلة أولى، و285 فجوة تحميل vendor. بقي verdict الأداة صريحاً: وحدات Evolution X 17 ذات `5.10.256-gki` غير متوافقة ABI مع Image 6.18 ولا تُحمّل أو تُغلف.

## معالجة BTF

فشل بناء BTF أولاً مع `pahole v1.25` لأن الأداة بلغت حد متغيرات per-CPU البالغ `4096`، ثم فشل `resolve_btfids` في قراءة BTF الناتج. بُني `pahole v1.31` محلياً من مصدر مشروع [dwarves الرسمي][1]، وثبت اختبار مستقل قدرته على ترميز BTF وسيط النواة بحجم `6,969,029` بايت. يمرر `tools/build_marble_flavor.sh` الآن قيمة `PAHOLE` كمتغير Make صريح، وسجل البناء الناجح يستخدم `/home/ubuntu/tools/dwarves-install/bin/pahole` بالإصدار `v1.31`.

> لا يجوز تعطيل BTF في نكهة `diagnostic` لتجاوز عطل في سلسلة الأدوات. أي بيئة بناء بديلة يجب أن تعيد إثبات نجاح BTF وقابلية قراءته قبل اعتماد مخرجاتها.

## تحذيرات Device Tree

لا يزال البناء يسجل تحذيرات DTC معلومة ومصنفة، ولا تخفيها أداة التحقق. العدادات الحالية هي:

| نطاق التحذير | العدد |
|---|---:|
| بناء marble المحدد | 126 |
| فك ترميز `ukee.dtb` | 50 |
| فك ترميز DTBO منفرداً | 153 |
| فك ترميز DTB بعد دمج DTBO | 99 |

يحمل [`DT_WARNING_CLASSIFICATION.md`](DT_WARNING_CLASSIFICATION.md) سبب كل فئة وحدود الإصلاح الآمن. خفضت رقعة CoreSight أحادية المنفذ التحذيرات إلى `126/50/153/99`، وشُددت الميزانية في أداة التحقق بهذه القيم؛ لم يُنفذ أي تغيير دلالي لتصفير المتبقي من دون binding أو اختبار عتادي.

## حالة KMI والقبول

لا تضم الشجرة الحالية قائمة ABI/KMI مرجعية لـmarble أو ROM مستهدفاً. أصبح ROM Evolution X 17 الفعلي مجروداً الآن، ويثبت `EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md` اختلاف kernel `5.10.256-gki` ووحدات vendor عن مرشح 6.18؛ لكن لا يزال لا توجد قائمة KMI معتمدة يمكن أن تحول ذلك إلى قبول. يلزم نقل drivers والوحدات أو بدائل upstream، وبناء vendor ramdisk وDTBO ملائمين، ثم اختبار جهاز فعلي وسجل إقلاع ونتائج UFS/USB/الشاشة والاتصال قبل فتح بوابة `boot.img` أو التفليش.

[1]: https://github.com/acmel/dwarves "dwarves / pahole"

## إعادة التحقق بعد تصحيح عقود DTC

بُنيت النكهات الثلاث من الالتزام `09743b464` بعد تصحيح عقود GICv3/ITS وخرائط PCIe `interrupt-map` وسياقات QUP وUSB و`reserved-memory` في overlays. استخدمت النكهتان التشخيصيتان `PAHOLE=/home/ubuntu/tools/dwarves-install/bin/pahole`، ولم يُفعّل root أو تغليف صورة إقلاع في أي نكهة.

| النكهة | وضع التشخيص | Image | SHA-256 للـImage | الوحدات | BTF |
|---|---|---:|---|---:|---|
| `aosp` | `diagnostic` | 46,021,120 بايت | `56172142a3fb38fc3126552e91e8b27c595953399dc0c97dcb4151eee7389324` | 104 | موجود في `vmlinux` |
| `xiaomi` | `release` | 36,559,360 بايت | `6c65085be1c4c75c045813566411c93c3057e669aac4f343277ec71417e3f96f` | 104 | غير مفعّل في release كما هو متوقع |
| `evolutionx-17` | `diagnostic` | 46,021,120 بايت | `e2f154e54c999d8a385051b4f54f618028fc615af121ca0b9d089a21c424ee13` | 104 | موجود في `vmlinux` |

نجحت بوابة `tools/validate_marble_dt_build.sh` بالقيم الجديدة: **`87/36/128/85`** لتحذيرات سجل البناء وDTB الأساس وDTBO المفرد وDTB المدمج، على الترتيب. يمثل ذلك انخفاضاً قدره `39/14/25/14` عن خط الأساس `126/50/153/99` من دون تعطيل فحوص DTC.

> يبقى هذا تحققاً ثابتاً للبناء والبنية. لا يحوّل النجاح إلى اعتماد تفليش: تحذيرات ADC/SPSS وbindings vendor المتبقية، إلى جانب عدم توافق ABI المعروف مع Evolution X 17 ذي 5.10، تتطلب source vendor مناسباً واختبار POCO F5 فعلياً قبل أي `boot.img` أو DLKM أو تفليش.

## تحقق SPSS الساكن مع marble diagnostic

تحققت رقعة SPSS وGLINK المضافة في شجرة العمل الحالية ببناء marble تشخيصي نظيف، مع تفعيل الرمزين `CONFIG_QCOM_SPSS=y` و`CONFIG_RPMSG_QCOM_GLINK_SPSS=y` عبر fragment تحقق مؤقت خارج الملفات المتتبعة. لا يغير هذا الأسلوب `defconfig` أو إعداد marble الافتراضي، ولا يزيل `status = "disabled"` من عقدة SPSS. استُخدم `pahole v1.31` المحلي، ومُررت BTF و`BTFIDS` بنجاح.

| بند التحقق | النتيجة |
|---|---|
| Image ARM64 | ناجح؛ SHA-256 `8a853a3be16cb777749e067d4ed890cb86944c5ac2c15207100cd5ee0c68aa47`. |
| الوحدات | ناجح؛ `104` ملفات `.ko`. |
| `ukee.dtb` | ناجح؛ SHA-256 `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0`. |
| marble DTBO | ناجح؛ SHA-256 `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba`. |
| SPSS وGLINK | دخلا في `vmlinux` بعد الترجمة والربط مع الرمزين مفعّلين. |
| BTF | ناجح؛ ظهر تسلسل `BTF` ثم `BTFIDS` من دون تعطيل BTF. |
| بوابات Device Tree | ناجح؛ `87/36/128/85` للبناء/DTB الأساس/DTBO/DTB المدمج، أي مساوية للسقف المرجعي لا أعلى منه. |

تحتفظ عملية التحقق بتحذيرات DTC كما هي؛ منها تحذيرات `glink-edge` المنقولة مسبقاً. لا توجد في الرقعة أي تعديلات على ملفات DTS أو `reg` أو phandle أو unit-address، ولذلك لا تُنسب التحذيرات المعروفة إلى تغيير SPSS. السجلان الخامان هما `reports/spss_marble_full_build_2026-08-20.log` و`reports/dt_gate_spss_recheck_2026-08-20.log`.

> يثبت هذا القسم قابلية بناء الرقعة وتكاملها الساكن فقط. لا توجد firmware `spss.mdt` متحققة ولا KMI/vendor manifest ولا UART أو خطة استرداد منفذة على POCO F5؛ لذلك تبقى عقدة SPSS معطلة ولا يُنتج boot image أو أي artefact تفليش.

## بناء رأس فرع marble الحالي — AOSP diagnostic

أُجري بناء جديد قابل للإعادة من رأس فرع `marble-6.18-full-port` عند الالتزام `d69d5a5daa894488f203f5d59edc04dc15ef4bd1`. استُخدمت نكهة `aosp` مع `diagnostic` و`root=none` و`package=none`، وClang `18.1.3` وpahole `v1.31` المحلي. استُخدم مخرج منفصل هو `out/marble-aosp-diagnostic-d69d5`؛ لا يدخل هذا المخرج أو أي صورة ناتجة في Git.

| بند التحقق | النتيجة |
|---|---|
| Image ARM64 | ناجح؛ SHA-256 `70cf0ed8e514bcd70bfd00ec008f558afcf94af6eaac82d3cfdcf5f83e011921`. |
| الوحدات | ناجح؛ `104` ملفات `.ko`. |
| `ukee.dtb` | ناجح؛ SHA-256 `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0`. |
| marble DTBO | ناجح؛ SHA-256 `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba`. |
| BTF | ناجح؛ مرّت مرحلتا `BTF` و`BTFIDS` في مخرج `vmlinux.unstripped`. |
| تغليف/تفليش | لم يُنفذ؛ `package=none` و`root=none` مفروضان. |

ظهرت تحذيرات DTC التاريخية المصنفة أثناء بناء `ukee.dtb` ولم تُخف أو تُخفض. لم يكن هذا الأمر إعادة تشغيل مستقلة لبوابات `tools/validate_marble_dt_build.sh` الأربع؛ لذلك تبقى آخر نتيجة بوابة موثقة `87/36/128/85` وليست نتيجة جديدة تُنسب إلى هذا البناء وحده. كما أن SPSS غير مفعّل في إعداد marble الافتراضي لهذا البناء؛ يظل تحقق SPSS المنفصل الموثق أعلاه هو دليل تكامله الساكن.

> نجاح هذا البناء يثبت تكامل المصدر عند رأس الفرع فقط. لا يثبت توافق ROM Evolution X ذي النواة 5.10 أو وحدات vendor أو firmware، ولا يفتح R1/B0 أو إنتاج `boot.img` أو التفليش.
