# جرد artefacts الرسمي لـEvolution X 17 — marble

**حالة الاستلام:** مكتمل وثابت. جرى فحص ZIP، وقراءة manifest الخاص بـAndroid OTA، واستخراج صور محددة من full payload باستخدام عمليات الاستبدال الكاملة فقط مع التحقق من SHA-256 لكل قسم. لم يُنفّذ أي ملف من ROM، ولم تُحمّل أي وحدة kernel، ولم يُنشأ `boot.img` جديد أو تُنفذ عملية تفليش.

> **حد الاستخدام:** تمثل هذه artefacts ROM الرسمي المحدد أدناه فقط. لا يجوز خلطها مع إصدار آخر أو روم آخر أو firmware مستقل، ولا تتحول سلامة الاستخراج إلى اعتماد توافق نواة 6.18.

## هوية المدخل وسلامة النقل

تسجل صفحة Evolution X الرسمية جهاز `marble` ضمن أجهزة Android 17.[1] تم تنزيل ملف ROM الرسمي المسجل في تقرير اكتشاف المصدر، ثم أُجري عليه اختبار CRC شامل باستخدام `unzip -t` وحساب SHA-256 محلي.

| حقل | القيمة المثبتة |
|---|---|
| اسم الإدخال | `EvolutionX-17.0-20260812-marble-12.1-Official.zip` |
| الحجم | `3,531,134,618` بايت |
| SHA-256 للـZIP | `f6abd32f40252bea3e8e3a8400949c29873f919f6f57fc76f31b3db242cda528` |
| اختبار ZIP | **نجح** (`unzip -t`) |
| صيغة التحديث | A/B OTA، `CrAU` payload v2 |
| SHA-256 لـpayload.bin | `01ad48fb044a05a45c0c3ff94c4f2835e4f8c52c33f8d40b3fa84c0a7c92cd94` |
| payload metadata | `232,720` بايت manifest و`267` بايت توقيع metadata |
| وقت `post-timestamp` | `2026-08-12T00:34:51Z` |
| الجهاز المطلوب OTA | `marble,marblein` |
| مستوى Android SDK | `37`؛ Android `17` |
| security patch | `2026-08-01` |

يفصل بروتوكول `update_engine` الرسمي رأس `CrAU` وmanifest والـoperation blobs، ويحدد حقول `PartitionUpdate` وحزم الـhash التي استخدمت للتحقق من الأقسام المستخرجة.[2] استقبل هذا الإدخال 31 تحديث قسم؛ لا توجد عملية delta أو source-copy في الأقسام الحساسة التي استخرجت، إذ كانت أنواعها `REPLACE` و`REPLACE_BZ` و`REPLACE_XZ` فقط.

## هوية البناء داخل النظام

هناك قيمتان يجب تسجيلهما معاً، لا اختيار إحداهما لإخفاء الأخرى. `META-INF/com/android/metadata` يعلن `post-build` عاماً باسم `google/mustang_beta/mustang:CANARY/ZP11.260717.006/16004061:user/release-keys`، بينما تكشف `system.img` نفسها أن `ro.system.build.fingerprint` هو `generic/marble/marble:17/CP2A.260605.016/eng.androi:user/release-keys` وأن `ro.evolution.device=marble`.

| الخاصية المقروءة من `system.img` | القيمة |
|---|---|
| `ro.system.build.id` | `CP2A.260605.016` |
| `ro.system.build.version.incremental` | `1786494891` |
| `ro.system.build.version.release` | `17` |
| `ro.system.build.version.sdk` | `37` |
| `ro.build.version.security_patch` | `2026-08-01` |
| `ro.product.mod_device` | `marble_global` |
| `ro.evolution.device` | `marble` |

هذه الملاحظة **لا تعني خللاً تلقائياً**؛ لكنها تجعل كتابة كل من fingerprint OTA وfingerprint system حقلاً إلزامياً في manifest خارج Git، وتمنع الاعتماد على قيمة واحدة في بوابة القبول.

## صور الإقلاع والأقسام الديناميكية

تحققت جميع الصور أدناه مقابل `new_partition_info.hash` المضمّن في manifest، لا مقابل اسم الملف وحده.

| القسم | الحجم (بايت) | SHA-256 | نتيجة القراءة |
|---|---:|---|---|
| `boot` | 201,326,592 | `635fdd95d1fcdec6705b36a98dfbe7bc094dcaa373bc8e5915339935b1b66530` | Android boot v4. |
| `vendor_boot` | 100,663,296 | `5d8063edc99883e59363a76f8cb5d0d56f9c854ebdb23d09671f006d34aa6de4` | Android vendor boot v4. |
| `dtbo` | 25,165,824 | `5306d0c74b9a7a9ef676e6b1f5c5da1f70d5588dfb397f9e9b2b6e21cb493cb7` | dt_table يحوي 14 مدخلاً. |
| `vendor_dlkm` | 94,461,952 | `6aa9f00dbc6501a2db56c6e09d3e003ada1bbab53c9c10dffeccaba5417a3336` | ext4 يحوي وحدات vendor 5.10. |
| `system` | 1,285,353,472 | `9bf6ada82a335785344060f3a409a1f6a55ac6a3bf9753dcec23f6e749a93cbb` | ext4؛ استُخدم لقراءة خصائص البناء فقط. |
| `vendor` | 2,112,389,120 | `19b0c11629b881beaccc367ca05cf6de6afb439d5b5a9b4e1113d17ea6f7dfbd` | ext4؛ استُخدم لجرد أسماء firmware فقط. |

> **ملاحظة مهمة:** لا يظهر قسم `system_dlkm` ضمن manifest لهذا البناء. لا يجوز اختراع مسار `SYSTEM_DLKM_DIR` في manifest؛ تسجل القيمة الفارغة صراحةً مع دليل absence من جرد payload.

