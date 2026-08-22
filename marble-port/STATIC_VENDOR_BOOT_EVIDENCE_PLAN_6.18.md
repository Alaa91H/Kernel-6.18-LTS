# Marble 6.18 Static Vendor and Boot Evidence Plan

**Status:** static planning complete; implementation, packaging, and device execution remain blocked

**Scope:** POCO F5 / Redmi Note 12 Turbo (`marble`, SM7475)

**Target:** Android Common Kernel 6.18.32 port branch `marble-6.18-full-port`

**Author:** Manus AI

**Recorded:** 2026-08-22

## Decision Boundary

The candidate 6.18 tree builds a raw kernel and selected modules, but that result is not a device-compatible Android boot stack. The current documented Evolution X 17 installation uses a 5.10.256 vendor stack, while the static audit identifies **97 first-stage** and **285 vendor-load** filename gaps, representing **382 unique** missing candidate-module filenames. The generated [vendor ledger](reports/marble_vendor_ledger_2026-08-22/MARBLE_VENDOR_MODULE_LEDGER_SUMMARY.md) classifies every name but does not make any binary reusable.

> Android distinguishes hardware-agnostic GKI modules from device-specific vendor modules. Vendor modules required early in boot belong in `vendor_boot`; therefore module-name overlap is not a compatibility proof and old vendor binaries cannot supply the missing 6.18 modules.[1]

The plan below is intentionally a **gate specification**. It identifies what must be evidenced before image assembly may even be reviewed. It does not provide flashing commands, create `boot.img`, create `vendor_boot.img`, produce an AnyKernel archive, extract private artifacts, or ask a device to boot an unverified stack.

## Current Static Baseline

| Evidence area | Static result | What it establishes | What it does not establish |
|---|---|---|---|
| Public Xiaomi source provenance | Kernel `48952ed36228217531482b39d5bef13e7fd808ec`; Device Tree `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` | Reproducible public 5.10 source and `cape`/`marble` DTS review bases | The original shipped artifact, board selector, or runtime behavior. |
| Candidate module ledger | 382 rows; 25 first-stage names have an ACK candidate and 72 first-stage names remain deferred; all rows retain a B0 block | Every observed filename gap has an explicit static disposition | A working native 6.18 module set or load order. |
| KMI baseline | Reproducible local `Module.symvers`/BTF baseline recorded in `KMI_BASELINE_REVIEW_6.18.32_R1.md` | The candidate output has a local ABI evidence point | Android-certified KMI or compatibility with a 5.10 vendor module. |
| Raw kernel build | Image, selected modules, DTB/DTBO and BTF/BTFIDS passed in diagnostic builds | The maintained source compiles with the documented toolchain | Boot, display, storage, modem, audio, cameras, safety, recovery, or flash safety. |
| Recovery route | User reports OFRP R11.1_7 worked for the current ROM; R1 has not been rehearsed | A user-reported recovery reference exists | An independently verified, exercised rollback route for this port. |

## Workstream A: Native 6.18 Vendor Module Replacement

The ledger is the normative starting point. Its `upstream` status means a target ACK Makefile candidate exists, not that the matching module is enabled, accepts the intended Device Tree, exposes an acceptable KMI, or can load in the required order. Its `defer/disable` and `proprietary-blocked` statuses are unresolved B0 blockers, not permission to remove a vendor load request.

| Priority | Scope | Required evidence before promotion | Explicit exclusion at this stage |
|---|---|---|---|
| A0: first-stage survival | Every one of the 97 first-stage filename gaps, concentrating first on storage/USB, PMIC/regulator, clocks/interconnect, IOMMU, SMEM/mailbox/SCM, pinctrl, and required filesystem/decompression facilities | One native 6.18 source/configuration disposition per row; generated `.ko` or intentional built-in proof; `modules.dep`/`modules.load` plan; exact DT, regulator, clock, reset, IOMMU, firmware, and init dependencies; BTF/KMI check | Reusing any 5.10 `.ko`; assuming a filename proves a required driver contract. |
| A1: platform services | Qualcomm remoteproc, IPC, WLAN, Bluetooth, USB/PCIe, audio and power policy only after A0 is fully evidenced | Source-port patch series or upstream selection, configuration diff, module dependency graph, firmware manifest, and userspace-ABI review | Enabling SPSS, modem, DSP or related remoteproc nodes merely because the static source compiles. |
| A2: user-facing subsystems | Display/GPU, camera, biometric/touch, haptics, audio enhancements and media | Vendor userspace/HAL and firmware contract evidence plus native driver plan | Treating these as boot-critical by default or declaring them functional from static analysis. |

