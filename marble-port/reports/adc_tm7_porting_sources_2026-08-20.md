# ADC_TM7 Porting Sources and Notes — 20 August 2026

## External sources

| Source | Reference | Files or purpose |
|---|---|---|
| [MiCode Xiaomi Kernel OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss) | Branch `marble-s-oss`, local checked-out commit `48952ed36228217531482b39d5bef13e7fd808ec` | Reference marble 5.10 source. Provides `drivers/thermal/qcom/{adc-tm.c,adc-tm-common.c,adc-tm5.c,adc-tm7.c}` and `CONFIG_QTI_ADC_TM`. |
| [LineageOS android_kernel_xiaomi_sm8450](https://github.com/LineageOS/android_kernel_xiaomi_sm8450/tree/lineage-23.2) | Branch `lineage-23.2` | Newer comparison-only reference; contains the same ADC_TM family and the interfaces `qpnp-revid.h` and `adc-tm-clients.h`. Not relied upon as an automatic source for the patch. |

## Preliminary inventory results

The Xiaomi 5.10 tree uses `CONFIG_QTI_ADC_TM=m` and builds the module `qti-adc-tm.o` from four implementation files: `adc-tm.c`, `adc-tm-common.c`, `adc-tm5.c`, and `adc-tm7.c`. The reference stack depends on two vendor interfaces not present in the current 6.18 tree: `linux/qpnp/qpnp-revid.h` and `linux/adc-tm-clients.h`.

The current 6.18 tree includes the driver `qcom-spmi-adc-tm5.c`. It already contains an `ADC_TM5_GEN2` path with a register map very close to ADC_TM7, but it does not match `qcom,adc-tm7` and cannot probe the target node directly because the current parser requires child channel nodes. The `pmk8350_adc_tm` node in marble declares `qcom,adc-tm7` and `reg = <0x3400>` and IRQ and `#thermal-sensor-cells = <1>` and does not have child channel nodes or a marble override applied yet.

The preliminary conclusion is that adding only the `compatible` to the current driver is unsafe and insufficient. Either a dedicated TM7 path must be added after isolating/moving the required vendor interfaces, or the current driver must be redesigned to support TM7's thermal-sensor index interface with proof of DT and hardware equivalence.
