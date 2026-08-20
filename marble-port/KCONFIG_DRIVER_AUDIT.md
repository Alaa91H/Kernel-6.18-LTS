# تدقيق Kconfig والتعريفات وFirmware لـ marble

## نتيجة الجرد

يقارن التقرير المرجعي 429 طلب تهيئة من مرجع Xiaomi 5.10 مع Android Common Kernel 6.18. يوجد 124 رمزاً بالاسم في ACK، بينما 305 رموز غير موجودة فيه. لا يعني تطابق الاسم أن driver أو binding أو ABI متوافق مع SM7475؛ ولا يعني غياب الاسم أن المسار لا يمكن نقله، بل يحدد عملاً مطلوباً خارج تفعيل Kconfig.

| المجال | النتيجة | القرار |
|---|---|---|
| UFS | `SCSI_UFS_QCOM` موجود ومفعّل؛ `PHY_QCOM_QMP_UFS` موجود في ACK لكن توافق DT الحالي `qcom,ufs-phy-qmp-v4-cape` غير موجود. | لا يفعّل PHY البديل قبل تكييف binding والعقدة. |
| USB | `USB_DWC3_QCOM` موجود، لكن توافق Xiaomi `qcom,dwc-usb3-msm` غير موجود في ACK. | لا يستبدل compatible ولا يفعّل glue مختلفاً بلا رقعة driver موثقة. |
| serial/SLIMbus | `SERIAL_QCOM_GENI` و`SLIM_QCOM_NGD_CTRL` موجودان؛ توافق Slimbus موجود. | قابل للتقييم في مسار منفصل بعد تعريف codec/DSP وfirmware. |
| DSP/modem | توجد بدائل عامة مثل `QCOM_Q6V5_ADSP` و`QCOM_Q6V5_MSS` و`QRTR_MHI` و`MHI_BUS`، لكن توافقات cape الخاصة لا تطابقها مباشرة. | محجوب على تكييف remoteproc/MHI/firmware في زمن التشغيل. |
| GPU والعرض | `drivers/gpu/msm` و`techpack/display` غير موجودين في checkout. | لا يمكن نقل KGSL أو display vendor من دون المصدر الكامل. |
| الكاميرا والصوت وWLAN vendor | `techpack/camera` و`techpack/audio` و`qcacld-3.0` غير موجودة. | لا توجد قاعدة مصدر كافية لتفعيل 5.10 vendor symbols أو وحداتها. |
| firmware اللوحة | تشير DTS إلى `goodix_firmware_TM.bin` و`goodix_cfg_group_TM.bin` و`idt9415.bin`. | يجب إدراج مصدر firmware وترخيصه ومطابقة الإصدار في خطة الجهاز؛ لا تُنشأ ملفات firmware بديلة. |

## قاعدة التفعيل

تفعيل رمز ACK جائز فقط إذا اجتازت جميع الشروط التالية: يوجد driver وbinding في ACK، وتطابق عقدة Device Tree الـcompatible والعقود التابعة، وتتوفر firmware اللازمة، ويوجد اختبار تشغيل على marble. الرموز المتشابهة بالاسم أو الوظيفة لا تكفي، لأن Linux يطابق الأجهزة ببيانات الـDevice Tree والـbindings لا بمجرد نية التهيئة.[1]

> 182 من الرموز المفقودة مصنفة في عائلات Qualcomm/Xiaomi vendor، وتشمل KGSL وCNSS وIPA وWALT وQTI minidump/charger وUSB/MSM legacy. نسخ تهيئة 5.10 إلى 6.18 أو تفعيل رموز غير موجودة لا ينتج تعريفاً قابلاً للبناء أو التشغيل.

## المراجع

[1]: https://docs.kernel.org/devicetree/usage-model.html "Linux and the Devicetree"
