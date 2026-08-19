# بنية نقل marble إلى Android/GKI 6.18

## نتيجة تأسيسية

لا تحتوي شجرة ACK 6.18 الحالية على ملفات DTS أو تعريفات منصة باسم `sm7475` أو `cape` أو `marble`. لذلك لا يمكن أن يبدأ النقل من overlay هاتف فقط؛ بل يتطلب أولاً طبقة منصة Qualcomm متوافقة، ثم تعريف SoC، ثم طبقة اللوحة.

> لا تُنسخ شجرة Xiaomi 5.10 حرفياً إلى ACK 6.18. كل طبقة تضاف في رقع مستقلة مع فحص Kconfig والـbindings والـAPIs المستخدمة.

## طبقات النقل وترتيبها

| المعرّف | الطبقة | مكونات المصدر المرجعي | الاعتمادات | معيار الخروج |
|---|---|---|---|---|
| L0 | البنية والأدوات | ACK، LLVM، BTF، فحوص KMI | لا شيء | بناء arm64 متكرر وفحوص جرد ناجحة. |
| L1 | أساس Qualcomm | bindings، clocks، reset، interconnect، RPMh، SPMI، SCM، SMEM، IPCC | L0 | Kconfig وDTS bindings متوافقة مع 6.18. |
| L2 | SoC SM7475 | قاعدة `ukee.dtb` وملفات cape/Qualcomm: CPU وGIC وtimers وmemory map وreserved-memory وGunyah/remoteproc وUFS وUSB | L1 | DTB أساسي للمنصة يترجم ولا يحوي phandles مكسورة. |
| L3 | لوحة marble | `marble-sm7475.dtsi` وpinctrl وXiaomi common وPM8008 overlay فوق `ukee.dtb` | L2 | DTBO/DTB marble يترجمان ضد SoC المنقول. |
| L4 | مسار الإقلاع | regulator، PMIC، clocks، UFS، USB، serial، reboot reason | L1–L3 | إقلاع استردادي مع سجل UART/pstore. |
| L5 | التفاعل الأساسي | panel، touch، input، battery/charger، sensors | L3–L4 | شاشة ولمس وشحن وADB مستقرة. |
| L6 | الاتصال والوسائط | Wi-Fi/BT/CNSS، audio، DSP، modem/QRTR | L1–L5 | اختبارات اتصال وصوت ومودم موثقة. |
| L7 | الرسوميات والكاميرا | Adreno/KGSL، display stack، ISP/camera | L1–L6 | تسريع رسومي وكاميرات ضمن اختبارات طويلة. |
| L8 | توافق الرومات | BTF/KMI، vendor DLKM، AVB، boot/vendor_boot/dtbo | L0–L7 | حزمة اختبار خاصة بروم محدد، لا حزمة عامة عمياء. |

## واجهات الاعتماد

| الواجهة | المصدر المرجعي | المخاطرة في 6.18 | سياسة النقل |
|---|---|---|---|
| Kconfig | `marble_GKI.config` | 305 رمزاً مرجعياً غائبة اسمياً من ACK. | يسجل كل رمز كـ: upstream بديل، رقعة نقل، أو غير مدعوم. |
| Device Tree | `kernel_devicetree:marble-s-oss` | 36 ملفاً محلياً في إغلاق `ukee.dtb` وoverlay marble، إضافة إلى 30 binding خارجياً. | تنقل البداية من bindings ثم SoC ثم اللوحة، لا بالعكس. |
| الوحدات | `modules.list.msm.marble` | 111 وحدة، وبعضها vendor-only أو يحمل API قديمة. | تقسم إلى أساسية/اختيارية/تشخيصية/محظورة حتى يتأكد KMI. |
| vendor boot chain | الروم المختبر لاحقاً | صيغة boot header وAVB وDLKM تختلف بين الرومات. | لا تدخل ضمن النواة العامة؛ تُنفذ في فرع تكامل للروم المختار. |

## سلم الأولويات

الترتيب الملزم للأعمال هو L1 ثم L2 ثم L3 ثم L4. لا يبدأ نقل KGSL أو الكاميرا قبل قيام DTB marble أساسي وتعريفات القدرة والتخزين، لأن أخطاء الطبقات الأدنى تمنع تشخيص الطبقات العليا بصورة موثوقة.
