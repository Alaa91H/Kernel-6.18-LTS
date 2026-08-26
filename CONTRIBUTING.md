# Contributing to Kernel-6.18-LTS

## Development model

This repository is an experimental, source-build-only marble prototype. Contributions must preserve its explicit safety boundary: **do not add boot-image packaging, flashing helpers, root integration, device claims, or vendor binary reuse without independently reviewable evidence and a maintainers-approved device acceptance plan.**

Prefer an upstream-first path. Android Common Kernel guidance recommends submitting generally useful work upstream and requires clear provenance and standard patch tags for non-upstream changes. [1]

## Before opening a pull request

| Change type | Required validation |
|---|---|
| Shell scripts | Run `bash -n` on every modified shell script and execute the relevant safe, host-side checks. |
| Marble prototype build or configuration | Run `./build_marble_gki_6_18_proto.sh` with a supported LLVM toolchain, then retain `build-metadata.txt` and verifier output. |
| Kernel C, Kconfig, Makefile, or Device Tree changes | Run `scripts/checkpatch.pl --strict --git <base>..HEAD` and build the relevant targets. Do not suppress warnings merely to obtain a green result. |
| Device Tree or vendor-interface changes | Add a reviewable compatibility rationale, list the exact source/ROM provenance, and update `PROJECT_STATUS.md` only with evidence actually obtained. |
| Documentation | Keep product status and safety boundaries consistent with `PROJECT_STATUS.md` and `CHANGELOG.md`. |

AOSP describes `gki_defconfig`/allmodconfig compatibility and `scripts/checkpatch.pl` compliance as common-kernel patch requirements. [1] The kernel documentation explains that checkpatch findings require engineering judgement, but ERROR and WARNING findings must receive deliberate review. [2]

## Commit expectations

Write a clear, imperative subject and explain the motivation, impact, validation, limitations, and provenance in the body. Include `Signed-off-by:` when the contribution is intended to follow the kernel contribution model. Use the applicable `UPSTREAM:`, `BACKPORT:`, `FROMGIT:`, `FROMLIST:`, or `ANDROID:` prefix for non-upstream Android Common Kernel work, as described by AOSP. [1]

## Pull-request expectations

State the exact base revision, toolchain identity, configuration fragment, commands run, and results. A successful compile is never sufficient evidence of hardware support. Pull requests must not introduce secrets, proprietary ROM partitions, proprietary firmware, or unreviewable binaries.

## References

[1]: https://android.googlesource.com/kernel/common/ "Android Common Kernel — patch requirements"
[2]: https://docs.kernel.org/dev-tools/checkpatch.html "Linux kernel documentation — Checkpatch"
