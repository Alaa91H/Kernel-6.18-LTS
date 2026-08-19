# مراجع نقل marble إلى GKI 6.18

## المصادر المثبتة

| المكوّن | المستودع والفرع | الالتزام المرجعي | الغرض |
|---|---|---|---|
| قاعدة النواة العامة | Android Common Kernel `android17-6.18-lts` | `4e44babe3f67ee6cfd7f183ce2eb8e369170a639` قبل رقع المشروع | قاعدة GKI 6.18.32. |
| نواة Xiaomi المرجعية | `MiCode/Xiaomi_Kernel_OpenSource`, الفرع `marble-s-oss` | `48952ed36228217531482b39d5bef13e7fd808ec` | تعريفات 5.10، ملفات بناء marble، قوائم الوحدات، وملفات Kconfig الخاصة بالمورّد. |
| Device Tree الرسمي | `MiCode/kernel_devicetree`, الفرع `marble-s-oss` | `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` | شجرة Qualcomm DTS/DTSI/DTBO، بما فيها `qcom/marble-sm7475.dtsi` وملفات منصة parrot/diwali المرتبطة. |

## ملاحظة بنيوية

شجرة `Xiaomi_Kernel_OpenSource` لفرع marble لا تحتوي مسار `arch/arm64/boot/dts/vendor/qcom` المتوقع من `build.config.msm.common`؛ فقد نُشرت Device Tree في مستودع Xiaomi منفصل. لذلك يعامل هذا المشروع شجرة `kernel_devicetree` المرجع الرسمي الإلزامي لطبقة DTS، ولا يعد غيابها من شجرة النواة دليلاً على عدم وجود تعريفات اللوحة.

## قواعد الاستخدام

تُستورد ملفات DTS أو التعريفات من المراجع أعلاه في رقع صغيرة مصنفة حسب الطبقة. لا ينسخ المشروع إعدادات أو تعريفات 5.10 إلى 6.18 دفعة واحدة؛ يجب فحص كل ملف في ضوء تعريفات upstream/ACK الحالية وتبعياته وواجهة KMI قبل دمجه.
