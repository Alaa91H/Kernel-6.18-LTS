# Boot Image and AnyKernel3 Packaging Readiness Specification — `marble`

**Status:** **BLOCKED — specification only.** This document defines the evidence required before a boot image or AnyKernel3 package may be assembled. It contains no flashing procedure and does not authorize creation, publication, or installation of a flashable artefact.

## 1. Purpose and scope

The current release asset is a raw ARM64 `Image`. It is useful for reproducible source-build review, but Android devices do not boot a raw kernel Image directly. A device-specific `boot.img`, `vendor_boot.img`, DTBO container, ramdisk, AVB policy, and compatible vendor/KMI environment must agree before an experimental boot path can be considered.

There are two possible packaging approaches after the gates below are green. A native boot-image path creates every required image from a documented, compatible source set. An AnyKernel3 path replaces the kernel only inside a previously proven boot image. Neither approach is currently accepted for the Evolution X 17 `marble` environment, because its installed vendor components target kernel 5.10 while this candidate is 6.18.

## 2. Current decision

| Gate | State | Packaging decision |
|---|---|---|
| R0 — ROM inventory | Partial | Do not select a base image until every required artefact has a fingerprint. |
| R1 — original-ROM recovery | Not executed | Do not create a candidate package. |
| B0 — KMI, DLKM, firmware, DTBO, and ramdisk compatibility | Blocked | Do not create a candidate package. |
| B1 — recoverable early boot | Closed | No device test is authorized. |
| AnyKernel3 or `boot.img` output | Blocked | No archive, `boot.img`, `vendor_boot.img`, or install instruction may be produced. |

> A successful kernel build, an Android 17 device identity, or a working recovery alone does not close any of these packaging gates.

## 3. Required immutable source set

One exact ROM build and one exact test device must be selected. Mixing a boot image from one release with a DTBO, vendor ramdisk, firmware, or module image from another release is prohibited.

| Artefact | Required evidence before packaging | Current state for Evolution X 17 / 6.18 |
|---|---|---|
| Original `boot.img` | SHA-256, Android boot header version, page size, kernel command line, OS version/patch level, ramdisk compression, and AVB relation. | Not recorded as a complete R0 manifest. |
| Original `vendor_boot.img` | SHA-256, vendor ramdisk fragments, embedded DTB layout, DLKM paths, bootconfig, and AVB relation. | Contains 5.10-dependent components; unsuitable for reuse by default. |
| Original DTBO container | SHA-256, entry table, board/MSM selectors, and overlay-to-board mapping. | The ROM container has 14 entries; the current raw overlay is not an equivalent container. |
| `vendor_dlkm` / `system_dlkm` | Module list, vermagic, symbol/KMI relationship, load lists, and a 6.18 replacement plan for every required module. | 390 vendor modules are recorded; reuse of the 5.10 binaries is prohibited. |
| Firmware inventory | Paths, SHA-256 values, consumer drivers, and evidence of compatibility with the enabled 6.18 path. | Incomplete; SPSS firmware and other vendor paths are not accepted. |
| AVB policy | Partition map, rollback-index policy, signing authority, and a test-only plan that does not use unapproved keys. | Not demonstrated. |
| Recovery evidence | Completed R1 recovery to the same original ROM, including stable USB and boot logs. | Not executed. |

## 4. Native boot-image route — future requirements

The native route is eligible only after R1 and B0 are green. It requires a documented source for all image components, including the exact Android boot header parameters, a 6.18-compatible generic and vendor ramdisk design, a matching DTB/DTBO plan, valid AVB handling, and an approved recovery route.

The static acceptance check for a future native image must prove that its header fields, ramdisk fragments, DTB placement, command line, and AVB metadata match the documented target policy. It must also prove that no 5.10 kernel module or vendor ramdisk fragment has been copied into the 6.18 package. Static image inspection is necessary, but it does not replace B1 device evidence.

## 5. AnyKernel3 route — future requirements

AnyKernel3 is only suitable when the following claim is already supported by evidence: replacing the kernel payload alone preserves a compatible boot and vendor environment. This claim is currently false for the examined Evolution X 17 build, because vendor ramdisk fragments, DLKM modules, the DTBO container, and KMI-dependent interfaces are not compatible by name or vermagic with the 6.18 candidate.

Before an AnyKernel3 package can be considered, the following items must be approved: a known-good base boot image from the same R0 manifest; an exact target partition and slot policy; an inspection of the base image format; a 6.18-compatible vendor/DLKM and DTBO plan; AVB and rollback-index evidence; and the completed R1 recovery proof. The package must contain an explicit abort policy for any mismatch. It must never silently overwrite unrelated partitions or modify vendor artefacts.

## 6. Pre-packaging decision record

A reviewer must complete every row before the packaging gate can change from blocked to open.

| Decision item | Required acceptance evidence | Required state |
|---|---|---|
| Base ROM identity | R0 manifest with all fingerprints and one build fingerprint. | Green |
| Recovery | R1 proof of return to the same original ROM. | Green |
| KMI/DLKM | A 6.18 source-built or upstream replacement plan for all required modules. | Green |
| Vendor ramdisk | No unknown 5.10 fragment; all early-boot dependencies mapped. | Green |
| DTB and DTBO | Documented board selector and a compatible DTBO container plan. | Green |
| Firmware | Per-driver firmware inventory and compatibility evidence. | Green |
| AVB and rollback | Reviewed policy and non-production signing plan. | Green |
| Logs and fallback | UART/pstore collection method and a tested recovery path. | Green |
| Image review | Independent inspection of the candidate package before device use. | Green |

Any missing item keeps the decision at **STOP**. A request for a faster experiment does not substitute for this evidence.

## 7. Current next action

The next action is to complete the R0 artefact manifest for the single installed Evolution X build, then conduct R1 only for that original ROM, and finally prepare the B0 compatibility report. No AnyKernel3 repository, image-packaging script, boot image, or flashable ZIP should be added before those gates are green.

## References

- [Pre-device readiness packet](PRE_DEVICE_READINESS_PACKET.md)
- [Evolution X 17 ABI and DTBO compatibility analysis](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md)
- [Release notes for the current raw Image](RELEASE_NOTES_MARBLE_6.18.32_R1.md)
