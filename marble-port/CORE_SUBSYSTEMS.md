# Core subsystem path map for marble

## Phase scope

This file documents the status of storage, power, and connectivity paths after a static Device Tree build. The `upstream-present` status means ACK 6.18 contains a definition or binding of the same name; it does not mean the device works until nodes, settings, and firmware are matched to the hardware.

| Path | Core marble compatibles | ACK 6.18 status | Xiaomi 5.10 reference when needed | Current decision |
|---|---|---|---|---|
| UFS storage | `qcom,ufshc`, `qcom,sm8450-ufshc` | `upstream-present` in `drivers/ufs/host/ufs-qcom.c` | Reference UFS tree for platform-specific details | Adapt nodes and settings first; do not copy the entire UFS driver before comparing its interfaces. |
| USB and EUSB2/QMP | `qcom,dwc-usb3-msm`, `qcom,usb-snps-eusb2-phy`, `qcom,usb-ssphy-qmp-dp-combo` | `vendor-gap` for exact compatibles; the generic DWC3 core exists | `dwc3-msm-core.c`, `phy-msm-snps-eusb2.c`, `phy-msm-ssusb-qmp.c` | Requires a driver port or adaptation to the ACK interface, and is not ready for flashing. |
| PCIe | `qcom,pci-msm` | `vendor-gap` for the exact compatible | `drivers/pci/controller/pci-msm.c` | Deferred until after UFS/USB boot. |
| RPMh and core power | `qcom,rpmh-rsc` | `upstream-present` in `drivers/soc/qcom/rpmh-rsc.c` | Xiaomi node reference | Keep to ACK, then verify clocks and interconnect. |
| VRM/ARC regulators | `qcom,rpmh-vrm-regulator`, `qcom,rpmh-arc-regulator` | `vendor-gap` for exact compatibles | `drivers/regulator/rpmh-regulator.c` | Needs regulator interface and Kconfig porting before power testing. |
| PM8008 | `qcom,pm8008-regulator` | `vendor-gap` for the exact compatible | `drivers/regulator/qcom_pm8008-regulator.c` | Requires a driver port before ensuring the board’s electrical initialization. |
| Bluetooth/WLAN | `qcom,qca6490` | `vendor-gap` | `drivers/bluetooth/btpower.c`; full WLAN source not included within the kernel reference | Blocked on vendor modules, firmware, and CNSS documentation. |
| PMIC GLINK | `qcom,pmic-glink` | `upstream-present` in `drivers/soc/qcom/pmic_glink.c` | Xiaomi node reference | Needs Kconfig verification and the firmware message path on actual hardware. |

## Porting rule

> It is forbidden to copy any driver from 5.10 directly to 6.18 just because the `compatible` matches. First compare the API, Kconfig, and clock/regulator/interconnect/KMI interfaces, then create buildable patches and review them on their own.

## Next priority

The minimal boot phase starts by bringing up UFS, RPMh, PMIC/regulator, and serial. USB, PCIe, Bluetooth/WLAN, and the modem interface remain unfit for functional testing until their drivers are ported or an equivalent ACK alternative is proven.
