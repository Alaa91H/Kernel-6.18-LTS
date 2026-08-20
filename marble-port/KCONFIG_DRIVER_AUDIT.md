# Kconfig, Definitions, and Firmware Audit for marble

## Inventory results

The baseline report compares 429 configuration requests from the Xiaomi 5.10 reference against the Android Common Kernel 6.18. 124 symbols exist by name in the ACK, while 305 symbols are absent from it. A name match does not mean the driver, binding, or ABI is compatible with SM7475; and a missing name does not mean the path cannot be ported—it indicates work required beyond Kconfig enablement.

| Area | Finding | Decision |
|---|---|---|
| UFS | `SCSI_UFS_QCOM` exists and is enabled; `PHY_QCOM_QMP_UFS` exists in ACK but the current DT compatible `qcom,ufs-phy-qmp-v4-cape` is not present. | Do not enable an alternative PHY before adapting the binding and node. |
| USB | `USB_DWC3_QCOM` exists, but the Xiaomi compatible `qcom,dwc-usb3-msm` is not present in ACK. | Do not replace the compatible nor enable a different glue without a documented driver patch. |
| serial/SLIMbus | `SERIAL_QCOM_GENI` and `SLIM_QCOM_NGD_CTRL` exist; Slimbus compatible exists. | Can be evaluated in a separate track after defining the codec/DSP and firmware. |
| DSP/modem | General alternatives such as `QCOM_Q6V5_ADSP`, `QCOM_Q6V5_MSS`, `QRTR_MHI`, and `MHI_BUS` exist, but cape-specific compatibles do not map to them directly. | Gated on runtime adaptation of remoteproc/MHI/firmware. |
| GPU and display | `drivers/gpu/msm` and `techpack/display` are not present in the checkout. | Cannot port KGSL or vendor display without the full source. |
| camera, audio, and vendor WLAN | `techpack/camera`, `techpack/audio`, and `qcacld-3.0` are not present. | There is not enough source base to enable the 5.10 vendor symbols or their modules. |
| board firmware | The DTS references `goodix_firmware_TM.bin`, `goodix_cfg_group_TM.bin`, and `idt9415.bin`. | Firmware source, licensing, and version matching must be included in the device plan; do not create substitute firmware files. |

## Enablement policy

An ACK symbol may be enabled only if all the following conditions are met: the driver and binding exist in ACK, the Device Tree node compatible and subordinate nodes match, the required firmware is available, and there is a runtime test on marble. Symbols similar in name or function are not sufficient, because Linux matches devices by Device Tree data and bindings, not by mere intent to configure.[1]

> 182 of the missing symbols are categorized under Qualcomm/Xiaomi vendor families, including KGSL, CNSS, IPA, WALT, QTI minidump/charger, and USB/MSM legacy. Copying 5.10 configuration to 6.18 or enabling non-existent symbols does not produce a buildable or runnable definition.

## References

[1]: https://docs.kernel.org/devicetree/usage-model.html "Linux and the Devicetree"