### عقد boot وvendor_boot

| خاصية | `boot.img` | `vendor_boot.img` |
|---|---:|---:|
| نسخة الرأس | 4 | 4 |
| page size | 4096 | 4096 |
| حجم kernel | 46,608,644 | — |
| حجم boot ramdisk | 2,681,722 | — |
| حجم vendor ramdisk | — | 12,855,750 |
| حجم DTB المضمّن | — | 5,745,935 |
| bootconfig | — | 85 بايت |
| vendor ramdisk fragments | — | default + `dlkm` |

تكشف سلسلة الإصدار داخل `boot.img` عن:

> `Linux version 5.10.256-gki-ge8fcf2558711 … clang version 21.0.0 … #68 SMP PREEMPT Tue Aug 11 20:16:11 UTC 2026`

يحتوي fragment `dlkm` في `vendor_boot` على LZ4-compressed CPIO بحجم مفكوك `34,351,872` بايت، و337 ملف `.ko`، و99 مدخلاً في قائمة التحميل الأولية، و66 مدخلاً في blocklist. لا تُستخرج هذه الوحدات إلى ناتج 6.18 ولا تُستخدم لتلبية فجوة تعريف driver.

## ABI ووحدات DLKM

`vendor_dlkm.img` ext4 ويحوي 390 وحدة kernel، مع 289 مدخلاً في `modules.load` و66 في `modules.blocklist`. تظهر وحدات ممثلة مثل `msm_drm.ko` و`qca_cld3_qca6490.ko` و`qcom-spmi-adc5.ko` قيمة vermagic واحدة:

> `5.10.256-gki-ge8fcf2558711 SMP preempt mod_unload modversions aarch64`

| جانب المقارنة | Evolution X 17 المستخرج | مرشح marble 6.18 التشخيصي | الحكم |
|---|---:|---:|---|
| إصدار kernel | 5.10.256-gki | 6.18.32 | **ABI مختلف جذرياً**. |
| وحدات vendor_dlkm | 390 | 104 وحدات مبنية | لا يوجد بديل ثنائي مباشر. |
| وحدات dlkm في vendor ramdisk | 337 | لا توجد حزمة vendor ramdisk 6.18 معتمدة | بوابة إقلاع محجوبة. |
| module versioning | مفعّل في vermagic المرجعي | يلزم إثبات KMI جديد | لا يُسمح بإعادة استخدام `.ko` المرجعية. |

هذا يثبت عملياً، من artefacts ROM المطابقة نفسها، أن نقل نظام Evolution X إلى نواة Android Common Kernel 6.18 يتطلب porting حقيقياً لمسارات Qualcomm/Xiaomi (أو بدائل upstream متكافئة)، لا مجرد استبدال `Image` أو نسخ DLKM 5.10.

## Device Tree وfirmware

تتألف حاوية `dtbo.img` من 14 DTB، بحجم منطقي `4,299,397` بايت، وحجم entry `32` بايت وpage size `4096`. المدخل `entry-03` يحوي إشارات `marble/ukee` ويطابق `qcom,msm-id = <0x24f 0x10000>`؛ جميع المداخل تخضع لاختيار Qualcomm board/SOC، لذلك لا تصلح مقارنة حجم overlay 6.18 المحلي (`68,799` بايت) مع صورة الحاوية كاختبار توافق.

تسجل `vendor.img` 111 مدخلاً مباشرةً تحت `/firmware`، تشمل firmware للـGPU (`a730_*` و`a662_gmu.bin`)، الكاميرا (`CAMERA_ICP.*`)، EVA/VPU، Wi-Fi/Touch، والصوت. كذلك يضم payload 20 قسماً خاصاً بالـfirmware/boot-chain، منها `abl` و`aop` و`bluetooth` و`cpucp` و`dsp` و`modem` و`tz` و`uefi` و`xbl`. تبقى هذه artefacts مرتبطة ببناء `20260812` ولا تدخل Git.

## أثر الاستلام على بوابات التكامل

| البوابة | الحالة | الدليل |
|---|---|---|
| I0 — ZIP وسلامة المصدر | **مكتملة** | حجم متوقع، SHA-256 و`unzip -t` ناجح. |
| I1 — صور الإقلاع وDLKM | **مكتملة** | استخراج يتحقق من hash لكل قسم. |
| I2 — هوية ROM | **مكتملة مع ملاحظة مزدوجة** | metadata و`system/build.prop`. |
| I3 — firmware/DT inventory | **مكتملة للاستقبال** | 14 DTBO و111 firmware root entry و20 قسم firmware. |
| I4 — KMI/ABI لـ6.18 | **مرفوضة حالياً** | مرجع ROM 5.10.256 ووحدات vendor غير قابلة لإعادة الاستخدام. |
| I5 — تغليف/تفليش | **محظور** | لا KMI port مكتمل ولا اختبار POCO F5 فعلي. |

## الملفات المولدة محلياً

توجد بيانات قابلة لإعادة الإنتاج خارج Git تحت `artifacts/evolutionx17-marble-20260812/`: `zip_inventory/`، `payload_inspection/`، `boot_artifact_inspection.json`، `vendor_dlkm_inventory/`، `vendor_boot_dlkm_fragment/` و`vendor_firmware_inventory/`. لا تتضمن هذه الوثيقة أو المستودع صور ROM أو وحدات binary أو firmware أو مفاتيح توقيع.

## المراجع

[1]: https://evolution-x.org/devices/marble "Evolution X — marble device page"
[2]: https://android.googlesource.com/platform/system/update_engine/+/HEAD/update_metadata.proto "AOSP update_engine payload metadata protobuf"
