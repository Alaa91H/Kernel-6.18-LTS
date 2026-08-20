# تصميم نكهات بناء marble

## الهدف والنطاق

ينتج المشروع نواة Android/GKI عامة، لا `boot.img` خاصاً بروم بعينه. لذلك تفصل واجهة البناء بين نكهة ROM التي تحدد **مدخلات التغليف والـvendor المتطابقة**، وطبقة root الاختيارية، وملف التشخيص. لا تُبنى أو تُوقّع أو تُفلش حزمة إقلاع قبل توفير مكونات ROM الفعلية واجتياز بوابات KMI والجهاز.

| خيار الواجهة | القيم المخططة | الأثر |
|---|---|---|
| `--flavor` | `aosp`، `xiaomi` | يختار manifest للمدخلات المتطابقة فقط؛ لا يغيّر Device Tree أو يزعم توافق vendor modules. |
| `--root` | `none`، `ksu-next`، `apatch` | يحدد سياسة المصدر وحالة الدعم؛ الافتراضي والوحيد المقبول حالياً هو `none`. |
| `--diagnostics` | `release`، `diagnostic` | يحدد جزء Kconfig الخاص بالمراقبة بعد اجتياز اختبارات البناء. |
| `--package` | `none`، `boot` | يمنع `boot` إلا عند وجود manifest صحيح واكتمال بوابات القبول. |

## حالة طبقات root على 6.18

| الطبقة | حالة الدعم المنشورة من المشروع | القرار على Android/GKI 6.18 |
|---|---|---|
| KernelSU Next | يعلن دعماً للنوى من 4.4 حتى 6.6 فقط، مع وضع GKI 5.10–6.6.[1] | **غير مدعوم**؛ نص البناء يجب أن يرفض الطلب ولا يجلب أو يطبق patch تلقائياً. |
| APatch | يعلن دعماً لـARM64 مع إصدارات kernel 3.18–6.12، ويتطلب `CONFIG_KALLSYMS=y`.[2] | **غير مدعوم** على 6.18؛ يرفض نص البناء الطلب ولا ينشئ مفتاح SuperKey أو patch. |
| بلا root | لا يضيف patch خارج ACK. | النكهة المدعومة حالياً، وتبقى خاضعة لفجوات marble وKMI والجهاز. |

> إضافة root framework غير مدعوم إلى 6.18 ليست «نكهة بناء»، بل عملية نقل kernel مستقلة عالية المخاطر. لا يُنفذ هذا المشروع نسخاً أعمى من patch أو تجاوزاً لفحوص الإصدار، لأن ذلك قد ينتج kernel panic أو يخرق KMI.

## مدخلات التغليف المطلوبة لكل ROM

لا تُستنتج مكونات التغليف من اسم الروم. يحتاج manifest النكهة إلى المصدر، و`boot` أو `vendor_boot` المطابق، و`dtbo` إن استُخدم، ووحدات `vendor_dlkm`/`system_dlkm` المتوافقة، وسياسة AVB/التوقيع المتفق عليها. تضمن KMI في GKI التوافق ضمن الفرع المدعوم فقط؛ ولا تحافظ تلقائياً على التوافق بين نوى GKI مختلفة أو وحدات vendor مبنية لنسخة أخرى.[3]

## المراجع

[1]: https://github.com/KernelSU-Next/KernelSU-Next "KernelSU Next — support matrix"
[2]: https://github.com/bmax121/APatch "APatch — supported kernels and configuration requirements"
[3]: https://source.android.com/docs/core/architecture/kernel/android-common "Android common kernels — KMI compatibility"
