# خريطة المسارات الأساسية لـ marble

## نطاق المرحلة

يوثق هذا الملف حالة مسارات التخزين والطاقة والاتصال بعد بناء Device Tree بصورة ثابتة. تعني حالة `upstream-present` أن ACK 6.18 يحتوي تعريفاً أو binding بالاسم نفسه؛ ولا تعني أن الجهاز يعمل قبل مطابقة العقد والإعدادات والـfirmware على العتاد.

| المسار | توافقات marble الأساسية | حالة ACK 6.18 | مرجع Xiaomi 5.10 عند الحاجة | القرار الحالي |
|---|---|---|---|---|
| التخزين UFS | `qcom,ufshc`، `qcom,sm8450-ufshc` | `upstream-present` في `drivers/ufs/host/ufs-qcom.c` | شجرة UFS المرجعية للتفاصيل الخاصة بالمنصة | تكييف العقد والإعدادات أولاً؛ لا تُنسخ وحدة UFS كاملة قبل مقارنة واجهاتها. |
| USB وEUSB2/QMP | `qcom,dwc-usb3-msm`، `qcom,usb-snps-eusb2-phy`، `qcom,usb-ssphy-qmp-dp-combo` | `vendor-gap` للتوافقات الدقيقة؛ نواة DWC3 العامة موجودة | `dwc3-msm-core.c`، `phy-msm-snps-eusb2.c`، `phy-msm-ssusb-qmp.c` | يحتاج منفذ تعريفات أو تكييفاً إلى واجهة ACK، ولا يعد جاهزاً للتفليش. |
| PCIe | `qcom,pci-msm` | `vendor-gap` للتوافق الدقيق | `drivers/pci/controller/pci-msm.c` | مؤجل إلى ما بعد إقلاع UFS/USB. |
| RPMh والطاقة الأساسية | `qcom,rpmh-rsc` | `upstream-present` في `drivers/soc/qcom/rpmh-rsc.c` | مرجع العقد من Xiaomi | المحافظة على ACK ثم التحقق من clocks وinterconnect. |
| منظمات VRM/ARC | `qcom,rpmh-vrm-regulator`، `qcom,rpmh-arc-regulator` | `vendor-gap` للتوافقات الدقيقة | `drivers/regulator/rpmh-regulator.c` | يحتاج نقل واجهات regulator وKconfig قبل اختبار الطاقة. |
| PM8008 | `qcom,pm8008-regulator` | `vendor-gap` للتوافق الدقيق | `drivers/regulator/qcom_pm8008-regulator.c` | يتطلب منفذ driver قبل ضمان التهيئة الكهربائية للوحة. |
| Bluetooth/WLAN | `qcom,qca6490` | `vendor-gap` | `drivers/bluetooth/btpower.c`؛ مصدر WLAN الكامل غير مثبت ضمن مرجع النواة | محجوب على وحدات vendor وfirmware ووثائق CNSS. |
| PMIC GLINK | `qcom,pmic-glink` | `upstream-present` في `drivers/soc/qcom/pmic_glink.c` | مرجع العقد من Xiaomi | يحتاج تحقق Kconfig ومسار رسائل firmware على جهاز فعلي. |

## قاعدة النقل

> يُمنع نسخ أي driver من 5.10 مباشرة إلى 6.18 لمجرد تطابق `compatible`. يجب أولاً مقارنة API وKconfig وواجهات clock/regulator/interconnect وKMI، ثم إنشاء رقع قابلة للبناء ومراجعتها وحدها.

## الأولوية التالية

تبدأ مرحلة الإقلاع الأدنى بتثبيت UFS وRPMh وPMIC/regulator وserial. تبقى USB وPCIe وBluetooth/WLAN وواجهة modem غير صالحة للاختبار الوظيفي إلى أن تنقل تعريفاتها أو يثبت بديل ACK مكافئ لها.
