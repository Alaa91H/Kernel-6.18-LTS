# Vendor/KMI and Boot-Image Engineering Plan — `marble` 6.18

**Status:** Planning and evidence design only. This plan does not authorize image creation, AnyKernel3 packaging, flashing, or booting on hardware.

## 1. Core conclusion

The compatibility problem cannot be solved by inserting the 6.18 `Image` into the installed Evolution X 17 boot image. The reference ROM is a 5.10.256 product whose `vendor_boot`, vendor-DLKM modules, module load lists, DTBO container, firmware assumptions, and ABI relationship were produced for that kernel generation. The marble candidate is 6.18.32. This is a **product-stack migration**, not a kernel-payload replacement.

A usable 6.18 stack must provide a kernel, vendor modules, vendor ramdisk, DTB/DTBO selection, firmware mapping, and Android Verified Boot policy that have been designed and tested together. A matching module filename is insufficient; module `vermagic`, symbol versions, configuration, exported KMI symbols, and load-time dependencies must agree.

## 2. Target-state definition

Before code porting begins, freeze one target definition. The project must select a single Android release, one source manifest or equivalent reproducible source snapshot, one clang/LLVM toolchain definition, and one device/RAM/SKU selector. The selected target must not be described as a drop-in replacement for the existing 5.10 Evolution X vendor stack.

| Target area | Required final state | Current state |
|---|---|---|
| Kernel | A reproducible 6.18 source commit and a locked production-oriented configuration. | Static diagnostic 6.18 build only. |
| KMI | A named 6.18 KMI/ABI baseline, allowlist, symbol report, and comparison policy. | No accepted 6.18 product KMI baseline. |
| Vendor modules | Source-built 6.18 `.ko` modules with matching `vermagic`, symbol versions, load order, signing policy, and installation path. | 5.10 binaries are incompatible; 104 generic modules are not a replacement. |
| Vendor ramdisk | 6.18-compatible platform, recovery, and DLKM fragments with documented bootconfig and fstab semantics. | 5.10-dependent fragments only. |
| DTB and DTBO | A board-selected DTB/DTBO design with a documented container and overlay-selector mapping. | Raw local overlay does not replace the 14-entry ROM DTBO container. |
| Firmware | Per-driver firmware inventory with version, path, consumer, and compatibility proof. | Incomplete; SPSS remains disabled. |
| AVB | Reviewed partition map, rollback policy, and test signing approach. | Not established. |

## 3. Workstream A — establish the 6.18 product baseline

First, create a hermetic 6.18 build definition. This means recording the source commits, Kconfig fragments, LLVM version, pahole version, module-signing policy, build environment, and generated `Module.symvers`. The reproducible diagnostic build is useful evidence, but it is not yet the target product configuration.

The baseline must include an ABI/KMI report generated from the 6.18 configuration. The report must identify exported symbols, symbol CRCs where `CONFIG_MODVERSIONS` applies, compiler version, configuration hash, and the exact `uname -r`/`vermagic` that modules will use. Every future vendor module is built against this baseline, never against the installed 5.10 ROM image.

**Exit criterion A:** An independently repeatable 6.18 build produces the same declared toolchain/configuration identity and a retained KMI/ABI report. Any changing configuration, toolchain, or symbol set restarts the comparison.

## 4. Workstream B — inventory and classify vendor responsibilities

Extract an inventory from one original ROM only, while keeping proprietary artefacts outside Git. For every module and early-boot item, record its path, load phase, dependencies, firmware dependencies, device-tree compatible strings, source availability, and proposed disposition.

| Class | Typical `marble` scope | Required disposition |
|---|---|---|
| Early boot / storage | UFS, PHY, regulators, clocks, pinctrl, interconnect, PM, first-stage mounts. | Must have a 6.18 source-built and load-tested replacement before any candidate boot image exists. |
| SoC services | SMEM, IPC, mailbox, RPMh, remoteproc, shared memory, SCM. | Port from source or use an upstream 6.18 implementation with an audited DT contract. |
| Connectivity | WLAN, Bluetooth, USB/charging, modem-facing control paths. | Keep disabled or provide source-built replacements and firmware evidence. |
| User-facing hardware | Display/GPU, touch, biometrics, audio/DSP, camera. | Treat each as an independent porting program; no support is implied by compilation. |
| Optional services | SPSS, SPCOM, diagnostics, secondary remote processors. | Keep disabled until firmware, ABI, SSR, logs, and recovery criteria are satisfied. |

The reference audit shows 390 vendor-DLKM modules, 337 modules associated with the vendor ramdisk, and large name and dependency gaps. This inventory is a lower bound: symbol, firmware, DT, and userspace-interface dependencies must be assessed separately.

**Exit criterion B:** Every boot-critical vendor component has a named 6.18 source tree or upstream replacement, build owner, Kconfig selection, module path, dependency graph, and test plan. Any item marked "binary reuse from 5.10" is a hard stop.

## 5. Workstream C — port drivers and build vendor modules for 6.18

Port one dependency domain at a time. Start with the minimum set needed to mount storage and maintain power safely. For each module or built-in driver, keep a driver contract that names the binding, clocks, regulators, interrupts, IOMMU, firmware file, userspace interface, and expected log evidence.

Each source-built module must be checked against the frozen 6.18 baseline. The checks include its `vermagic`, undefined symbols, CRC/modversion behaviour, required KMI exports, licence/signing policy, load order, firmware requests, and resulting module dependency graph. A vendor module should never be validated merely because it compiles; it must load cleanly in an environment that contains the 6.18 kernel and the matching vendor ramdisk plan.

