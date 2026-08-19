# سجل عمل نقل marble إلى GKI 6.18

## حالات العمل

| الحالة | المعنى |
|---|---|
| `blocked` | لا يمكن البدء تقنياً قبل إغلاق اعتماد محدد. |
| `researched` | المرجع والاعتمادات موثقة، لكن لا توجد رقعة نقل. |
| `in-progress` | توجد رقعة صغيرة قيد البناء أو المراجعة. |
| `static-validated` | اجتازت الرقعة البناء والفحوص الثابتة فقط. |
| `hardware-validated` | ثبتت على POCO F5 بسجل إقلاع أو اختبار وظيفي. |

## بنية Device Tree والمنصة

| المعرّف | المهمة الذرية | الحالة | الاعتمادات | معيار القبول |
|---|---|---|---|---|
| DT-001 | تكييف 15 binding مفقوداً في ACK أو تحديد بدائل upstream لها. | `static-validated` | headers منقولة من Xiaomi وسجل `marble_dt_bindings_imported.tsv`. | 30 تضميناً خارجياً موجودة نصياً؛ تحقق providers يؤجل إلى DT-002/DT-003. |
| DT-002 | نقل قاعدة `ukee.dtb` و`ukee.dtsi` وطبقة SoC cape/SM7475. | `in-progress` | DT-001 وطبقة Qualcomm L1. | DTB أساسي يترجم بلا labels أو phandles مكسورة. |
| DT-003 | نقل reserved-memory وIOMMU وinterconnect وclocks للمنصة. | `blocked` | DT-002. | تحقق `dtbs_check` الخاص بالرقع ووجود العقد المرجعية. |
| DT-004 | نقل `marble-sm7475.dtsi` و`marble-pinctrl.dtsi`. | `blocked` | DT-002 وDT-003. | دمج اللوحة يترجم فوق قاعدة ukee. |
| DT-005 | نقل overlay `marble-sm7475-pm8008-overlay.dts`. | `blocked` | DT-004 وPMIC/regulator. | DTBO يترجم ويُعلن توافقه مع `ukee.dtb`. |

## إعدادات النواة والوحدات

| المعرّف | المهمة الذرية | الحالة | الاعتمادات | معيار القبول |
|---|---|---|---|---|
| KC-001 | مراجعة 124 رمز Kconfig موجوداً اسمياً في ACK. | `researched` | `marble_gki_config_present.tsv`. | لكل رمز قرار تمكين أو تعطيل مع سبب. |
| KC-002 | تصنيف 305 رموز مفقودة إلى بديل upstream أو رقعة نقل أو غير مدعوم. | `researched` | `marble_gki_config_missing_categories.tsv`. | لا تبقى رموز مفعلة من دون قرار موثق. |
| MOD-001 | فصل 111 وحدة مرجعية إلى أساس إقلاع، vendor، وتشخيص. | `researched` | `marble_module_categories.tsv`. | قائمة وحدات دنيا قابلة للبناء دون vendor-only APIs. |
| MOD-002 | إعادة بناء وحدات المنصة الأساسية وفق KMI/BTF النهائي. | `blocked` | KC-001 وKC-002 وDT-002. | تحميل الوحدات على جهاز الاختبار بلا رموز غير محلولة. |

## المسارات الوظيفية

| المعرّف | المسار | الحالة | الاعتمادات الدنيا | دليل القبول |
|---|---|---|---|---|
| BOOT-001 | UFS وUSB وserial وreboot reason | `blocked` | DT-002، DT-003، MOD-001. | سجل إقلاع واسترداد فعلي. |
| PWR-001 | PMIC وregulator وRPMh وthermal | `blocked` | DT-002، DT-005، KC-002. | تعليق/استئناف وشحن بلا kernel panic. |
| NET-001 | Wi-Fi/BT/CNSS وQRTR/modem | `blocked` | BOOT-001، وحدات vendor، firmware. | اختبار اتصال وسجل modem. |
| UI-001 | display وtouch وGPU | `blocked` | PWR-001، DT-004، تعريفات العرض/Adreno. | شاشة ورسوميات تعملان على الجهاز. |
| MEDIA-001 | audio وDSP والكاميرا | `blocked` | NET-001 وUI-001 وتعريفات vendor. | اختبار صوت وكاميرا متكرر. |

> عناصر `blocked` ليست مهملة: تعني أن ترتيب الاعتماد يمنع إنتاج رقعة مضللة قبل أن يصبح أساس المنصة قابلاً للبناء والتحقق.
