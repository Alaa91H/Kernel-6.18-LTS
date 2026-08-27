# Changelog

All notable changes to the **Kernel-6.18-LTS marble prototype** are documented in this file. The project follows a conservative release policy: a build may demonstrate source and artifact consistency, but it does **not** demonstrate device bootability, ROM compatibility, vendor-DLKM compatibility, KMI compatibility, firmware availability, or hardware functionality.

> Release artifacts from this repository are **not flash-ready** unless a future release explicitly provides independently reviewed device-validation evidence, a compatible ROM/vendor contract, and a recovery plan.

## [marble-6.18.32-r4] — 2026-08-27

### Fixed

| Area | Correction |
|---|---|
| Evidence-bundle portability | The external SHA-256 file now records only the evidence archive basename instead of the absolute temporary path used by the CI runner. Consumers can therefore run `sha256sum -c marble-gki-source-build-evidence.tar.gz.sha256` after downloading both files into any directory. |
| Release verification | Added a local regression check that copies the evidence archive and checksum into a distinct download directory, verifies the external archive checksum there, then verifies the archive's internal manifest. |

### Release note

The `marble-6.18.32-r3` tag exercised the attestation workflow but did not have a published GitHub Release. r4 supersedes it as the consumable pre-release because its evidence checksum is portable. This correction affects evidence distribution and verification only; it does not alter kernel source, build configuration, output safety scope, or device-validation status.

## [marble-6.18.32-r3] — 2026-08-27

### Added

| Area | Change |
|---|---|
| ACK-aligned configuration gate | CI now materializes the upstream arm64 `gki_defconfig` and asserts that a valid arm64 configuration is generated before running the prototype build. This adds a low-cost guard aligned with Android Common Kernel patch expectations. [1] |
| Portable build evidence | Added `tools/create_marble_gki_evidence.sh`, which creates a normalized, checksum-protected archive containing the effective configuration, build metadata, build log, image hash, and manifest. It deliberately excludes the kernel image, modules, boot images, and device artifacts. |
| Release provenance | Builds triggered by `marble-*` tags now generate a signed GitHub artifact attestation for the evidence archive. The attestation binds the archive to its workflow, source revision, and build context; it does not certify security or device compatibility. [2] |

### Changed

| Area | Change |
|---|---|
| Continuous integration | The workflow now runs for protected release tags as well as pull requests, main-branch pushes, and manual dispatch. Release-tag runs retain the same build and verification gates before signing evidence. |
| Action runtime | Updated the checkout action to a commit-pinned v5 reference, removing the prior Node.js 20 deprecation annotation while retaining immutable action pinning. |
| Validation boundary | r3 distinguishes evidence integrity from software or hardware quality: a successful attestation verifies provenance for the evidence archive, not a flash image or a POCO F5 hardware result. |

### Fixed

| Area | Correction |
|---|---|
| Supply-chain auditability | Consumers no longer need to rely solely on mutable CI logs for release evidence. The new archive has deterministic tar metadata, an internal manifest, an external checksum file, and a release-tag attestation. |
| Early failure detection | A malformed or unsupported arm64 GKI base configuration now fails before the expensive prototype build begins. |

### Validation boundary

r3 still does **not** provide a flashable kernel. The release output is limited to signed source-build evidence and validation metadata. It does not establish Marble bootability, KMI/vendor-module compatibility, AVB/boot-chain acceptance, firmware availability, ROM compatibility, thermals, radios, cameras, storage, charging, or recovery behaviour.

## [marble-6.18.32-r2] — 2026-08-27

### Added

| Area | Change |
|---|---|
| Artifact verification | Added `tools/verify_marble_gki_prototype.sh`, an independent validator for the merged configuration, required GKI facilities, intentionally disabled BTF policy, kernel `Image` checksum, metadata integrity, module count, and DTB count. |
| Provenance | Extended build metadata with a UTC timestamp, explicit safety scope, working-tree state, compiler identification, and merged-config SHA-256. |
| Continuous integration | Added a least-privilege GitHub Actions workflow for shell syntax checks, config policy checks, checkpatch on the changed commit range, a reproducible arm64 source build, post-build artifact verification, and short-retention non-flashable evidence artifacts. |
| Project governance | Added contributor and security-reporting guidance, together with an explicit project status and validation-boundary document. |

### Changed

| Area | Change |
|---|---|
| Build entry point | `build_marble_gki_6_18_proto.sh` now performs prerequisite discovery, rejects unsafe output paths and invalid parallelism values, writes stronger provenance, and fails unless post-build validation passes. |
| Documentation | The project documentation now distinguishes host-side source-build evidence from device acceptance, making the absence of board DT/DTBO, vendor drivers, ROM/KMI evidence, firmware validation, and hardware results explicit. |

### Fixed

| Area | Correction |
|---|---|
| Release reproducibility | The build helper no longer treats the existence of an `Image` alone as sufficient evidence. The image and metadata are now cross-checked after the build. |
| CI coverage | The repository previously had no automated workflow. r2 introduces a reviewable validation path for pull requests, main-branch pushes, and manual runs. |
| Output-directory safety | The helper rejects empty, root, and source-tree output directories before deleting any build output. |

### Security

The workflow uses the minimum `contents: read` token permission, avoids privileged pull-request triggers and secrets, and pins every external action to a full commit SHA. GitHub identifies full-SHA pinning as the immutable option for actions. [3]

### Validation boundary

r2 validates **only** the generic-GKI prototype build path. It does not build a `boot.img`, `vendor_boot.img`, DTBO package, recovery image, flashing ZIP, root integration, or vendor-module bundle. It must not be used for device flashing.

## [marble-6.18.32-r1] — 2026-08-22

The initial pre-release published a static-verification ARM64 `Image` with checksum and manifest. It was explicitly marked as non-flashable and did not claim device bootability or ROM compatibility.

## References

[1]: https://android.googlesource.com/kernel/common/ "Android Common Kernel — patch requirements"
[2]: https://docs.github.com/en/actions/concepts/security/artifact-attestations "GitHub Docs — Artifact attestations"
[3]: https://docs.github.com/en/actions/reference/security/secure-use "GitHub Docs — Secure use reference"