A candidate source port may proceed only where a specific Xiaomi source path **and** an ACK target candidate have been reviewed. The change must be separate, buildable with the documented pahole v1.31 wrapper, and accompanied by a ledger regeneration. If the target candidate is absent, the row stays `defer/disable`; if the public source candidate is absent, it stays `proprietary-blocked`. Neither condition can be closed by copying the corresponding 5.10 module.

## Workstream B: Vendor Ramdisk and Module Load Order

AOSP specifies that early-boot vendor modules are delivered in `vendor_boot`, and boot-image header v4 can describe distinct `PLATFORM`, `RECOVERY`, and `DLKM` vendor-ramdisk fragments.[1] [2] The existing 5.10 module lists are evidence of a prior implementation, not a fragment recipe for 6.18.

| Required artifact | Required static contents | Acceptance condition | Current status |
|---|---|---|---|
| Partition/header manifest | Exact original `boot`, `vendor_boot`, `init_boot`, `recovery`, `dtbo`, `vbmeta*` partition topology; header version; page size; offsets; command line; compression; slot policy | Acquired lawfully from the matching ROM build and independently parsed, with hashes and no private image committed | Missing. |
| Native vendor module staging map | For each selected 6.18 module: source, Kconfig, built-in/module form, install directory, dependency order, and fragment classification | All A0 rows are covered; no entry refers to a 5.10 binary | Missing; intentionally not fabricated. |
| `modules.load` and dependency proof | Ordered native `.ko` names, `modules.dep`, `modules.alias`, required firmware paths, and first-stage availability | Deterministic output from a native 6.18 build, reconciled against the original boot phase | Missing. |
| Ramdisk content manifest | File path, owner/mode/SELinux label, fstab/init import relationship, decompression format, and fragment metadata | Matches the acquired device format and passes an offline unpack/repack equivalence check | Missing. |
| Recovery content boundary | Whether recovery resources and recovery-required modules reside in a dedicated recovery partition or in `vendor_boot` | Derived from the actual partition map and recovery evidence, never inferred from a generic Android version | Missing. |

> In a GKI design, the bootloader uses both `boot` and `vendor_boot`; the vendor boot image carries the vendor ramdisk and DTB, while version 4 additionally carries a ramdisk table and bootconfig. The generic and vendor ramdisks must use compatible formats and are concatenated by the boot process.[2]

## Workstream C: DTB, DTBO, and Board-Selector Evidence

The imported `cape`/`marble` sources offer valuable candidate DTS evidence but do not authorize alterations to `reg`, phandles, unit addresses, IRQs, selectors, or overlay targets. The current diagnostic DTS warning baseline remains visible and separately controlled. The following evidence is mandatory before modifying a hardware contract or making a DTB/DTBO container plan.

| Evidence item | Static validation required | Blocking reason if absent |
|---|---|---|
| Original DTB/DTBO container manifest | Partition location, image/container format, entry count, IDs/revisions, offsets, sizes, compression and SHA-256 | A generated `ukee.dtb` and standalone overlay cannot prove bootloader selection or container compatibility. |
| Selector-to-board mapping | Binding/source evidence linking the exact device SKU/PMIC/panel/board identifiers to the selected base DTS and overlay | Similar file names such as `cape-mtp` or PM8008 overlays are insufficient. |
| Node-by-node port rationale | Source/binding citation for every changed compatible, clock, regulator, reset, interrupt, IOMMU, reserved memory, interconnect, phandle, or `status` property | Suppressing warnings or guessing hardware addresses can make the kernel unsafe to boot. |
| Offline validation set | DTS compile, four warning gates at or below `87/36/128/85`, dt-schema/binding review when available, plus an extracted-container comparison | DTC success alone cannot validate bootloader selection or peripheral electrical contracts. |

## Workstream D: Firmware and Userspace ABI Bill of Materials

Many Qualcomm vendor drivers bind to firmware and vendor userspace interfaces outside the kernel tree. The ledger labels these requirements as review prompts rather than guesses. A firmware bill of materials must not copy or publish firmware; it records evidence only.

