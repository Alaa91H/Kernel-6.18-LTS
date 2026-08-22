# KMI/ABI Baseline Review — marble 6.18.32-r1

**Decision:** The marble 6.18 static build now has a reproducible, hash-bound **local module ABI baseline**. This is a starting point for source-built vendor-module porting. It is not a stable Android product KMI, and it does not establish compatibility with the existing Evolution X 17 vendor stack.

## Evidence reviewed

The baseline generator was run against the successful `marble-6.18.32-r1` diagnostic output. The report binds the configuration, `Module.symvers`, `vmlinux`, and raw Image through SHA-256 values while leaving the large build artefacts outside Git. The build identity is kernel release `6.18.32-4k-marble-aosp-diagnostic-g5322f6db6ea9`, built from source commit `5322f6db6ea978f979deb349d9ebf0a52754bcc0`. Documentation-only updates afterwards do not alter the compiled source identity.

| Baseline item | Observed value | Review result |
|---|---:|---|
| Built modules | 104 | Insufficient as a replacement for the reference vendor set. |
| `Module.symvers` rows | 17,856 | Retained as a hash-bound local KMI comparison input. |
| `CONFIG_MODULES` | `y` | Module baseline is applicable. |
| `CONFIG_MODVERSIONS` | `y` | Symbol CRC and vermagic checks are mandatory for future modules. |
| BTF / BTF modules | enabled | Debug/type evidence is available for review. |
| Reference vendor-DLKM unique modules | 390 | Gap remains material. |
| Reference early-load names not built | 97 | Hard early-boot block. |
| Reference vendor-load names not built | 285 | Hard vendor-stack block. |
| Same filename overlap | 4 | Names do not imply ABI compatibility; no binary reuse is allowed. |

## What the baseline enables

A future source-built vendor module can now be assessed against a retained 6.18 configuration and symbol table. The module must be built with the frozen or deliberately revised toolchain/configuration baseline, then reviewed for `vermagic`, symbol versions, unresolved references, KMI/export dependencies, signing policy, module load order, firmware requests, and its Device Tree driver contract.

The baseline also turns broad vendor-port work into an ordered programme. The first implementation target is not display, camera, SPSS, or a boot image. It is the early-boot dependency graph: storage, regulators, clocks, pinctrl, interconnect, PM, first-stage mounts, and the required SoC services. Each of the 97 reference first-stage gaps must receive a source-port, upstream-replacement, or deliberate-disable decision before B0 can be reevaluated.

## What remains blocked

The baseline cannot make a KMI stable across 5.10 and 6.18. The installed Evolution X vendor modules, vendor ramdisk fragments, and DTBO container must not be reused with this candidate. There is still no frozen Android product manifest, approved GKI symbol allowlist, source-built 6.18 vendor-DLKM set, compatible vendor ramdisk, reviewed DTBO container, firmware bill of materials, AVB policy, or R1 recovery proof.

> The state therefore remains **B0 blocked** and **no packaging or device test is authorized**. The baseline is an engineering control that prevents arbitrary module experiments; it is not a bootability result.

## Next implementation work

The next source task is to create a **boot-critical vendor dependency ledger**. It will consume the existing 97 first-stage gaps and classify every item as: source available and candidate for port; upstream replacement candidate; required proprietary interface with no source; or intentionally deferred/disabled. The ledger must name the relevant binding, firmware, power/clock/IOMMU dependency, module path, and acceptance log for each item.

## References

- [Generated KMI baseline manifest](reports/kmi_baseline_6.18.32_r1/KMI_BASELINE_MANIFEST.md)
- [Vendor/KMI and boot-image engineering plan](VENDOR_KMI_BOOT_IMAGE_ENGINEERING_PLAN.md)
- [Evolution X 17 ABI and DTBO compatibility analysis](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md)
- [AOSP GKI/KMI reference notes](ANDROID_GKI_KMI_BOOT_REFERENCE_2026-08-22.md)
