# Changelog

All notable changes to the **Kernel-6.18-LTS marble prototype** are documented in this file. The project follows a conservative release policy: a build may demonstrate source and artifact consistency, but it does **not** demonstrate device bootability, ROM compatibility, vendor-DLKM compatibility, KMI compatibility, firmware availability, or hardware functionality.

> Release artifacts from this repository are **not flash-ready** unless a future release explicitly provides independently reviewed device-validation evidence, a compatible ROM/vendor contract, and a recovery plan.

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

The workflow uses the minimum `contents: read` token permission, avoids privileged pull-request triggers and secrets, and pins every external action to a full commit SHA. GitHub identifies full-SHA pinning as the immutable option for actions. [1]

### Validation boundary

r2 validates **only** the generic-GKI prototype build path. It does not build a `boot.img`, `vendor_boot.img`, DTBO package, recovery image, flashing ZIP, root integration, or vendor-module bundle. It must not be used for device flashing.

## [marble-6.18.32-r1] — 2026-08-22

The initial pre-release published a static-verification ARM64 `Image` with checksum and manifest. It was explicitly marked as non-flashable and did not claim device bootability or ROM compatibility.

## References

[1]: https://docs.github.com/en/actions/reference/security/secure-use "GitHub Docs — Secure use reference"
