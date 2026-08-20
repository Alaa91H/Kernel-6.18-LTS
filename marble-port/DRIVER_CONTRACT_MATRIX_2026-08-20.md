# Priority Contract Compatibility Matrix — marble

**Date:** 20 August 2026
**Analysis tree:** `marble-6.18-full-port` at `32ffe3adde922d2b927c4849af186317d9dd8643`
**Xiaomi Kernel reference:** `marble-s-oss` at `48952ed36228217531482b39d5bef13e7fd808ec` [1]
**Xiaomi Device Tree reference:** `marble-s-oss` at `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` [2]

## Executive Summary

This matrix documents the three contracts that combine a real Device Tree node and Kconfig/module gaps in the Xiaomi reference. A `compatible` match alone does not equal device readiness; a proper driver, an enabled configuration, ABI/firmware integrity, and hardware testing are also required.

| Contract/Path | Ported DT node | driver or binding in 6.18 | Built AOSP config state | Verdict | Action this round |
|---|---|---|---|---|---|
| SPSS + `glink-edge` | `qcom,cape-spss-pas` and child `glink-edge`; the final state of SPSS is `disabled`. | `qcom_common.c` discovers a child named `glink-edge` and runs it via GLINK-SMEM; but there is no driver matching `qcom,cape-spss-pas` in the current tree. | `RPMSG_QCOM_GLINK` is missing from AOSP config; vendor symbol `QCOM_SPSS` is missing from ACK. | **Blocked.** | No change to `reg` or `ranges` or `reg-names` and do not enable the config. |
| Standard GLINK-SMEM | node includes `qcom,remote-pid` and IRQ and mailbox. | `qcom_glink_smem_register()` reads `qcom,remote-pid` then IRQ and mailbox; it does not establish the meaning of `qcom,spss-addr`/`qcom,spss-size`. | `RPMSG_QCOM_GLINK_RPM` and `RPMSG_QCOM_GLINK_SMEM` are not enabled. | **No automatic alternative.** | A port of the matching SPSS/GLINK driver and then device testing are required. |
| VADC7 | PMIC node uses `compatible = "qcom,spmi-adc7"`. | `qcom-spmi-adc5.c` in 6.18 matches `qcom,spmi-adc7`. | `CONFIG_QCOM_SPMI_ADC5=y`. | **Statically supported.** | No change; IIO verification on the device remains required. |
| ADC_TM7 | PMIC node uses `compatible = "qcom,adc-tm7"`. | The current binding lists it as 'incomplete/subject to change', while the 6.18 driver does not include a match for `qcom,adc-tm7`. | `CONFIG_QCOM_SPMI_ADC_TM5=y`, while Xiaomi symbol `QTI_ADC_TM` is missing. | **Blocked.** | Do not rename to TM5 nor add properties to bypass the check. |
| UFS controller | `ufshc@1d84000` with `compatible = "qcom,ufshc"`. | `ufs-qcom.c` matches `qcom,ufshc`. | `SCSI_UFSHCD=y` and `SCSI_UFSHCD_PLATFORM=y` and `SCSI_UFS_QCOM=y` and `SCSI_UFS_CRYPTO=y`. | **Statically supported.** | No change; UFS/ICE and vendor ABI verification on the device are required. |
| UFS QMP PHY | UFS node refers to `ufsphy_mem`. | The QMP-UFS driver includes matches for SM8450/SM8475, and `PHY_QCOM_QMP_UFS=y` is set. | Enabled in the AOSP build. | **Statically supported, but not hardware-tested.** | Do not replace the PHY or tune values. |

## Compatibility evidence and blockers

### SPSS and GLINK

The current path in `qcom_common.c` literally looks for a child named `glink-edge`, then passes it to `qcom_glink_smem_register()`. This path reads `qcom,remote-pid` and IRQ and mailbox, and therefore explains why it is not acceptable to use it as evidence for the paired `reg` properties named `qcom,spss-addr` and `qcom,spss-size`. `compatible = "qcom,cape-spss-pas"` remains without a matching driver in the tree, and the Xiaomi 5.10 reference requires `CONFIG_QCOM_SPSS` and `CONFIG_RPMSG_QCOM_GLINK_SPSS`, both of which are not available by those names in ACK.

> Conclusion: Enabling standard GLINK or removing SPSS properties to silence the DTC warning will change a vendor node before proving that matching remoteproc and firmware exist. Therefore this is forbidden at this stage.

### ADC7 and ADC_TM7

The current ADC driver supports `qcom,spmi-adc7` under `CONFIG_QCOM_SPMI_ADC5=y`, which is a direct static match. In contrast, the ported DT uses `qcom,adc-tm7` while the Xiaomi 5.10 source provides path `CONFIG_QTI_ADC_TM` and files `adc-tm7.o`, whereas the 6.18 tree includes a binding that explicitly warns that the `qcom,adc-tm7` compatibility is incomplete and subject to change. There is no corresponding driver match in 6.18.

> Result: It is not permitted to change `qcom,adc-tm7` to `qcom,spmi-adc-tm5` or `qcom,spmi-adc-tm5-gen2`; this would replace a hardware/driver contract without proof of calibration or thresholds.

### UFS

The controller has a direct match with `ufs-qcom.c` and the basic UFS settings and QMP PHY are enabled in the AOSP output. However, the Xiaomi reference contains additional modules such as `ufshcd-crypto-qti.ko` and `phy-qcom-ufs-qmp-v4-cape.ko` — ABI/ICE equivalence for those cannot be inferred from a successful kernel build. A single ROM manifest and compatible vendor modules are required before any experimental boot.

## Result and change implemented

No C, Kconfig or DTS source modifications were added in this stage. The implemented change is the installation of the decision matrix to prevent automatic porting of vendor settings or renaming of Device Tree nodes. The contracts safe for static verification later are UFS and VADC7; SPSS/GLINK and ADC_TM7 require a matching driver/firmware source and hardware testing.

## References

[1]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss "MiCode Xiaomi Kernel OpenSource — marble-s-oss"
[2]: https://github.com/MiCode/kernel_devicetree/tree/marble-s-oss "MiCode kernel_devicetree — marble-s-oss"
[3]: https://source.android.com/docs/core/architecture/dto "Android Open Source Project — Device tree overlays"
