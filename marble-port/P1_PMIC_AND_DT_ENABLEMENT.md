# موجة P1 — PMIC وDevice Tree لـ marble 6.18

## القرار والنطاق

تضيف هذه الموجة المسار الأول للتحكم في PMIC يمكن إثباته مباشرةً في Android Common Kernel 6.18. لا تنقل أي binary أو وحدة من Evolution X 17/5.10، ولا تنتج `boot.img` أو `vendor_boot.img` أو `vendor_dlkm.img`.

> **قاعدة القبول:** لا يُفعل driver لأن اسمه يشبه وحدة مرجعية. يلزم وجود عقدة Device Tree مستخدمة فعلياً، و`compatible` مطابق في جدول `of_match` الخاص بـACK 6.18، وتبعيات Kconfig محلولة إلى `y`، ثم بناء واختبار جهاز قبل إعلان نجاح التشغيل.

| العنصر | دليل marble | دليل ACK 6.18 | القرار |
|---|---|---|---|
| SPMI PMIC Arbiter | `spmi0_bus` و`spmi1_bus` في `cape.dtsi`، وكلاهما `qcom,spmi-pmic-arb` | `drivers/spmi/spmi-pmic-arb.c` يطابق `qcom,spmi-pmic-arb`؛ الرمز `SPMI_MSM_PMIC_ARB` | مفعّل كـ`y` في fragment الأساسي. |
| UFS/QMP | عقد UFS في marble تستخدم المسار العام؛ `SCSI_UFS_QCOM` و`PHY_QCOM_QMP_UFS` مفعّلان مسبقاً | driver موجود ومفعّل مسبقاً | لا تغيير؛ يلزم اختبار جهاز. |
| RPMh/SCM | عقد RPMh ومصادرها متاحة في ACK | `QCOM_RPMH` و`QCOM_RPMHPD` و`REGULATOR_QCOM_RPMH` و`QCOM_SCM` مفعلة مسبقاً | لا تغيير؛ يلزم اختبار جهاز. |
| LLCC/AOSS/TSENS waipio | compatibles الخاصة باللوحة موجودة في DT | لا يوجد `of_match` مباشر في ACK 6.18 للـcompatibles الموجودة | محجوبة؛ لا تفعيل تجريبي. |
| Watchdog | لا توجد عقدة marble مطابقة لجدول `qcom-wdt.c` | `QCOM_WDT` موجود لكن لا يملك عقدة مستهدفة مثبتة | محجوب؛ لا تفعيل تجريبي. |

## تغيرات التهيئة والبناء

يضيف `marble_gki_6_18_core.config` الرمز `CONFIG_SPMI_MSM_PMIC_ARB=y`. يتحقق `tools/validate_marble_core_config.sh` من هذا الرمز ضمن 16 رمزاً أساسياً، ويستبدل assignments السابقة عند دمج fragments كي لا تنتج بيئة التحقق أو البناء تحذيرات `override: reassigning` اصطناعية. يحافظ الدمج المرتب على أسبقية `diagnostic` فوق `proto`، ومنها إعادة تفعيل BTF في النكهات التشخيصية.

## إصلاح Device Tree المتحقق

أزيلت خلايا العنوان/الحجم و`reg` غير اللازمة من ثلاث حاويات CoreSight أحادية المنفذ، وحُول `port@0` إلى `port`. بقيت labels الخاصة بالـendpoints ومراجع `remote-endpoint` بلا تغيير، ولا توجد مراجع لمسارات العقد المتغيرة. نجح بناء DTB وDTBO وفك ترميزهما وتطبيق overlay بعد التغيير.

| قياس DTC | قبل الرقعة | بعد الرقعة | التغير |
|---|---:|---:|---:|
| سجل البناء | 129 | 126 | -3 |
| فك ترميز `ukee.dtb` | 53 | 50 | -3 |
| فك ترميز DTBO | 154 | 153 | -1 |
| فك ترميز DTB المدمج | 103 | 99 | -4 |

شدّد `tools/validate_marble_dt_build.sh` ميزانياته الافتراضية إلى `126/50/153/99`، ولذلك ستفشل أي عودة لهذه التحذيرات أو أي تراجع جديد. لا يعني ذلك أن شرط الصفر تحقق؛ التحذيرات المتبقية تتطلب bindings أو drivers vendor أو اختبار عتادي.

## بوابات الانتقال

| البوابة | الحالة | الدليل المطلوب للانتقال |
|---|---|---|
| P1-C0 — تهيئة | ناجحة | `olddefconfig` و`modpost` مع `SPMI_MSM_PMIC_ARB=y`. |
| P1-C1 — static DT | ناجحة | DTB/DTBO/merged-DTB قابلة للقراءة وتلتزم بالميزانية المشددة. |
| P1-C2 — KMI/DLKM | محجوبة | KMI baseline لـmarble و`Module.symvers` hermetic ووحدات 6.18 معاد بناؤها. |
| P1-B1 — PMIC probe | محجوبة | سجل POCO F5 فعلي: تعداد SPMI، PMIC children، ADC، وغياب panic أو deferred probe غير منتهٍ. |

لا يفتح نجاح P1-C0/P1-C1 بوابة تغليف أو تفليش. تبقى وحدات Evolution X 17 ذات ABI 5.10 غير قابلة للاستخدام مع هذا المخرج 6.18.

## المراجع

[1]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"
[2]: https://docs.kernel.org/devicetree/usage-model.html "Linux and the Devicetree"
