# سياسة المراقبة والتشخيص لـ marble

## نكهات التشخيص

| المكوّن | `release` | `diagnostic` | سبب الفصل |
|---|---|---|---|
| BTF ومعلومات التصحيح | مطلوبة للتحقق من KMI متى دعمتها أداة البناء. | مطلوبة أيضاً. | BTF ليس بديلاً عن اختبار الجهاز لكنه شرط مهم لفحص الواجهة. |
| pstore/ramoops | يبقى دعم GKI الأساسي مفعلاً. | يضاف ftrace persistent عند اجتياز بناء التهيئة. | يحتفظ بسجل panic/oops لإعادة التشغيل، لكن نجاحه يحتاج ذاكرة محجوزة واختبار جهاز. |
| ftrace | يبقى دعم GKI الأساسي فقط. | `FUNCTION_TRACER` و`FUNCTION_GRAPH_TRACER` و`FTRACE_SYSCALLS` و`BOOTTIME_TRACING`. | يتيح تحديد موضع توقف الإقلاع أو الانحدار الوظيفي؛ لا يفعّل تلقائياً في الإصدار. |
| dynamic debug | معطّل افتراضياً. | مفعّل؛ لا تُكتب قواعد debug في cmdline افتراضياً. | يتيح تحكمًا انتقائياً في سجلات drivers من دون إغراق سجل الإصدار. |
| watchdog/lockup/hung workqueue | إعدادات GKI الحالية تبقى مفعلة. | تبقى مفعلة مع إخراجها في تقرير الصحة. | تلتقط soft/hard lockup وRCU/workqueue stalls. |
| KASAN/KFENCE/UBSAN | لا تضاف خيارات جديدة فوق GKI. | لا تفرض KASAN أو LOCKDEP من fragment عام. | هذه الأدوات لها أثر ذاكرة وأداء وتحتاج نواة اختبار وحزمة ROM واختبار جهاز منفصلين. |

## الحالة المثبتة في GKI الأساسي

إعداد GKI الحالي يفعّل `PSTORE` و`PSTORE_RAM` و`PSTORE_CONSOLE` و`PSTORE_PMSG` و`DEBUG_FS` و`FTRACE` و`KPROBE_EVENTS` و`KALLSYMS_ALL` و`STACKTRACE` و`FRAME_POINTER` و`MAGIC_SYSRQ` وwatchdog/RCU stall detection و`KFENCE` و`UBSAN`. أما `DYNAMIC_DEBUG` و`FUNCTION_TRACER` و`PSTORE_FTRACE` فليست مفعلة في النكهة الأساسية؛ وتصلح لتكون جزء `diagnostic` منفصلاً.

## بوابة التحقق من التشخيص

نجاح Kconfig أو وجود عقدة `ramoops` لا يثبت حفظ السجلات. يجب على اختبار الجهاز إثبات وجود `/sys/fs/pstore` بعد panic مراقب أو إعادة تشغيل متعمدة في بيئة استرداد، وفحص buffer فـtrace، وإثبات عدم وقوع reboot loop. لا ترفع مفاتيح panic أو fault injection أو أوامر trace الدائمة إلى نكهة `release`.

> تشخيص الأعطال الفعلي هو سلسلة أدلة: صورة ذات رموز وتصحيح مناسب، وسجل serial أو pstore محفوظ، و`dmesg` بعد الإقلاع، ورمز مصدر مطابق لبصمة الصورة. لا يوجد خيار Kconfig منفرد يجعل النواة «مراقَبة بنسبة 100%».
