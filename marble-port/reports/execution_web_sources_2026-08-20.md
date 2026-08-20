# Public Sources Register — 20 August 2026

## Android Open Source Project: Device tree overlays

Source: <https://source.android.com/docs/core/architecture/dto>

The AOSP document confirms that the Device Tree describes non-discoverable hardware, and that vendors provide DTS that are compiled to DTB by `dtc`. It also describes DTO as an overlay applied over a central DTB by the bootloader, and that the actual boot process includes building the DTB and placing it in a trusted location accessible to the bootloader and then loading it into memory. This supports relying in this round on building the DTB and DTBO and merging them and inspecting the result, rather than treating DTBO alone as sufficient evidence.

## Qualcomm Linux documentation

Source: <https://docs.qualcomm.com/doc/80-70018-3/topic/getting_started_chapter2.html>

The page did not provide technically readable content in this environment; it was limited to a cookie consent screen. Therefore it is not used as evidence of SPSS/GLINK or ADC encoding, and does not justify any modification to the targeted nodes.

## Usage decision

Neither of the above sources replaces the binding or the Qualcomm driver source matching `marble` for ADC5 or SPSS nodes. These references remain required inputs before modifying those nodes.

## Pinned Xiaomi references

| Reference | Branch | Pinned commit | Purpose |
|---|---|---|---|
| <https://github.com/MiCode/kernel_devicetree> | `marble-s-oss` | `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` | DTS/DTSI/DTBO reference for Redmi Note 12 Turbo / POCO F5; used to check include closure and compare moved marble files. |
| <https://github.com/MiCode/Xiaomi_Kernel_OpenSource> | `marble-s-oss` | `48952ed36228217531482b39d5bef13e7fd808ec` | Xiaomi Kernel 5.10 reference; used to inventory `marble_GKI.config` and `modules.list.msm.marble`. |

The include-closure check against the Device Tree reference succeeded; it counted 36 locally included files and 30 external `dt-bindings` headers, and all thirty headers were present in the current ACK tree. The 5.10 reference inventory showed 429 Kconfig requests, of which 124 symbols are available by name in ACK and 305 are a gap needing review or porting; it also enumerated 111 referenced modules. These numbers describe the porting gap and do not constitute authorization to enable symbols automatically.

## SPSS/GLINK verification

An initial search in ACK 6.18 source showed that `drivers/remoteproc/qcom_common.c` requests a child named `glink-edge`. That alone does not prove the encoding of `qcom,spss-addr` or `qcom,spss-size`, and therefore is not a justification for modifying the `reg` or `ranges` cells of the SPSS node.
