# تحليل نقل SPSS إلى Kernel 6.18

**التاريخ:** 20 أغسطس 2026
**الفرع:** `marble-6.18-full-port`
**الحالة:** تحليل مصدر مكتمل؛ لم تُنشأ رقعة مصدر SPSS بعد ولم تُفعّل عقدة الجهاز.

## النتيجة الأساسية

دعم SPSS في marble ليس مجرد إضافة compatible إلى driver PAS العام. مرجع Xiaomi يشغّل loader خاصاً بـSPSS لأنه يحتاج بروتوكول إقلاع ثنائي المرحلة عبر سجلات SCSR وIRQ، ومسار GLINK مخصصاً يستخدم FIFO في SMEM وإعلان عنوانه للـSPSS. لا يستبدل `RPMSG_QCOM_GLINK_SMEM` هذا النقل، ولا تستطيع دالة `qcom_add_glink_subdev()` القياسية استخدامه لأنها مقيدة بـ`qcom_glink_smem`.

| الطبقة | مرجع Xiaomi 5.10 | المقابل المتاح في 6.18 | النتيجة |
|---|---|---|---|
| SPSS remoteproc/PAS | `drivers/remoteproc/qcom_spss.c` | PAS وremoteproc وSCM وMDT loader متاحة | يلزم driver SPSS منفصل ومكيّف، لا مجرد جدول compatible. |
| تحميل firmware | `spss.mdt` وPAS ID `14` | SCM وMDT loader متاحان | قابل للنقل ساكناً؛ firmware الحقيقي غير موجود في الشجرة. |
| SCSR/IRQ | `qcom,spss-scsr-bits` وسجلات مسماة وحالة PBL/SW_INIT | العقدة المنقولة تحتفظ بالعقد المطلوب | يلزم إبقاء منطق handshake المتخصص. |
| GLINK | `qcom_glink_spss.c` مع FIFO في SMEM | GLINK native موجود لكن عقد `pipe` تغيرت | يلزم transport SPSS جديد/مكيّف. |
| إيقاظ الطرف البعيد | إصدار Xiaomi لا يملك `kick` في عقد pipe | 6.18 يطلب `kick` | يجب توصيل mailbox في `glink-edge` كـ`kick` واستقبال IRQ باستدعاء `qcom_glink_native_rx()`. |
| SSC/SSR | SSR/sysmon helpers موجودة، وsysmon اختياري | helpers موجودة مع stubs عند غياب `QCOM_SYSMON` | يمكن إبقاء sysmon اختياريًا في المرحلة الأولى. |
| SPCOM وSPSS utils | ABI vendor وواجهات userspace | غير موجودة | خارج الحد الأدنى؛ لا تُنقل قبل نجاح remoteproc وGLINK على جهاز. |

## عقد Device Tree المثبتة

العقدة `qcom,cape-spss-pas` في `arch/arm64/boot/dts/qcom/cape.dtsi` تبقى `status = "disabled"`. تحتوي على `memory-region`، وسجلات SCSR، وقيم البتات، وclock/regulator وطفل `glink-edge`. طفل GLINK يعرّف `qcom,remote-pid = <8>` وmailbox وIRQ وسجلي `qcom,spss-addr` و`qcom,spss-size`.

> يجب أن تبقى حالة العقدة معطلة أثناء النقل والاختبار الساكن. لا يُسمح بتحويلها إلى enabled أو إنشاء حزمة تفليش قبل قبول firmware وABI والاسترداد والاختبارات العتادية.

## واجهات 6.18 المطلوبة

الـdriver المقترح يمكنه إعادة استخدام `qcom_scm_pas_auth_and_reset()` و`qcom_scm_pas_shutdown()` وMDT loader و`qcom_register_dump_segments()` وSSR helpers. لكن driver PAS الحديث يعتمد `qcom_q6v5` لتسلسل Q6، وهو ليس بديلاً لحالة SPSS ولا لإشارات SCSR.

طبقة GLINK تحتاج تكييفاً واضحاً من API Xiaomi إلى 6.18:

| فرق API | مرجع Xiaomi | Kernel 6.18 | قرار النقل |
|---|---|---|---|
| قراءة FIFO | `peak` | `peek` | إعادة تسمية callback. |
| lifecycle | `probe()` ثم `start()` ثم `remove()` و`unregister()` | `probe()` يبدأ التفاوض، و`remove()` فقط | حذف start/unregister القديمين وتثبيت الموارد قبل `probe()`. |
| التنبيه TX | لا `kick` في pipe | `kick` إلزامي عملياً | mailbox `spss_spss` يرسل notification بعد الكتابة. |
| التنبيه RX | لا ISR ظاهر في transport المرجعي | `qcom_glink_native_rx()` متاح | IRQ في `glink-edge` يستدعي RX. |

## الحد الأدنى المقترح للرقعة

1. إضافة `qcom_spss.c` مكيّفاً إلى `drivers/remoteproc`، مع Kconfig مستقل لا يفعّل تلقائياً.
2. إضافة `qcom_glink_spss.c` مكيّفاً إلى `drivers/rpmsg`، مع mailbox وIRQ وcallback `kick`.
3. إضافة header داخلي صغير بين driverين، من دون نقل `spcom` أو `spss_utils` أو ABI userspace.
4. إبقاء `qcom,cape-spss-pas` معطلاً، وعدم تغيير أي DTS في جولة النقل الساكن.
5. بناء كائنَي SPSS تحت `COMPILE_TEST` ثم بناء marble الكامل؛ فقط بعد ذلك يُطلب firmware وmanifest للروم وخطة استرداد لتجربة الجهاز.

## الحواجز الحالية

لا يمكن اختبار تشغيل SPSS من دون الملف الأصلي `spss.mdt` وتوافق صورة vendor/firmware والروم المستهدف. كما لا يصح افتراض أن عنوان FIFO أو الـPAS ID أو ترتيب SCSR صالح عبر الرومات. نجاح البناء يثبت تكامل API فقط، وليس تحميل firmware أو عمل GLINK أو سلامة الإقلاع.

## مراجع محلية

1. `/home/ubuntu/work/reference/xiaomi-marble-5.10/drivers/remoteproc/qcom_spss.c`
2. `/home/ubuntu/work/reference/xiaomi-marble-5.10/drivers/rpmsg/qcom_glink_spss.c`
3. `/home/ubuntu/work/Kernel-6.18-LTS/drivers/remoteproc/qcom_q6v5_pas.c`
4. `/home/ubuntu/work/Kernel-6.18-LTS/drivers/rpmsg/qcom_glink_native.c`
5. `marble-port/reports/spss_reference_inventory_raw_2026-08-20.txt`
