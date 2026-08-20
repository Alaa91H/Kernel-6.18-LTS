# مصادر وملاحظات نقل ADC_TM7 — 20 أغسطس 2026

## المصادر الخارجية

| المصدر | المرجع | الملفات أو الغرض |
|---|---|---|
| [MiCode Xiaomi Kernel OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss) | فرع `marble-s-oss`، الالتزام المحلي المثبت `48952ed36228217531482b39d5bef13e7fd808ec` | مصدر marble 5.10 المرجعي. يوفّر `drivers/thermal/qcom/{adc-tm.c,adc-tm-common.c,adc-tm.h,adc-tm5.c,adc-tm7.c}` و`CONFIG_QTI_ADC_TM`. |
| [LineageOS android_kernel_xiaomi_sm8450](https://github.com/LineageOS/android_kernel_xiaomi_sm8450/tree/lineage-23.2) | الفرع `lineage-23.2` | مرجع مقارنة أحدث فقط؛ يضم عائلة ADC_TM نفسها وواجهتي `qpnp-revid.h` و`adc-tm-clients.h`. لا يُعتمد مصدراً تلقائياً للرقعة. |

## نتائج الجرد الأولي

تستخدم شجرة Xiaomi 5.10 `CONFIG_QTI_ADC_TM=m` وتبني وحدة `qti-adc-tm.o` من أربعة ملفات تطبيق: `adc-tm.c` و`adc-tm-common.c` و`adc-tm5.c` و`adc-tm7.c`. يحتاج stack المرجعي إلى واجهتي vendor غير موجودتين في شجرة 6.18 الحالية: `linux/qpnp/qpnp-revid.h` و`linux/adc-tm-clients.h`.

تضم شجرة 6.18 الحالية driver `qcom-spmi-adc-tm5.c`. يحتوي بالفعل مسار `ADC_TM5_GEN2` ذا خريطة سجلات متقاربة جداً من ADC_TM7، لكنه لا يطابق `qcom,adc-tm7` ولا يستطيع probe عقدة target مباشرة لأن parser الحالي يتطلب عقد قنوات أبناء. عقدة `pmk8350_adc_tm` في marble تعلن `qcom,adc-tm7` و`reg = <0x3400>` وIRQ و`#thermal-sensor-cells = <1>` ولا تملك عقد قنوات أبناء أو override marble مثبت حتى الآن.

النتيجة الأولية هي أن إضافة `compatible` فقط إلى driver الحالي غير آمنة وغير كافية. يلزم إما نقل مسار TM7 مخصص بعد عزل/نقل واجهات vendor المطلوبة، أو إعادة تصميم driver الحالي ليدعم واجهة thermal-sensor index الخاصة بـTM7 مع إثبات تكافؤ DT والـhardware.
