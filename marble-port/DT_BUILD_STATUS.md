# حالة بناء Device Tree لـ marble

## نتيجة البناء الثابت

نجح بناء أهداف Device Tree التالية باستخدام LLVM وإعداد GKI arm64 مع `CONFIG_OF_OVERLAY=y`:

| المخرج | الحجم | SHA-256 | الحالة |
|---|---:|---|---|
| `ukee.dtb` | 379,047 بايت | `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8` | بُني برموز `-@` اللازمة للـoverlay. |
| `marble-sm7475-pm8008-overlay.dtbo` | 68,799 بايت | `5c73e0d1f6ee5ee5fbb5ba4cf9ac61a77c494bdfcd02d31c3170c3e956fd3e62` | بُني بنجاح. |
| `ukee-marble-merged.dtb` | 427,762 بايت | `2b7970d274d6f61131f1a32e49ca7d366d67cc84310580be33ee48d7986a7d67` | ناتج تطبيق الـDTBO بنجاح عبر `fdtoverlay`. |

يمكن إعادة إنتاج النتيجة عبر:

```bash
./tools/build_marble_dt.sh
```

## تحذيرات DTC المتبقية

نجح البناء مع **130 تحذيراً**. هذه التحذيرات ليست أخطاء تجميع، لكنها تمنع رفع الحالة إلى `hardware-validated` أو إنشاء حزمة تفليش.

| فئة التحذير | العدد | ملاحظة المعالجة |
|---|---:|---|
| `unit_address_vs_reg` | 75 | يلزم تطبيع عناوين عقد المنصة المنقولة مع قيمة `reg`. |
| `avoid_default_addr_size` | 16 | يلزم ضبط خلايا العنوان/الحجم صراحة في العقد المنقولة. |
| `interrupt_map` | 10 | يلزم مراجعة خلايا العنوان لعقد GIC/PCIe المنقولة. |
| `reg_format` | 7 | يلزم مراجعة تنسيق `reg` بعد تكييف خلايا العنوان للمنصة. |
| `ranges_format` و`simple_bus_reg` | 5 | ناتجة عن إعدادات الناقل والعناوين في cape. |
| `graph_child_address` | 3 | يلزم تطبيع عقد graph ذات الطفل المفرد. |
| `pci_device_reg` و`pci_device_bus_num` و`i2c_bus_reg` و`spi_bus_reg` | 8 | تحذيرات تابعة لمشكلات `reg_format`. |
| `avoid_unnecessary_addr_size` و`unique_unit_address` و`unit_address_format` | 6 | يلزم تطبيع تعريفات العقد والعناوين. |

## الاستنتاج

هذه المرحلة تحقق **بناءً ثابتاً** للـDTB والـDTBO ولعملية دمجهما، لا تحقق إقلاعاً. استُوردت 29 ملفاً غير متعارض من الإغلاق المرجعي، وتكيّفت 7 ملفات PMIC متعارضة من مرجع Xiaomi لأن رموز overlay المطلوبة لا توجد في ACK. تبقى معالجة التحذيرات، ومطابقة drivers وclock providers، وسجل الإقلاع الفعلي شروطاً لازمة قبل أي تفليش.
