# Marble Device Enablement Source Register

## Purpose and scope

This register identifies the external source material that must be reconciled before this repository can carry device-specific Marble enablement. It is a **source-admission record**, not a device-support claim and not a flashing guide. The current repository remains a host-side ACK/GKI 6.18 source-build prototype.

> A device file is not admitted merely because it exists in a public repository. It must have an immutable, reviewable source revision and a demonstrated match to the Android, vendor, KMI/ABI, boot-chain, firmware, and recovery contract that will consume it.

## Observed public sources

| Source | Observed contract | What it contributes | Admission decision for this ACK/GKI 6.18 tree |
|---|---|---|---|
| [Xiaomi Kernel Open Source `marble-s-oss`][1] | The source `Makefile` identifies Linux **5.10.117**. Its `build.config.msm.marble` records a Marble build variant using boot-header v3, vendor DLKM, DT-overlay support, and a Qualcomm GENI console command line. [2] [3] | Historical Marble vendor-kernel source, build configuration, Device Tree, Qualcomm extensions, module lists, and blocklists. | **Do not copy directly.** A 5.10 vendor tree is not source or ABI compatible by assertion with this 6.18 prototype. A port would require a separately reviewed change series and a matching Android/vendor contract. |
| [LineageOS Marble device tree `lineage-23.2`][4] | The device `BoardConfig.mk` inherits `device/xiaomi/sm8450-common` and `vendor/xiaomi/marble`; its current vendor security patch variable is 2026-02-01. [5] | Product properties, overlays, init configuration, audio data, product manifests, and a declaration of proprietary-file inputs. | **Do not treat as a kernel-board drop-in.** It is part of a Lineage product tree and requires its paired common and proprietary vendor trees. |
| [LineageOS SM8450 common tree `lineage-23.2`][6] | The common board configuration points to `kernel/xiaomi/sm8450`, supplies several vendor GKI configuration fragments and external-module paths, requires vendor-ramdisk/vendor-DLKM module loading, and specifies boot-header v4. [7] | Android product integration assumptions, module placement, partition expectations, VINTF, sepolicy, and framework interfaces. | **Do not combine with Xiaomi Marble 5.10 settings or ACK 6.18.** The documented boot-header and module contract differs from Xiaomi Marble OSS and needs a complete paired manifest. |
| [LineageOS Marble build guide][8] | The guide obtains device-specific sources through the Lineage manifest and requires proprietary blobs from a matching running device or installable zip. [8] | A reference process for assembling a complete Android product source checkout. | **Reference only.** It confirms that a kernel checkout alone cannot establish a flashable product. |

## Required admission evidence

A future proposed Marble file or driver must supply every item below before it may be represented as device enablement.

| Evidence class | Minimum reviewable input |
|---|---|
| Immutable source identity | Upstream repository URL, branch/tag, full commit SHA, license, and provenance or published checksum. |
| Android/vendor match | Exact Android/ROM manifest revision, security-patch level, `vendor` and `vendor_dlkm` build identity, and an explanation of which component consumes the file. |
| Kernel interface match | Kernel version, GKI/KMI/ABI compatibility evidence, expected module symbol versions, compiler/toolchain conditions, and all required configuration fragments. |
| Hardware description | Reviewed Marble Device Tree and overlays with binding validation, along with a clear split between generic upstream nodes and vendor-specific nodes. |
| Boot and recovery contract | Boot-header version, partition layout, AVB policy, DTBO rules, a tested recovery/rollback path, and no dependence on unreviewed partition assumptions. |
| Firmware and functional validation | Versioned firmware inventory plus reproducible boot logs and functional tests for each claimed peripheral. |

## Current non-admission boundary

No source currently recorded here establishes a version-matched Marble device contract for ACK/GKI 6.18. Accordingly, this repository does **not** publish or generate `boot.img`, `vendor_boot.img`, DTBO images, modules, firmware, recovery images, root integrations, or flashing scripts. The repository must not describe generic configuration symbols, historical vendor source, or Lineage product files as completed Marble support.

## How to propose a future import

A proposal should first create an evidence record that maps every imported path to an immutable source revision and the required admission evidence above. The change must then be reviewed in isolated, logically grouped patches; validate the relevant Kconfig, Device Tree, and module interfaces; build against the exact Android/vendor contract; and provide device test and recovery evidence before any device-oriented release claim.

## References

[1]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss "Xiaomi Kernel Open Source — marble-s-oss"
[2]: https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/marble-s-oss/Makefile "Xiaomi Marble source Makefile"
[3]: https://raw.githubusercontent.com/MiCode/Xiaomi_Kernel_OpenSource/marble-s-oss/build.config.msm.marble "Xiaomi Marble build configuration"
[4]: https://github.com/LineageOS/android_device_xiaomi_marble/tree/lineage-23.2 "LineageOS Marble device tree"
[5]: https://raw.githubusercontent.com/LineageOS/android_device_xiaomi_marble/lineage-23.2/BoardConfig.mk "LineageOS Marble BoardConfig"
[6]: https://github.com/LineageOS/android_device_xiaomi_sm8450-common/tree/lineage-23.2 "LineageOS SM8450 common device tree"
[7]: https://raw.githubusercontent.com/LineageOS/android_device_xiaomi_sm8450-common/lineage-23.2/BoardConfigCommon.mk "LineageOS SM8450 common BoardConfig"
[8]: https://wiki.lineageos.org/devices/marble/build/variant1/ "LineageOS Marble build guide"
