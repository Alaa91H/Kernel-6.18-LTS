# تفعيل P0 upstream لـmarble 6.18

## القرار والنطاق

يفعل fragment `marble_gki_6_18_core.config` طبقة P0 صغيرة من drivers الموجودة في ACK 6.18، بعد التحقق من وجود عقد Device Tree مطابقة مباشرة في `cape.dtsi`. هذه ليست عملية نسخ لوحدات Evolution X 17/5.10، ولا تضع وحدة في `vendor_boot` أو `vendor_dlkm`، ولا تفتح بوابة تغليف أو تفليش.

> الهدف هو تهيئة لبنات IPC والذاكرة المشتركة التي تحتاجها مسارات Qualcomm التالية، ثم قياس البناء والـKMI والجهاز قبل إضافة أي driver إضافي.

| الرمز | عقدة marble التي تستعمله | driver/binding ACK 6.18 | سبب التفعيل |
|---|---|---|---|
| `CONFIG_QCOM_IPCC=y` | `qcom,ipcc@ed18000` مع `compatible = "qcom,ipcc"` | `drivers/mailbox/qcom-ipcc.c` و`qcom-ipcc.yaml` | mailbox وinterrupt controller لمسارات ADSP/CDSP/modem/AOSS. |
| `CONFIG_HWSPINLOCK_QCOM=y` | `hwlock` مع `compatible = "qcom,tcsr-mutex"` | `drivers/hwspinlock/qcom_hwspinlock.c` وbinding QCOM | dependency حقيقية للـSMEM. |
| `CONFIG_QCOM_SMEM=y` | `qcom,smem` مع `memory-region = <&smem_mem>` و`hwlocks` | `drivers/soc/qcom/smem.c` | إدارة الذاكرة المشتركة بين المعالجات. |
| `CONFIG_QCOM_SMP2P=y` | عقد `qcom,smp2p-*` المرتبطة بـIPCC وSMEM | `drivers/soc/qcom/smp2p.c` | حالة/إشارات point-to-point بين APSS والـsubsystems. |

نجح `tools/validate_marble_core_config.sh` بعد الدمج مع `olddefconfig` وأثبت تفعيل 15 رمزاً أساسياً. تعتمد `QCOM_SMEM` على `HWSPINLOCK`، وتختار `QCOM_SMP2P` حالة SMEM وIRQ domain؛ لذا تفعّل العناصر بالترتيب نفسه في fragment واحد.

## ما لم يُفعل عمداً

لا تملك عقد `qcom,waipio-aoss-qmp` و`qcom,waipio-llcc` تطابقاً مباشراً مثبتاً في drivers/bindings ACK 6.18 الحالية، ولذلك لم تُفعل `QCOM_AOSS_QMP` أو `QCOM_LLCC` لمجرد تشابه الاسم. كما أن drivers `remoteproc` العامة لا تطابق تلقائياً compatibles `qcom,cape-*-pas` الخاصة بالمورّد.

تبقى الوحدات المرجعية ذات 5.10 غير قابلة للاستخدام، وتبين `evolutionx17_module_porting_contract.tsv` أن 84 اسماً فقط يملك مرشح مصدر ACK، بينما 235 اسمًا لا يظهر إلا في المرجع و55 اسماً غير مربوط بمصدر Makefile. كل مرشح ما زال يتطلب مراجعة bindings وKMI وfirmware واختبار جهاز قبل stage DLKM.

## بوابات الانتقال

| البوابة | الدليل المطلوب |
|---|---|
| C0 | fragment يحل إلى `y` في `.config`، و`olddefconfig` و`modpost` ينجحان. |
| C1 | Image وmodules وDTB/DTBO تبنى لكل نكهة بلا regression في ميزانية DTC. |
| C2 | قائمة KMI و`Module.symvers` من بيئة ACK hermetic؛ لا رمز vendor خارج allowlist. |
| B1 | IPCC/SMEM/SMP2P probe في POCO F5، مع `dmesg` وpstore وبدون SSR أو panic. |

**الحالة الحالية:** C0 فقط ناجحة. C1–B1 لم تُدّعَ بعد، و`--package boot` يبقى محجوباً.

## المراجع

[1]: https://source.android.com/docs/core/architecture/kernel/modules "AOSP — Kernel modules overview"
[2]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"
[3]: https://source.android.com/docs/core/architecture/kernel/android-common "AOSP — Android common kernels"
