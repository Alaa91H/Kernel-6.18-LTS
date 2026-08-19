# جرد نقل marble

ينظم هذا المجلد نتائج الجرد القابلة لإعادة الإنتاج لنقل POCO F5 (`marble` / SM7475) من مرجع Xiaomi 5.10 إلى Android/GKI 6.18. تُنشأ النتائج بواسطة الأداتين التاليتين:

```bash
./tools/marble_port_inventory.sh
./tools/marble_dt_closure.sh
```

## لقطة الجرد الحالية

| العنصر | النتيجة | الدلالة |
|---|---:|---|
| طلبات Kconfig في `marble_GKI.config` | 429 | نطاق التهيئة المرجعية المنشورة من Xiaomi. |
| رموز موجودة اسمياً في ACK 6.18 | 124 | مرشحة للمراجعة، لا للتمكين التلقائي. |
| رموز مفقودة اسمياً في ACK 6.18 | 305 | فجوات نقل يجب أن تعالج برقم قضية أو رقعة أو بديل upstream. |
| وحدات `modules.list.msm.marble` | 111 | نطاق وحدات vendor المرجعية. |
| ملفات DTS مباشرة مرتبطة بـ marble/SM7475 | 4 | نقطة البداية لتعريف اللوحة. |
| إغلاق تضمينات DTS المحلي | 36 | يشمل قاعدة `ukee.dtb` الرسمية للـoverlay وملفات منصة cape/Qualcomm اللازمة. |
| تضمينات DTS الخارجية | 30 | bindings يفترض وجودها أو تكييفها في ACK. |

## ترتيب القراءة

1. راجع `reports/marble_gki_missing_categories.tsv` لتحديد فجوات Kconfig حسب الطبقة.
2. راجع `reports/marble_module_categories.tsv` لفصل الوحدات الأساسية عن وحدات التشخيص وvendor hooks.
3. ابدأ Device Tree من `reports/marble_dt_include_closure.txt`، ولا تنقل ملف overlay قبل تحليل شجرة تضميناته.
4. راجع `PORT_ACCEPTANCE.md` قبل إعلان أي مستوى نجاح أو إنشاء مخرجات تفليش.

> الجرد ليس رقعة نقل. إنه يمنع الاستنتاج الخاطئ بأن بناء GKI عام وحده يجعل تعريفات Xiaomi 5.10 متوافقة مع 6.18.
