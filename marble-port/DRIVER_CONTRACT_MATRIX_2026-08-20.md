# مصفوفة توافق العقود ذات الأولوية — marble

**التاريخ:** 20 أغسطس 2026
**شجرة التحليل:** `marble-6.18-full-port` عند `32ffe3adde922d2b927c4849af186317d9dd8643`
**مرجع Xiaomi Kernel:** `marble-s-oss` عند `48952ed36228217531482b39d5bef13e7fd808ec` [1]
**مرجع Xiaomi Device Tree:** `marble-s-oss` عند `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` [2]

## الحكم التنفيذي

توضح هذه المصفوفة العقود الثلاثة التي تجمع بين عقد Device Tree فعلية وفجوات Kconfig/وحدات في مرجع Xiaomi. لا تساوي مطابقة `compatible` وحدها جهوزية الجهاز؛ يلزم أيضاً driver مناسب، وإعداد مفعّل، وسلامة ABI/firmware، ثم اختبار على العتاد.

| العقد/المسار | دليل DT المنقول | driver أو binding في 6.18 | حالة إعداد AOSP المبني | الحكم | الإجراء في هذه الجولة |
|---|---|---|---|---|---|
| SPSS + `glink-edge` | `qcom,cape-spss-pas` وطفل `glink-edge`؛ الحالة النهائية لـSPSS هي `disabled`. | `qcom_common.c` يكتشف طفلاً باسم `glink-edge` ويشغله عبر GLINK-SMEM؛ لكن لا يوجد driver مطابق لـ`qcom,cape-spss-pas` في الشجرة الحالية. | `RPMSG_QCOM_GLINK` غائب من إعداد AOSP؛ الرمز vendor `QCOM_SPSS` غائب من ACK. | **محجوب.** | لا تغيير لـ`reg` أو `ranges` أو `reg-names` ولا تفعيل config. |
| GLINK-SMEM القياسي | العقدة تتضمن `qcom,remote-pid` وIRQ وmailbox. | `qcom_glink_smem_register()` يقرأ `qcom,remote-pid` ثم IRQ وmailbox؛ لا يثبت دلالة `qcom,spss-addr`/`qcom,spss-size`. | `RPMSG_QCOM_GLINK_RPM` و`RPMSG_QCOM_GLINK_SMEM` غير مفعّلين. | **لا بديل تلقائي.** | يلزم port لمشغل SPSS/GLINK المتطابق ثم اختبار جهاز. |
| VADC7 | عقد PMIC تستخدم `compatible = "qcom,spmi-adc7"`. | `qcom-spmi-adc5.c` في 6.18 يطابق `qcom,spmi-adc7`. | `CONFIG_QCOM_SPMI_ADC5=y`. | **مدعوم ساكناً.** | لا تعديل؛ يبقى تحقق IIO على الجهاز مطلوباً. |
| ADC_TM7 | عقد PMIC تستخدم `compatible = "qcom,adc-tm7"`. | binding الحالي يدرجه بوصفه «غير مكتمل/قابل للتغيير»، بينما driver 6.18 لا يضم match لـ`qcom,adc-tm7`. | `CONFIG_QCOM_SPMI_ADC_TM5=y`، أما رمز Xiaomi `QTI_ADC_TM` فغائب. | **محجوب.** | لا إعادة تسمية إلى TM5 ولا إضافة خصائص لتجاوز الفحص. |
| UFS controller | `ufshc@1d84000` مع `compatible = "qcom,ufshc"`. | `ufs-qcom.c` يطابق `qcom,ufshc`. | `SCSI_UFSHCD=y` و`SCSI_UFSHCD_PLATFORM=y` و`SCSI_UFS_QCOM=y` و`SCSI_UFS_CRYPTO=y`. | **مدعوم ساكناً.** | لا تعديل؛ يلزم تحقق UFS/ICE وABI vendor على الجهاز. |
| UFS QMP PHY | عقدة UFS تشير إلى `ufsphy_mem`. | driver QMP-UFS يضم توافقات SM8450/SM8475، وإعداد `PHY_QCOM_QMP_UFS=y`. | مفعّل ضمن بناء AOSP. | **مدعوم ساكناً، لكن غير مختبر عتادياً.** | لا استبدال للـPHY أو قيم tune. |