| BOM field | Required record | Closure evidence |
|---|---|---|
| Consumer | Native 6.18 module/built-in driver, source path, configuration, and driver version/port commit | Native build and module metadata. |
| Firmware request | Exact runtime request path/name, load phase, signature/authentication behavior, and subsystem owner | Reviewed source plus controlled runtime log later; no inferred filename. |
| Source and licensing | Original ROM build identity, partition origin, SHA-256 held outside Git, redistribution status | Lawful acquisition and review; never commit the binary. |
| Hardware/DT contract | Required reserved memory, clocks, regulators, mailbox, IOMMU, IRQ, or power domain | Binding plus DTS/source review. |
| Userspace coupling | Required HAL, daemon, QMI service, DSP/modem component, property, SELinux rule, or ioctl ABI | Matching userspace source/evidence and later runtime logs. |
| Disposition | `native-supported`, `source-port`, `defer`, or `blocked` | Signed reviewer decision with linked evidence. |

No firmware-dependent workstream is considered green merely because an executable firmware file is present in an existing ROM. The relevant 6.18 driver, DT contract, loading policy, userspace ABI, and failure behavior must all be identified.

## Workstream E: AVB, Partition Policy, and Recovery Evidence

Android Verified Boot is integrated with the Android build system, protects partition updates, and uses device-specific root-of-trust and rollback metadata.[3] The current project has no authorized production signing material and must not solicit, store, or commit any private key. An unlocked test device may have a different enforcement policy, but that condition requires direct evidence and does not transform an untested image into a safe test artifact.

| Gate | Evidence required | Current state |
|---|---|---|
| E0: partition map | Matching-ROM partition names, A/B/virtual-A/B status, dynamic partition relationship, and size limits | Not independently captured. |
| E1: AVB chain | Exact `vbmeta` chain/descriptor/rollback policy for all affected partitions, with public-safe hashes and no keys | Not captured. |
| E2: recovery rehearsal (R1) | A user-executed and recorded original-ROM recovery/restore rehearsal using the matching artifacts, including a return-to-boot proof | Not executed. |
| E3: artifact review | Independent review that proposed contents match the measured header, partition, ramdisk, DTB/DTBO, module, AVB and recovery evidence | Impossible while E0–E2 and A0–D are incomplete. |
| E4: controlled device test | Planned only after all prior gates are green; captures serial/pstore/recovery logs and restoration result | Not authorized or attempted. |

AOSP documents that vendor boot is protected by AVB and that header-v4 ramdisk fragments can be tagged for platform, recovery, or DLKM use.[2] Those facts describe a framework, not marble's unmeasured partition policy. The exact marble policy remains a required artifact-level investigation.

## Completion Matrix

| Deliverable | Static completion | External artifact or action still required | B0 effect |
|---|---|---|---|
| Public source provenance | Complete | None for this record | Informative only. |
| Gap classification and candidate source ledger | Complete for all 382 reported filenames | Native replacement selection and configuration review | Blocked. |
| Native 6.18 module plan | Partial, evidence structure complete | Ports/configs/builds/dependency and KMI review for all required rows | Blocked. |
| Vendor ramdisk plan | Template complete | Matching ROM partition/header/ramdisk manifest and native module staging data | Blocked. |
| DTB/DTBO plan | Template complete | Extracted matching container/selector evidence and validated property changes | Blocked. |
| Firmware/userspace BOM | Template complete | Lawful matching-artifact evidence and driver/HAL contract review | Blocked. |
| AVB and recovery plan | Template complete | Measured AVB policy and completed R1 recovery rehearsal | Blocked. |
| Device compatibility or flashability | Not attempted | All preceding gates plus controlled device logs | Blocked. |

**B0 conclusion:** **BLOCKED.** Static analysis has been completed as far as the available public source and text-only ROM-audit evidence permits. It does not produce a safe test package and does not establish bootability.

## References

[1]: https://source.android.com/docs/core/architecture/kernel/modules "AOSP: Kernel modules overview"
[2]: https://source.android.com/docs/core/architecture/partitions/vendor-boot-partitions "AOSP: Vendor boot partitions"
[3]: https://source.android.com/docs/security/features/verifiedboot/avb "AOSP: Android Verified Boot"
[4]: https://source.android.com/docs/core/architecture/partitions/generic-boot "AOSP: Generic boot partition"

<!-- cspell:ignore ACK ABI AVB BOM DTB DTBO DLKM DTS IOMMU KMI OFRP PMIC QMI RAMDISK SMEM SM7475 SPDX TSV -->
