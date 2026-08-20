# Architecture for porting marble to Android/GKI 6.18

## Foundational result

The current ACK 6.18 tree does not contain DTS files or platform definitions named `sm7475` or `cape` or `marble`. Therefore the port cannot begin from the phone overlay alone; it requires first a compatible Qualcomm platform layer, then the SoC definition, then the board layer.

> Do not copy the Xiaomi 5.10 tree verbatim into ACK 6.18. Each layer is added in independent patches with Kconfig, bindings, and the used APIs checked.

## Porting layers and order

| Identifier | Layer | Reference source components | Dependencies | Exit criterion |
|---|---|---|---|---|
| L0 | Infrastructure and tools | ACK, LLVM, BTF, KMI checks | None | Reproducible arm64 build and successful inventory checks. |
| L1 | Qualcomm base | bindings, clocks, reset, interconnect, RPMh, SPMI, SCM, SMEM, IPCC | L0 | Kconfig and DTS bindings compatible with 6.18. |
| L2 | SoC SM7475 | base `ukee.dtb` and cape/Qualcomm files: CPU, GIC, timers, memory map, reserved-memory, Gunyah/remoteproc, UFS, and USB | L1 | A basic platform DTB that compiles and has no broken phandles. |
| L3 | marble board | `marble-sm7475.dtsi` and pinctrl and Xiaomi common and PM8008 overlay on top of `ukee.dtb` | L2 | marble DTBO/DTB compile against the ported SoC. |
| L4 | Boot path | regulator, PMIC, clocks, UFS, USB, serial, reboot reason | L1–L3 | Recovery boot with UART/pstore logs. |
| L5 | Basic interaction | panel, touch, input, battery/charger, sensors | L3–L4 | Stable display, touch, charging, and ADB. |
| L6 | Connectivity and media | Wi‑Fi/BT/CNSS, audio, DSP, modem/QRTR | L1–L5 | Connectivity, audio, and modem tests documented. |
| L7 | Graphics and camera | Adreno/KGSL, display stack, ISP/camera | L1–L6 | Graphics acceleration and cameras within long-running tests. |
| L8 | ROM compatibility | BTF/KMI, vendor DLKM, AVB, boot/vendor_boot/dtbo | L0–L7 | A test package specific to the chosen ROM, not a blind generic package. |

## Dependency interfaces

| Interface | Reference source | Risk in 6.18 | Porting policy |
|---|---|---|---|
| Kconfig | `marble_GKI.config` | 305 symbol references nominally missing from ACK. | Record each symbol as: upstream alternative, a port patch, or unsupported. |
| Device Tree | `kernel_devicetree:marble-s-oss` | 36 local files in the `ukee.dtb` closure and marble overlay, plus 30 external bindings. | Porting begins with bindings, then the SoC, then the board — not the reverse. |
| Modules | `modules.list.msm.marble` | 111 modules, some vendor-only or carrying legacy APIs. | Divide into core/optional/diagnostic/forbidden until KMI confirms. |
| vendor boot chain | the ROM to be tested later | boot header format, AVB, and DLKM differ between ROMs. | Not included in the mainline kernel; implemented on an integration branch for the chosen ROM. |

## Priority order

The mandatory order of work is L1 then L2 then L3 then L4. Do not start porting KGSL or the camera before producing a basic marble DTB and power and storage definitions, because lower-layer errors prevent reliable diagnosis of higher layers.
