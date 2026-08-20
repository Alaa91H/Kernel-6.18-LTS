# تشغيل نكهات بناء marble

## بناء المصدر فقط

يدعم `tools/build_marble_flavor.sh` نكهتي `aosp` و`xiaomi` كوسم منشأ قابل للتتبع، وملفي `release` و`diagnostic`. لا يغير اختيار الروم تعريفات العتاد ولا يُنشئ `boot.img`؛ فالاختلاف الحقيقي بين الرومات يقع في صور vendor والوحدات والتوقيع، وهي مدخلات لا يمكن تخمينها من اسم الروم.

| الأمر | الناتج | الحالة |
|---|---|---|
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor aosp --root none --diagnostics release` | Image ووحدات وDTB/DTBO موسومة بـAOSP. | مسموح كمخرج مصدر فقط. |
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor xiaomi --root none --diagnostics release` | Image ووحدات وDTB/DTBO موسومة بـXiaomi. | مسموح كمخرج مصدر فقط. |
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor aosp --root none --diagnostics diagnostic` | مخرج مع BTF وdynamic-debug وftrace/pstore tracing. | مسموح للتحقق؛ ليس حزمة تفليش. |
| `--root ksu-next` أو `--root apatch` | رفض واضح. | غير مدعومين من upstream على Linux 6.18. |
| `--package boot` | رفض واضح. | محجوب حتى manifest وKMI واختبار جهاز. |

## templates لمدخلات التغليف

عند اكتمال بوابات القبول، ينسخ المستخدم ملف المثال المناسب إلى موقع خارج Git ويملأ مسارات artefacts التي استخرجت **من الروم المطابق للجهاز والبناء نفسه**. لا تُحمّل الصور أو المفاتيح أو firmware إلى المستودع.

| النكهة | النموذج |
|---|---|
| AOSP | `marble-port/manifests/aosp.env.example` |
| Xiaomi | `marble-port/manifests/xiaomi.env.example` |

> يطبع كل بناء `build-metadata.txt` ويشمل الالتزام، النكهة، وضع التشخيص، بصمات Image وDTB/DTBO وعدد الوحدات. تحفَظ هذه البيانات مع سجل الجهاز عند اختبار الاسترداد.
