# Kernel-6.18-LTS — Marble Prototype Status

## Scope

This repository tracks a **host-side Android Common Kernel / Generic Kernel Image (GKI) 6.18 prototype** for the Qualcomm SM7475-based Xiaomi POCO F5 and Redmi Note 12 Turbo (`marble`). It begins from Android Common Kernel sources and carries a deliberately narrow configuration fragment that enables generic Android, UFS, Qualcomm GENI serial, remoteproc, and RPMsg facilities already available in the tree.

> **This is not a device release.** A successful build proves that the selected source tree, configuration, compiler, and requested targets can produce coherent artifacts. It does not prove that the artifacts boot on a POCO F5, interoperate with a specific ROM, or support any particular hardware function.

| Capability | Current evidence | Release claim permitted |
|---|---|---|
| ARM64 `Image` source build | Validated by the local helper and the active CI workflow | A source-build artifact can be reproduced under the recorded toolchain conditions. |
| Configuration intent | Checked against the merged `.config` after `olddefconfig` | The generic-GKI facilities in the fragment are enabled as requested. |
| Evidence integrity and provenance | Fixed regular-file archive layout, SHA-256, internal manifest, source revision, tree state, configuration hash, compiler line, module/DTB counts, and tag-only attestation | Evidence content and its recorded source state can be checked separately. An attestation is provenance evidence, not a device-compatibility certification. |
| Runtime testing | Not performed | No boot, peripheral, suspend/resume, thermal, modem, GPU, camera, display, audio, Wi-Fi, Bluetooth, or storage-functional claim is allowed. |
| Device integration | Not available | No `boot.img`, `vendor_boot.img`, DTBO package, recovery package, root integration, flashing ZIP, or firmware bundle is provided. |
| Vendor and KMI compatibility | Not established | Existing vendor modules and ROM partitions must not be reused or assumed compatible. |

## Build and verification

The prototype uses a transparent Kbuild-based helper:

```bash
./build_marble_gki_6_18_proto.sh
```

The helper generates `gki_defconfig`, merges `arch/arm64/configs/marble_gki_6_18_proto.config`, resolves the configuration with `olddefconfig`, builds `Image`, `modules`, and `dtbs`, writes `build-metadata.txt`, and invokes the independent verifier. The verifier fails if required symbols are absent, BTF policy changes unexpectedly, the recorded image checksum differs from the actual image, or recorded module/DTB counts differ from the output tree.

For recent Android common kernels, AOSP documents Bazel/Kleaf as the standard GKI distribution path and identifies `build.sh` as legacy for Android 14 and above. This repository’s helper remains an explicitly documented prototype path rather than a replacement for a full Android manifest/Kleaf environment. [1] [2]

## CI contract

The active workflow runs on pull requests, pushes to `main`, matching `marble-*` tags, and manual dispatch. It verifies shell syntax, whitespace, evidence-verifier positive and negative cases, configuration intent, changed-commit patch style, the full prototype build, evidence integrity, and tag-only provenance attestation. Its uploaded artifact contains only build records and the non-flashable evidence archive; it deliberately does not publish packaging or flashing artifacts.

GitHub recommends least-privilege workflow tokens, avoiding privileged PR triggers for untrusted code, and full commit-SHA pins for third-party actions. [3]

## Device-acceptance gate

A future device-focused release requires evidence for every item below before the project can change its non-flashable status. `DEVICE_ENABLEMENT_SOURCES.md` additionally records why currently available Xiaomi and LineageOS source trees cannot be copied into this ACK/GKI 6.18 prototype as complete Marble support.

| Gate | Minimum evidence required |
|---|---|
| Version-matched software contract | Identified ROM build, boot-chain partition layout, matching vendor and vendor-DLKM artifacts, and an ABI/KMI assessment. |
| Board enablement | Reviewed marble Device Tree/overlay path and all essential drivers built for the exact software contract. |
| Firmware and coprocessors | Compatible firmware inventory and validated interfaces for modem, DSP, GPU, Wi-Fi/Bluetooth, camera, audio, display, sensors, and remote processors. |
| Recovery | A rehearsed recovery method and a rollback path that do not rely on untested assumptions. |
| Instrumented boot | Serial/UART or equivalent boot logs, persistent crash collection, and no unexplained errors during initial boot. |
| Functional acceptance | Repeatable tests for storage, input, display, graphics, audio, networking, telephony, cameras, sensors, charging, thermals, suspend/resume, and stability. |
| Independent review | Maintainer review of the evidence, manifests, checksums, and release packaging. |

## References

[1]: https://source.android.com/docs/setup/build/building-kernels "Android Open Source Project — Build kernels"
[2]: https://android.googlesource.com/kernel/build/+/master/kleaf/ "AOSP Kleaf — Building Android Kernels with Bazel"
[3]: https://docs.github.com/en/actions/reference/security/secure-use "GitHub Docs — Secure use reference"