## أدلة التوافق والحواجز

### SPSS وGLINK

المسار الحالي في `qcom_common.c` يبحث حرفياً عن طفل يسمى `glink-edge`، ثم يمرره إلى `qcom_glink_smem_register()`. يقرأ هذا المسار `qcom,remote-pid` وIRQ وقناة mailbox، ولذلك يفسر لماذا لا يجوز استخدامه دليلاً على صحة زوجي `reg` المسمّيين `qcom,spss-addr` و`qcom,spss-size`. لا يزال `compatible = "qcom,cape-spss-pas"` بلا driver مطابق في الشجرة، كما أن مرجع Xiaomi 5.10 يطلب `CONFIG_QCOM_SPSS` و`CONFIG_RPMSG_QCOM_GLINK_SPSS`، وكلاهما غير متاح بالاسم في ACK.

> النتيجة: إن تفعيل GLINK القياسي أو حذف خصائص SPSS لإسكات تحذير DTC سيغيّر عقدة vendor قبل إثبات أن remoteproc وfirmware المتوافقين موجودان. لذا يُمنع ذلك في هذه المرحلة.

### ADC7 وADC_TM7

يدعم driver ADC الحالي `qcom,spmi-adc7` ضمن `CONFIG_QCOM_SPMI_ADC5=y`، وهي مطابقة ساكنة مباشرة. على النقيض، يستخدم DT المنقول `qcom,adc-tm7` بينما مصدر Xiaomi 5.10 يوفّر مسار `CONFIG_QTI_ADC_TM` وملفات `adc-tm7.o`، أما شجرة 6.18 فتضم binding تحذر صراحة من أن توافق `qcom,adc-tm7` غير مكتمل وقابل للتغيير. لا توجد مطابقة driver مقابلة في 6.18.

> النتيجة: لا يجوز تغيير `qcom,adc-tm7` إلى `qcom,spmi-adc-tm5` أو `qcom,spmi-adc-tm5-gen2`؛ فذلك يستبدل عقد hardware/driver بلا إثبات للمعايرة أو الـthresholds.

### UFS

يملك controller توافقاً مباشراً مع `ufs-qcom.c` وتكون إعدادات UFS الأساسية وQMP PHY مفعلة في ناتج AOSP. ومع ذلك، يحتوي مرجع Xiaomi على وحدات إضافية مثل `ufshcd-crypto-qti.ko` و`phy-qcom-ufs-qmp-v4-cape.ko` لا يصح استنتاج تكافؤ ABI/ICE لها من نجاح بناء النواة. لا بد من manifest لروم واحد ووحدات vendor متوافقة قبل أي إقلاع تجريبي.

## النتيجة والتغيير المنفذ

لم تُضف هذه المرحلة أي تعديل لمصدر C أو Kconfig أو DTS. التغيير المنفذ هو **تثبيت مصفوفة القرار** لمنع نقل إعدادات vendor أو إعادة تسمية عقد Device Tree بصورة آلية. العقود الآمنة للتحقق الساكن لاحقاً هي UFS وVADC7؛ أما SPSS/GLINK وADC_TM7 فتحتاج مصدر driver/firmware مطابق واختبار عتادي.

## المراجع

[1]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss "MiCode Xiaomi Kernel OpenSource — marble-s-oss"
[2]: https://github.com/MiCode/kernel_devicetree/tree/marble-s-oss "MiCode kernel_devicetree — marble-s-oss"
[3]: https://source.android.com/docs/core/architecture/dto "Android Open Source Project — Device tree overlays"
