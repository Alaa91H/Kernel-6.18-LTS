# Xiaomi Reference Provenance for Marble Static Vendor Analysis

**Status:** static-source evidence only

**Scope:** POCO F5 / Redmi Note 12 Turbo (`marble`, Qualcomm SM7475)

**Target branch:** `marble-6.18-full-port`

**Author:** Manus AI

**Recorded:** 2026-08-22

## Purpose and Boundary

This record fixes the exact public Xiaomi source references used by the static vendor-module and Device Tree analysis. It makes source-ledger results reproducible without importing a ROM image, proprietary module, firmware blob, signing key, recovery image, or generated build output into this repository.

> A source-path match is **candidate evidence**, not proof that a 5.10 vendor module can be loaded by, copied to, or made ABI-compatible with the 6.18 target. Every candidate still requires a native 6.18 build, configuration review, Device Tree and firmware contract review, KMI/ABI review, and eventual device evidence.

## Recorded References

| Reference | Upstream repository and branch | Resolved commit | Local analysis role | Integrity boundary |
|---|---|---:|---|---|
| Xiaomi kernel source | [MiCode/Xiaomi_Kernel_OpenSource, `marble-s-oss`][1] | `48952ed36228217531482b39d5bef13e7fd808ec` | Candidate 5.10 source paths, Kconfig/Makefile contracts, and marble configuration context | Public source reference only; no built module is reused. |
| Xiaomi Device Tree source | [MiCode/kernel_devicetree, `marble-s-oss`][2] | `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` | Candidate `cape`/`marble` DTS, overlay, selector, pinctrl, regulator, thermal, and reserved-memory evidence | Public DTS reference only; no selector or hardware property is changed solely from filename similarity. |
| ACK port tree | `Alaa91H/Kernel-6.18-LTS`, `marble-6.18-full-port` | `34a6e975936c4cc616ce4fad1e6dec31c1e3c59c` at capture time | 6.18 target-source and target-Kconfig candidate inventory | The moving branch must be recorded again whenever a generated ledger is regenerated. |

The Xiaomi kernel reference contains marble vendor configuration fragments, including `arch/arm64/configs/vendor/marble_GKI.config` and `arch/arm64/configs/vendor/marble_consolidate.config`. The public Device Tree reference contains `qcom/cape.dts`, `qcom/cape.dtsi`, `qcom/cape-v2.dts`, `qcom/marble-sm7475.dtsi`, and multiple PM8008/PM8010 overlay variants. Their existence establishes source-review starting points; it does not identify the exact shipping board selector or validate an assembled DTB/DTBO container.

## Audit Inputs Frozen for the Ledger Run

The ledger generator consumes already committed, source-data-free summaries of the documented Evolution X 17 5.10 vendor stack. The baseline input set contains **97 first-stage filename gaps**, **285 vendor-load filename gaps**, and **382 unique filename gaps**. The first-stage set is deliberately treated as higher priority because a missing early-boot dependency can prevent the system from reaching a useful diagnostic state.

| Input | Repository path | Meaning | Treatment in the ledger |
|---|---|---|---|
| First-stage gaps | `marble-port/reports/evolutionx17_rom_abi_audit/first_stage_load_filename_gaps.txt` | Vendor module filenames observed in the first-stage loading set but not built by the candidate 6.18 output | Every line must receive a candidate mapping, an explicit disposition, and a B0 effect. |
| Vendor-load gaps | `marble-port/reports/evolutionx17_rom_abi_audit/vendor_load_filename_gaps.txt` | Vendor module filenames observed later in the vendor-load set but not built by the candidate 6.18 output | Every line must receive a candidate mapping and an explicit disposition. |
| Gap-family counts | `marble-port/reports/evolutionx17_rom_abi_audit/module_gap_families.tsv` | Coarse triage for camera, display/GPU, power/clock/interconnect, Qualcomm vendor, storage/USB, touch/biometrics, and other | Used only as a prioritisation aid, never as proof of a source relationship. |
| Existing port contract | `marble-port/reports/evolutionx17_module_porting_contract.tsv` | Earlier filename/module disposition candidates and Makefile pointers | Treated as review input; the generator independently searches both source trees. |

## Reproduction Controls

The reference clones live outside the ACK Git work tree and their paths are supplied explicitly to the generator. The committed outputs contain only text, source-relative paths, Git revisions, classifications, and hashes. The generator does not read module binary contents, copy firmware, build a boot image, create a flash package, or make device changes.

A successful static ledger run therefore closes only the **evidence-inventory** portion of B0. It cannot close the runtime compatibility, proprietary-artifact, vendor ramdisk, DTBO container, firmware, AVB, recovery, or device-boot gates described in [the engineering plan](VENDOR_KMI_BOOT_IMAGE_ENGINEERING_PLAN.md).

## References

[1]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss "MiCode Xiaomi Kernel OpenSource marble-s-oss branch"
[2]: https://github.com/MiCode/kernel_devicetree/tree/marble-s-oss "MiCode kernel devicetree marble-s-oss branch"

No claim of device compatibility, safe flashing, or successful boot follows from this provenance record.

<!-- cspell:ignore MiCode PM8008 PM8010 DTB DTBO Kconfig Makefile ABI -->
