# قواعد خارجية مرجعية لإصلاح DTC

## قواعد التسمية و`reg`

تنص مواصفة Devicetree على أن جزء عنوان الوحدة في اسم العقدة يجب أن يطابق أول عنوان في خاصية `reg`، وأنه يجب حذف `@unit-address` عندما لا توجد `reg`.[1] كما تحدد أن ترميز `reg` يعتمد على `#address-cells` و`#size-cells` لدى **العقدة الأب**، ولا يُورث من الأسلاف؛ ويجب تعريف الخلايا صراحةً للعقد الحاوية للأبناء.[1]

## قواعد `ranges`

توضح المواصفة أن `ranges` الفارغ يعلن تطابق فضاء عناوين الطفل والأب، بينما ترميز `ranges` غير الفارغ يعتمد على خلايا العناوين والحجم للعقدة والأب.[1] لذلك لا يجوز إضافة أو حذف الخلايا أو `ranges` لتسكين تحذير إلا إذا بقيت دلالة فضاء العناوين والعقدة المستهدفة صحيحة.

## معيار أسلوب Linux

يوصي دليل Linux بأن تستعمل عناوين الوحدة أرقاماً سداسية صغيرة من دون أصفار بادئة، وأن تُرتب خصائص `compatible` ثم `reg` ثم `ranges`، لكنه لا يجيز التضحية بعقدة binding أو مورد عتاد من أجل النظافة الشكلية.[2]

## قنوات Qualcomm ADC

يبين binding `qcom,spmi-vadc.yaml` في ACK 6.18 أن عقد ADC channels يجب أن تتبع نمط `channel@[0-9a-f]+` وأن `reg` يمثل رقم القناة.[3] ويبين binding ADC thermal monitor أن أسماء حساسات ADC_TM تتضمن عنوان القناة وأن `reg` يحدد قناة الحساس.[4] لذلك تعد إعادة تسمية القنوات القديمة إلى أسماء متوافقة مرشحة فقط بعد إثبات عدم وجود مستهلك لمسار الاسم، مع إبقاء `label` و`reg` والـphandles دون تغيير.

## المراجع

[1]: https://devicetree-specification.readthedocs.io/en/latest/chapter2-devicetree-basics.html "Devicetree Specification — node names, address cells, reg and ranges"
[2]: https://docs.kernel.org/devicetree/bindings/dts-coding-style.html "Linux Devicetree Sources Coding Style"
[3]: https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/iio/adc/qcom%2Cspmi-vadc.yaml "Qualcomm SPMI PMIC ADC binding"
[4]: https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/thermal/qcom%2Cadc-tm5.yaml "Qualcomm ADC thermal monitor binding"

## GICv3 وITS وPCIe

يُلزم binding GICv3 عقدة GIC الحاوية لـITS بتعريف `#address-cells` و`#size-cells` و`ranges` المناسبين لترميز `reg` في ITS، كما يعرّف ITS كعقدة `msi-controller` مع `#msi-cells = <1>`.[5] لذلك فإن تحذيرات MSI تحت GIC ليست مرشحة لإضافة خلايا عشوائية: يجب أن تتبع بنية GICv3/ITS المحددة في binding وأن تعاد مراجعة خرائط MSI الخاصة بـPCIe مع مصدر Qualcomm أحدث.[6]

[5]: https://www.kernel.org/doc/Documentation/devicetree/bindings/interrupt-controller/arm%2Cgic-v3.txt "ARM GICv3 Device Tree binding"
[6]: https://lkml.iu.edu/hypermail/linux/kernel/2301.0/00391.html "Qcom: Add GIC-ITS support to SM8450 PCIe controllers"
