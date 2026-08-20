# Evolution X 17 Integration Baseline for marble

**Status:** Device source trees fixed and complete; official ROM binary artifact intake is still pending, therefore creation of `boot.img` or `vendor_boot.img` or flashing any output is **prohibited**. This document is not a boot compatibility approval.

## Scope of the baseline

This baseline targets the POCO F5 / Redmi Note 12 Turbo (`marble`) device and the Evolution X 12.1 release built on Android 17. The official device page lists `marble` among Android 17 devices, and the official ROM link recorded in the discovery report is treated as an unprocessed intake until fingerprint and contents verification are completed.[1]

| Baseline item | Anchored source | Commit / version | Purpose |
|---|---|---:|---|
| Evolution X device tree | `Evolution-X-Devices/device_xiaomi_marble` | `a8d866758688862bcff9c5d9b2ff3ba00fc9b549`, 2026-06-25 | Device definition and `marble` properties. |
| Common tree | `Evolution-X-Devices/device_xiaomi_sm8450-common` | `b73b209ae0ec6858a03117e89b4705174bd1fcac`, 2026-06-29 | Hosts boot images, DLKM and VINTF. |
| Reference kernel source | `Evolution-X-Devices/kernel_xiaomi_sm8450` | `e8fcf25587112c854814dbe399a99110d18c82de`, 2026-07-03 | Reference vendor 5.10 configuration and module lists; not a source to mix with 6.18. |
| Published legacy 5.10 artefacts | `Evolution-X-Devices/device_xiaomi_marble-kernel` | `03dda81f521cf7ab016ef8558b3f9d67d0fdaf79`, 2024-03-19 | Historical reference for DLKM builds only; not an ABI reference for Evolution X 17. |
| Local 6.18 candidate | `android17-6.18-lts` at `4e44babe3f67` | Linux 6.18.32 | Public kernel under test. |

> ABI rule: 5.10 vendor binaries must not be loaded, copied, signed, or packaged with the 6.18 kernel. Name matching does not prove ABI or KMI compatibility.

## Extracted Evolution X vendor contracts

The `marble` tree imports the `sm8450-common` tree. Its configuration sets `TARGET_KERNEL_SOURCE := kernel/xiaomi/sm8450` with `gki_defconfig` and fragments `waipio_GKI.config`, `xiaomi_GKI.config`, `marble_GKI.config` and `debugfs.config`.[2] This indicates the current Evolution X target is centered on the Qualcomm/Xiaomi vendor 5.10 definition set, not on the Android Common Kernel 6.18.

| Area | Declared Evolution X contracts | Impact on the public 6.18 |
|---|---|---|
| Boot | Boot header v4, `Image`, and DTB embedded in boot. | The actual `boot.img` must be extracted to verify page size, ramdisk and cmdline; guessing is not permitted. |
| Device Tree | GKI enabled, QCOM DTBs merged, and `TARGET_NEEDS_DTBOIMAGE := true`. | The real `dtbo.img` must be compared with the DTBO built for marble after ROM intake. |
| A/B | OTA list includes: `boot` and `dtbo` and `vendor_boot` and `vendor_dlkm` in addition to dynamic partitions. | Requires a consistent image inventory from the **same build** before any packaging. |
| vendor ramdisk | fragment named `dlkm`; two-stage loading lists. | First-stage modules are required for boot and cannot be swapped with 5.10 modules when testing 6.18. |
| vendor DLKM | `vendor_dlkm` ext4 and a private module list. | 6.18 alternatives require source-built replacements or freezing the public kernel until a compatible vendor layer is available. |
| AVB | AVB enabled and separate vbmeta system. | No keys or complete acceptance policy available; packaging remains rejected. |

## Static audit result

`tools/audit_evolutionx17_kernel_contract.sh` was run against the `marble-aosp-diagnostic-none` output and performed a configuration/name-only comparison. The `marble_GKI.config` and `waipio_GKI.config` configurations from the Evolution X 5.10.256 reference were used, then compared to the candidate 6.18 `.config`. This audit does not translate differences into automatic enable requests because vendor symbols may not exist at all in the Android Common Kernel 6.18.

