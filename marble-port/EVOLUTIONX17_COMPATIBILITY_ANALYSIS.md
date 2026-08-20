# Evolution X 17 compatibility analysis with marble GKI 6.18

**Current decision:** The current Evolution X 17 ROM does not install any binary or KMI compatibility with the Android Common Kernel 6.18.32 candidate. The 6.18 kernel remains buildable and statically analyzable, but **packaging and flashing are prohibited** until the required vendor paths are migrated to 6.18 and installed on an actual POCO F5 device.

> Successful building of an `Image` or the presence of four identical module names does not imply that the 6.18 kernel is suitable to replace kernel 5.10 in the ROM. Verification depends on ABI and KMI and Device Tree and ramdisk and firmware together, not on name or size.

## Actual ABI comparison

I extracted version values from the official `boot.img` and `vendor_dlkm.img`, then compared module names with the `marble-aosp-diagnostic-none` output from the local checkout. The reference is the ROM `EvolutionX-17.0-20260812-marble-12.1-Official.zip` documented in the artefacts inventory.[1]

| Item | Official Evolution X 17 | marble 6.18 candidate | Conclusion |
|---|---|---|---|
| kernel release | `5.10.256-gki-ge8fcf2558711` | `6.18.32-4k-marble-aosp-diagnostic-g5fa05535c108` | Major difference prevents reuse of binary modules. |
| compiler declared inside Image | Android Clang 21.0.0 / r563880c | Ubuntu Clang 18.1.3 | No toolchain or release match. |
| vendor vermagic | `5.10.256-gki-ge8fcf2558711 SMP preempt mod_unload modversions aarch64` | `6.18.32-4k-marble-aosp-diagnostic-g5fa05535c108 SMP preempt mod_unload modversions aarch64` for nominally intersecting modules | `modversions` enabled, ABI incompatible. |
| unique `vendor_dlkm` modules | 390 | 104 in candidate build | Not a loadable replacement. |
| `dlkm` modules in vendor ramdisk | 337 | no 6.18 DLKM ramdisk supported | Early boot gateway not satisfied. |
| initial load list | 97 modules | 97 names not built in candidate | vendor boot cannot be proven. |
| vendor DLKM load list | 289 modules | 285 names not built | Requires porting or 6.18-source-built replacements. |

The Android OTA protocol shows that `vendor_boot` can carry ramdisk fragments and that the payload describes partitions and separate hashes; therefore you cannot put an alternate `Image` into boot without building the vendor ramdisk and DTB and AVB from the same ROM keys.[2]

### Overlapping module names

Only four names appeared in the nominal intersection: `asix.ko`, `ax88179_178a.ko`, `zram.ko` and `zsmalloc.ko`. This is a names-only inventory result. Each of these carries a completely different vermagic in 6.18, therefore no `.ko` file is copied from the ROM to the candidate kernel.

| Reference name-gap family | number of modules not built by name | porting implication |
|---|---:|---|
| Qualcomm/vendor general | 126 | IPC, DSP, WLAN, PM, modem, vendor hooks. |
| power/clock/interconnect | 25 | RPMh and clocks and pinctrl and regulator and interconnect. |
| storage/USB | 24 | UFS/PHY and DWC3 and USB functions. |
| touch/biometrics | 11 | Goodix/FPC/Xiaomi/touch controllers. |
| display/GPU | 9 | KGSL/SDE/display clocks/panel/HDMI. |
| camera | 3 | vendor-specific camera integration. |
| other | 188 | includes audio, networking, diagnostics and board-specific features. |

These numbers represent a **lower bound** on the gap; they do not measure symbols or interfaces that have been renamed or moved built-in. The report does not permit randomly toggling Kconfig; a large number of Qualcomm reference options do not exist in ACK 6.18, and require source porting rather than a configuration fragment only.

## Device Tree and DTBO

The ROM's `vendor_boot.img` actually carries a DTB with a logical FDT size of `481,891` bytes inside a DTB reserved area of size `5,745,935` bytes. The local output `ukee.dtb` is a logical FDT of size `379,047` bytes. A difference in fingerprint and size is expected and not by itself a failure, but it prevents accepting equivalence without content analysis.

| DTB baseline metric | Evolution X 17 | marble 6.18 | Reading |
|---|---:|---:|---|
| unique compatible strings | 306 | 228 | the local base covers only a large portion. |
| shared compatible strings | 224 | — | structural overlap, not driver compatibility. |
| reference strings not present locally | 82 | — | genuine gaps candidate for inspection. |
| official DTBO | dt_table, 14 entries, logical size 4,299,397 bytes | raw overlay FDT single, 68,799 bytes | the official container cannot be replaced by the raw overlay. |
| DTBO entry referencing `marble/ukee` | `entry-03`, MSM ID `0x24f/0x10000` | current packaging nodes do not contain an equivalent selector | building a properly tuned DTBO container is required after testing the selector. |

The 82 reference compatible strings absent from the 6.18 candidate concentrate around camera (`cam-*`, `csiphy`, `vfe`, `sfe`), display (`dsi`, `dp`, `sde`), audio/DSP (`lpass`, `msm-*`, `wcd/wsa`, `spf/gpr`) and adsp. This is consistent with the absence of corresponding DLKM availability, and prevents treating the current DTB/DTBO as functionally equivalent.

> **Warnings:** Disassembling the official DTB/DTBO with DTC shows warnings related to legacy vendor nodes, and this audit does not turn those warnings into errors in the local output. Classification of build warnings will remain independent in `DT_WARNING_CLASSIFICATION.md` from the ROM artefact; do not edit ROM blobs to silence warnings.

## KMI and gated policies

The incoming ROM does not contain a textual ABI/KMI listing suitable as a 6.18 reference. There is no `system_dlkm` in this build's manifest, while there is `vendor_dlkm` and a `dlkm` fragment in `vendor_boot`. Therefore the state is as follows:

| Gate | Status | Condition to transition |
|---|---|---|
| KMI baseline | **not available** | build a project-specific 6.18 ABI list or obtain an approved KMI source. |
| vendor ramdisk | **incompatible** | build a 6.18 fragment with module paths built, loaded and tested. |
| vendor DLKM | **incompatible** | port the modules' sources or provide upstream replacements that are functionally identical. |
| DTB/DTBO | **not equivalent** | choose the correct board, build a documented DTBO container and compare nodes/properties not just strings. |
| AVB/boot packaging | **prohibited** | key policy and rollback index and device acceptance proof. |
| Device testing | **not performed** | POCO F5 connected, recovery path, logs and recovery established. |

## Reproducible outputs

The audit runs from existing outputs only and does not touch images or binaries:

```bash
./tools/audit_evolutionx17_rom_abi.sh \
  /path/to/evolutionx17-marble-artefacts \
  out/marble-aosp-diagnostic-none \
  marble-port/reports/evolutionx17_rom_abi_audit
```

Detailed results are available in `marble-port/reports/evolutionx17_rom_abi_audit/` and `marble-port/reports/evolutionx17_dtbo_comparison/`. Do not store ROM images or firmware or binary modules in Git.

## References

[1]: https://evolution-x.org/devices/marble "Evolution X — marble device page"
[2]: https://android.googlesource.com/platform/system/update_engine/+/HEAD/update_metadata.proto "AOSP update_engine OTA payload format"
