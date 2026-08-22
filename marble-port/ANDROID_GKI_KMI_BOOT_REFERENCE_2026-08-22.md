# AOSP Reference Notes — GKI/KMI and `vendor_boot`

**Purpose:** This note preserves the official Android design constraints used by the marble 6.18 compatibility and packaging plan. It is not a device-testing or image-packaging procedure.

## Stable KMI constraints

Android's GKI model expects the GKI kernel and vendor-loadable modules to work as though they were built together. A stable KMI is constrained to the same LTS and Android-version branch, a single `gki_defconfig` configuration, a compatible LLVM toolchain, and a monitored symbol list. Vendor modules that depend on symbols outside the supported KMI surface can fail to load. The official build guidance therefore prefers a hermetic manifest-defined build environment and ABI tooling rather than mixing a kernel from one branch with binary modules from another.[1]

For marble, this reinforces the current block: the observed Evolution X 17 modules target kernel 5.10 while the candidate is 6.18. A raw `Image` replacement cannot make those binaries KMI-compatible.

## Vendor modules and early boot

Android distinguishes generic GKI modules from hardware-specific vendor modules. Vendor modules required early in the boot process must be located in `vendor_boot`; they cannot be treated as optional late-boot files. A 6.18 migration therefore needs source-built compatible replacements and a documented load plan for early vendor modules, rather than copying 5.10 `.ko` files by name.[2]

## `vendor_boot` structure

For Android boot header v3 and v4, `vendor_boot` contains vendor ramdisk content and DTB metadata in addition to header fields. Header v4 adds a vendor-ramdisk table, bootconfig, fragment types such as `PLATFORM`, `RECOVERY`, and `DLKM`, and board identifiers. The bootloader uses information from both `boot` and `vendor_boot`; the generic and vendor ramdisks are concatenated and must use a compatible format. These facts require preservation and review of header parameters, ramdisk fragments, DTB placement, board IDs, and bootconfig before any native image design is attempted.[3]

## Consequence for this project

The documented route is: establish R1 recovery for one original ROM; obtain a complete R0 fingerprinted artefact set; port or replace all required vendor modules and early-boot dependencies with 6.18-compatible outputs; create ABI/KMI evidence; prove DTB/DTBO and vendor ramdisk semantics; then design a test image for independent static inspection. No part of this note authorizes packaging or flashing.

## References

[1]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"

[2]: https://source.android.com/docs/core/architecture/kernel/modules "AOSP — Kernel modules overview"

[3]: https://source.android.com/docs/core/architecture/partitions/vendor-boot-partitions "AOSP — Vendor boot partitions"