| Metric | Result | Correct interpretation |
|---|---:|---|
| Active 5.10 reference symbols | 344 | Historical / reference vendor capability contracts. |
| Symbols appearing enabled in the 6.18 candidate | 9 | Not evidence of hardware parity. |
| Missing or disabled symbols in nominal comparison | 335 | Expected gaps between the Qualcomm/Xiaomi 5.10 tree and ACK 6.18; real porting or upstream alternatives required. |
| Unique first-stage modules in the reference | 97 | Depend on 5.10 vendor ABI and interfaces. |
| Unique `.ko` files built in the 6.18 candidate | 104 | ACK public outputs and not a nominal replacement for the reference modules. |
| First-stage module name collisions | 0 | Not evidence of a packaging bug; rather confirmation that binary substitution is invalid. |

The prominent families of gaps are Qualcomm clocks/interconnect/RPMh, UFS and USB PHY, CNSS/WLAN, display/KGSL/camera/audio, DSP/ADSP and IPA/MHI, power and thermal and touch input. This result aligns with the general vendor-gap audit in `MEDIA_VENDOR_GAPS.md`, and shifts the test gate from “Image build” to “vendor branch porting or upstream support verification”.

## Official ROM artefact and its intake state

The official ROM intake is defined in `manifests/evolutionx-17.env.example` and in `reports/evolutionx17_source_discovery.md`. The repository does not store the ROM, extracted images, firmware, or AVB keys. After download completes, the intake steps are strictly as follows:

| Gate | Required evidence | Eligibility decision |
|---|---|---|
| I0 — ZIP integrity | Expected size, local SHA-256 and `unzip -t`. | Failure stops analysis. |
| I1 — image inventory | Names, sizes and fingerprints of `boot`, `vendor_boot`, `dtbo`, `vendor_dlkm` and `system_dlkm` if present. | No packaging before completion. |
| I2 — identity | fingerprint and build ID and build date and AVB from the build itself. | Populates a manifest outside Git. |
| I3 — ABI/DT | kernel version, vermagic, modules lists, overlays and DTB/DTBO. | No name-only match is accepted instead of ABI. |
| I4 — device | Recovery and boot and logging and recovery proof from a real POCO F5. | The only gate that allows updating the device acceptance state. |

## Current integration decision

There is no established binary compatibility between the reference Evolution X 17 5.10.256 and the public kernel 6.18.32. The 6.18 kernel remains a research/porting public kernel suitable for reproducible builds, while the Evolution X target either needs vendor definitions and sources ported to 6.18 with matching KMI/DT/firmware, or documented upstream alternatives for every critical hardware path. Reference 5.10 modules will not be included in any 6.18 output.

There is a small consistency gap to be addressed at flavor setup time: the manifest template carries `ROM_FLAVOR=evolutionx-17`, while the `--flavor` accept list in the current build script is limited to `aosp|xiaomi`. Changing the acceptance to include `evolutionx-17` is a metadata-only modification and will be implemented with an independent build test after intake and analysis gates are completed, without lifting the packaging prohibition.

## References

[1]: https://evolution-x.org/devices/marble "Evolution X official page for marble"
[2]: https://github.com/Evolution-X-Devices/device_xiaomi_sm8450-common/blob/main/BoardConfigCommon.mk "Evolution X sm8450-common BoardConfigCommon.mk"
[3]: https://github.com/Evolution-X-Devices/device_xiaomi_marble "Evolution X marble device tree"
[4]: https://github.com/Evolution-X-Devices/kernel_xiaomi_sm8450 "Evolution X Xiaomi SM8450 kernel source"
[5]: https://github.com/Evolution-X-Devices/device_xiaomi_marble-kernel "Evolution X marble kernel artefact tree"