When an interface is not available in ACK 6.18, choose one of three explicit outcomes: port the vendor source, adapt to an upstream interface with a semantic contract review, or leave the feature disabled. Do not use configuration toggles or stubs to claim that a hardware function is supported.

**Exit criterion C:** The early-boot module set is built from source for the frozen baseline, has no unexpected unresolved symbols, and has a documented replacement or disablement decision for every 5.10 dependency.

## 6. Workstream D — construct the vendor ramdisk and DT/DTBO plan

The project must reconstruct the Android partition semantics from the selected ROM. Record the boot header version, page size, command line, bootconfig, ramdisk compression, DTB location, vendor-ramdisk table, fragment types, board identifiers, and slot/partition map. Header-v4 designs may contain separate `PLATFORM`, `RECOVERY`, and `DLKM` fragments; those fragments and their board IDs are part of the boot contract.

Build a 6.18 vendor ramdisk from the source-built module set. Preserve only data that is proven compatible and define every changed file and path. The first-stage fstab, storage dependencies, module load lists, and firmware paths require separate review. Do not place an old 5.10 DLKM fragment next to a new 6.18 `Image`.

The DTB and DTBO plan must identify the exact `marble` board/MSM selector. A raw overlay FDT is not equivalent to an Android DTBO container with multiple entries. The project must generate a compatible container only after its entry selection, overlay semantics, and affected nodes are reviewed. Existing DTC-warning classification remains visible and independent from runtime acceptance.

**Exit criterion D:** A static inspector can account for every vendor-ramdisk fragment, module, DTB/DTBO entry, and bootconfig field, and each one links to the frozen 6.18 baseline or an explicit disabled feature.

## 7. Workstream E — firmware and userspace contracts

Create a firmware bill of materials. For each enabled driver, record the requested filename, expected path, hardware consumer, interface version where known, source ROM relation, and a proof strategy. Firmware is not automatically portable across a kernel-generation change; firmware loading, remote-processor protocol, regulator requirements, and userspace HAL expectations are separate contracts.

SPSS must remain disabled until a dedicated firmware and SSR/GLINK/SMEM assessment is complete. The same staged approach applies to modem, DSP, WLAN, camera, and display domains. A userspace service that depends on a vendor ioctl or netlink interface becomes a compatibility item in the B0 report.

**Exit criterion E:** Every enabled firmware request and userspace-facing interface has a compatible evidence record. Unknown firmware or undocumented protocol dependencies block the relevant hardware domain.

## 8. Boot-image readiness gate

Only after workstreams A through E and the R1 recovery rehearsal are green may a candidate boot-image design be reviewed. At that time, choose exactly one approach.

| Approach | Preconditions | Required static inspection |
|---|---|---|
| Native Android image build | 6.18-compatible kernel, vendor ramdisk, DTB/DTBO, modules, firmware map, and AVB policy. | Header fields, ramdisk table, DTB location, bootconfig, partition sizes, AVB metadata, module paths, and hashes. |
| AnyKernel3 replacement | A proven claim that kernel-only replacement preserves the complete compatible vendor environment. | Base-image identity, exact target partition/slot, ramdisk preservation, no KMI/DLKM mismatch, DTB/DTBO policy, AVB policy, and abort-on-mismatch design. |

The current project does not meet the preconditions for either approach. In particular, AnyKernel3 cannot solve a vendor-module/KMI mismatch and must not be used to conceal one.

## 9. Recovery and test containment gate

A candidate package is not enough for a device attempt. R1 must first prove that the owner can restore the same original ROM using the documented recovery route. Before B1 opens, retain an immutable original-artefact manifest outside Git, a verified recovery record, a private backup location, UART or an equivalent early-log plan, pstore/ramoops collection, a masked device identity, and an attempt log template.

The first hardware candidate must minimize scope. It must not enable SPSS, camera, display tuning, audio/DSP, modem experiments, or unknown vendor modules simultaneously. A panic, storage fault, boot-loop, missing log, or uncertainty about the restored state returns the project to R0/R1. The raw release Image must not be treated as a candidate package.

## 10. Execution order and decision gates

| Order | Deliverable | Gate to proceed |
|---:|---|---|
| 1 | Complete one-ROM R0 artefact and fingerprint manifest. | Every required original artefact is present and hashed. |
| 2 | R1 original-ROM recovery record. | Original ROM returns to stable boot; USB and logs are available. |
| 3 | Frozen 6.18 KMI/ABI baseline and toolchain record. | ABI report accepted and reproducible. |
| 4 | Vendor-module gap matrix and source/disposition record. | No boot-critical unknown dependencies. |
| 5 | Source-built 6.18 early-boot vendor module set. | Module/KMI, firmware, and load-order checks pass. |
| 6 | 6.18 vendor ramdisk and DTB/DTBO container design. | Static inspection accounts for all fragments and selectors. |
| 7 | AVB/rollback and package review record. | Security and recovery review accepted. |
| 8 | Candidate boot-image design review. | B0 green; only then can B1 be considered. |

## References

- [AOSP GKI/KMI and vendor boot reference](ANDROID_GKI_KMI_BOOT_REFERENCE_2026-08-22.md)
- [Evolution X 17 ABI and DTBO compatibility analysis](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md)
- [Pre-device readiness packet](PRE_DEVICE_READINESS_PACKET.md)
- [Boot packaging readiness specification](BOOT_PACKAGING_READINESS_SPEC.md)
