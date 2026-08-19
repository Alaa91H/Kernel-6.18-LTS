# تقييم وحدات العرض والوسائط والاتصال عالي المستوى

## نتيجة المطابقة الثابتة

تمت مطابقة التوافقات الموجودة في Device Tree الخاص بـ marble مع ملفات drivers وbindings الموجودة في ACK 6.18. يعني `no-exact-match` غياب تطابق نصي لتعريف العقدة في الشجرة الحالية؛ ولا يثبت غياب كل بديل ممكن، لكنه يمنع الادعاء بأن العقدة ستعمل بلا نقل أو تكييف.

| المسار | توافق marble | نتيجة مطابقة ACK 6.18 | حالة النقل |
|---|---|---|---|
| GPU/Adreno | `qcom,adreno-gpu-gen7-4-0` | `no-exact-match` | محجوب على تكييف DRM/Adreno أو منفذ KGSL؛ لا يفعّل في نواة الاختبار. |
| معالج العرض | `qcom,cape-gpucc` وملفات display المرتبطة | `no-exact-match` | محجوب على clock/display driver خاص بالمنصة. |
| الكاميرا | `qcom,cape-camcc` | `no-exact-match` | محجوب على سلسلة camera/ISP وuserspace vendor المطابق. |
| ADSP | `qcom,cape-adsp-pas` | `no-exact-match` | محجوب على مسار remoteproc/firmware ومطابقة الذاكرة المحجوزة. |
| CDSP | `qcom,cape-cdsp-pas`، `qcom,cdsp-loader`، `qcom,msm-cdsp-rm` | `no-exact-match` | محجوب على تعريفات DSP vendor وfirmware. |
| المودم/QRTR | `qcom,cape-modem-pas`، `qcom,qrtr-mhi`، `qcom,qrtr-gunyah` | `no-exact-match` | محجوب على تعريفات مودم وfirmware واتفاقية vendor. |
| الصوت عبر Slimbus | `qcom,slim-ngd-v1.5.0` | `upstream-present` في `drivers/slimbus/qcom-ngd-ctrl.c` | يتطلب تكييفاً لاحقاً للعقد والـcodec/DSP؛ لا يعد جاهزاً وظيفياً. |
| USB audio QMI | `qcom,usb-audio-qmi-dev` | `no-exact-match` | مؤجل حتى نقل مسار QMI/USB audio vendor. |

## حدود المصدر المرجعي

مرجع Xiaomi يحتوي شجرة `drivers/gpu/msm` خاصة، بينما ACK يحتوي `drivers/gpu/drm/msm`، وهذا اختلاف معماري لا تسمح معه عملية نسخ الملفات. كما أن مجلدات camera/audio/display المستقلة ليست حاضرة في مرجع kernel المتاح؛ لذلك لا توجد قاعدة مصدر مكتملة لادعاء نقل تلك الوظائف إلى 6.18.

> لا تُفعّل GPU أو الشاشة أو الكاميرا أو الصوت أو المودم لمجرد أن Device Tree يُبنى. قبول هذه المسارات يستلزم تعريفات متوافقة وfirmware ووحدات vendor واختبارات جهاز فعلية.
