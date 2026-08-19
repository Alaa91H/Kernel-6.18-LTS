# رقعة bindings الأولية لـ SM7475/marble

## النطاق

أضافت هذه الرقعة 15 header مفقوداً تحت `include/dt-bindings/` من مصدر Xiaomi المرجعي `marble-s-oss`، الالتزام `48952ed36228217531482b39d5bef13e7fd808ec`. تحمل الملفات المنقولة ترخيص `GPL-2.0-only` الموجود في المصدر.

| المجموعة | headers المنقولة |
|---|---|
| clocks | AOP QMP، وcamcc/dispcc/gcc/gpucc/videocc لمنصة waipio. |
| platform fabric | interconnect waipio، IPCC، DCC v2، DMA heap constants. |
| power/thermal/USB | RPMh regulator levels، USB3 4nm QMP combo، thermal QTI. |
| input | HV haptics وQPnP power-on. |

سجل التجزئة لكل ملف موجود في `reports/marble_dt_bindings_imported.tsv`.

## التحقق المنجز

أعيد تحليل تضمينات Device Tree بعد الاستيراد. كانت النتيجة **30 binding موجوداً و0 مفقود** في مسار `include/dt-bindings` لشجرة ACK. هذا يحقق إغلاق فجوة التضمينات النصية فقط.

> لا يثبت هذا التحقق وجود تعريفات drivers أو clock providers أو interconnect providers المتوافقة مع هذه الأرقام في Linux 6.18. تبقى هذه العناصر ضمن DT-002 وDT-003، ولا يجوز إنتاج DTB أو صورة تفليش اعتماداً على headers وحدها.
