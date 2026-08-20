# سجل المصادر العلنية — 20 أغسطس 2026

## Android Open Source Project: Device tree overlays

المصدر: <https://source.android.com/docs/core/architecture/dto>

تؤكد وثيقة AOSP أن Device Tree يصف عتاداً غير قابل للاكتشاف، وأن الموردين يقدّمون DTS تُترجم إلى DTB بواسطة `dtc`. كما تصف DTO بوصفه overlay يُطبّق فوق DTB مركزي بواسطة bootloader، وأن عملية الإقلاع الفعلية تشمل بناء DTB ووضعه في موقع موثوق متاح للـbootloader ثم تحميله إلى الذاكرة. يدعم ذلك اعتماد هذه الجولة على بناء DTB وDTBO ودمجهما وفحص الناتج، بدلاً من اعتبار DTBO منفرداً دليلاً كافياً.

## Qualcomm Linux documentation

المصدر: <https://docs.qualcomm.com/doc/80-70018-3/topic/getting_started_chapter2.html>

لم توفّر الصفحة محتوى تقنياً قابلاً للقراءة في هذه البيئة؛ اقتصرت على شاشة ملفات تعريف الارتباط. لذلك لا تُستخدم بوصفها دليلاً على ترميز SPSS/GLINK أو ADC، ولا تبرر أي تعديل في العقد المستهدفة.

## قرار الاستخدام

لا يستبدل أي من المصدرين أعلاه binding أو مصدر driver Qualcomm المتطابق مع `marble` لعقد ADC5 أو SPSS. تظل هذه المراجع مدخلات مطلوبة قبل تعديل تلك العقود.

## مراجع Xiaomi المثبتة

| المرجع | الفرع | الالتزام المثبت | الغرض |
|---|---|---|---|
| <https://github.com/MiCode/kernel_devicetree> | `marble-s-oss` | `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` | مرجع DTS/DTSI/DTBO لـRedmi Note 12 Turbo / POCO F5؛ استُخدم لفحص include closure ومقارنة ملفات marble المنقولة. |
| <https://github.com/MiCode/Xiaomi_Kernel_OpenSource> | `marble-s-oss` | `48952ed36228217531482b39d5bef13e7fd808ec` | مرجع Xiaomi Kernel 5.10؛ استُخدم لجرد `marble_GKI.config` و`modules.list.msm.marble`. |

نجح فحص include closure مقابل مرجع Device Tree؛ أحصى 36 ملف تضمين محلياً و30 ترويسة `dt-bindings` خارجية، وكانت جميع الترويسات الثلاثين موجودة في شجرة ACK الحالية. أظهر جرد مرجع 5.10 وجود 429 طلب إعداد، منها 124 رمزاً متاحاً بالاسم في ACK و305 فجوة تحتاج مراجعة أو نقلاً؛ كما أحصى 111 وحدة مرجعية. هذه الأرقام تصف فجوة النقل ولا تمثل تفويضاً لتمكين الرموز آلياً.

## تحقق SPSS/GLINK

أظهر بحث أولي في مصدر ACK 6.18 أن `drivers/remoteproc/qcom_common.c` يطلب طفلاً باسم `glink-edge`. لا يثبت ذلك وحده دلالة ترميز `qcom,spss-addr` أو `qcom,spss-size`، ولذلك لا يُعد مبرراً لتعديل خلايا `reg` أو `ranges` لعقدة SPSS.
