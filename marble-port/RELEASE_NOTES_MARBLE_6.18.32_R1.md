# marble 6.18.32-r1 Release Notes

**Release date:** 2026-08-22
**Target device:** Xiaomi POCO F5 / Redmi Note 12 Turbo (`marble`)
**Source branch:** `marble-6.18-full-port`
**Source commit:** `5322f6db6ea978f979deb349d9ebf0a52754bcc0`

## Release scope

`marble 6.18.32-r1` is the first published **static-verification kernel Image** from this porting branch. It is provided for source review, reproducible-build validation, and future controlled device bring-up only. The release asset is a raw ARM64 Linux `Image`; it is deliberately not a `boot.img`, `vendor_boot.img`, AnyKernel ZIP, recovery package, or flashing bundle.

The release does not claim bootability, ROM compatibility, vendor-DLKM compatibility, firmware completeness, or hardware functionality on a POCO F5. It must not be treated as a daily-use kernel release.

## Included porting work

The source tree includes the marble Device Tree port and the previously recorded static driver work. This includes the ADC_TM7 compatibility extension in the Qualcomm thermal driver, together with the SPSS remoteproc and GLINK transport port. The default marble configuration intentionally leaves the SPSS Device Tree node disabled; no SPSS firmware, ABI, or on-device transport result is claimed.

The build path also retains the explicit `PAHOLE` forwarding needed for diagnostic BTF. The diagnostic configuration keeps BTF enabled, and this release was built with pahole `v1.31`; BTF was not disabled to obtain a successful result.

## Build verification

The release asset was produced from a clean Git tree using the `aosp` flavor, the `diagnostic` profile, `root=none`, and `package=none`. LLVM/Clang 18.1.3 and pahole v1.31 were used. The build completed successfully, the `BTF` and `BTFIDS` stages passed, and `pahole -F btf -C task_struct vmlinux` successfully read the resulting BTF.

| Verification item | Result |
|---|---|
| Kernel release | `6.18.32-4k-g5322f6db6ea9` |
| Image format | ARM64 Linux boot executable Image, little-endian, 4 KiB pages |
| Image size | `46,086,656` bytes |
| Image SHA-256 | `6141993c8f9fcf8eaee15ac021d976c3b10f2a6444fcb2239cf57ab898865f8c` |
| Modules built | `104` `.ko` files |
| `ukee.dtb` SHA-256 | `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0` |
| marble DTBO SHA-256 | `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba` |
| BTF and BTFIDS | Passed with BTF enabled |
| BTF readability | Passed through pahole v1.31 |

The build emitted the known classified Device Tree compiler warnings. They were neither hidden nor suppressed. This release build was not an independent rerun of the four Device Tree warning gates; the previously documented reference result remains `87/36/128/85` for build, base DTB, DTBO, and merged DTB respectively.

## Release assets

| Asset | Purpose |
|---|---|
| `Kernel-6.18.32-marble-r1-Image` | Raw, uncompressed ARM64 kernel Image from the verified build. |
| `Kernel-6.18.32-marble-r1-Image.sha256` | SHA-256 verification record for the raw Image. |
| `MANIFEST.txt` | Build provenance, verification results, and safety scope. |

No boot image, vendor boot image, DTBO image, vendor modules, firmware, recovery image, root layer, AnyKernel ZIP, or flashing script is published with this release.

## Important limitations

The currently examined Evolution X 17 device environment uses a 5.10.256 kernel and vendor components that are not ABI-compatible with this 6.18 candidate. No KMI baseline, matching vendor-DLKM bundle, compatible firmware package, boot image assembly, recovery rehearsal, UART evidence, or POCO F5 runtime result is included here. The static SPSS work likewise remains disabled pending firmware and physical-device validation.

> This release is deliberately **not flash-ready**. Do not flash the raw Image. A practical recovery path, matching ROM/vendor artefacts, KMI evidence, and a reviewed physical-device acceptance plan are mandatory before any boot-image or device-test step.

## References

The detailed build history, BTF remediation record, Device Tree warning policy, and device acceptance gates are maintained in the [`marble-port`](README.md) documentation set.
