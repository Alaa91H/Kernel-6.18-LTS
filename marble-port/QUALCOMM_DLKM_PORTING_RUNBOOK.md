# Qualcomm and DLKM Porting Runbook to marble 6.18

**Scope:** POCO F5 / `marble` (SM7475) with Evolution X 17 as artefacts-only reference. This runbook explains how to port sources and vendor modules to the Android Common Kernel 6.18; it does not permit copying `.ko` modules or DTB/DTBO or firmware binaries from the 5.10 ROM, and it does not produce a flashable image.

> **Non-negotiable rule:** A module built for `5.10.256-gki-ge8fcf2558711` is not a valid input for the `6.18.32` kernel. Every module must be rebuilt from its source against the 6.18 build's own `vmlinux`, `Module.symvers`, and KMI. A matching module name does not prove compatibility.

Android GKI does not promise KMI stability across LTS branches or different Android releases; stability is limited to the same branch and Android release and to the constrained configuration and toolchain. Also `CONFIG_MODVERSIONS` prevents loading a module with a mismatched CRC at runtime.[1] [2]

## 1. Lock input artifacts before writing any patch

Create an independent branch, e.g. `marble-6.18-port/<subsystem>`, and do not mix the porting work with general ACK changes. Record the two references reproducibly: the Qualcomm/Xiaomi 5.10 source that produced the Evolution X artefacts, and the `android17-6.18-lts` commit you will target. Do not use manifests from different releases or blobs from another ROM.

| Work file required | Source data | Mandatory fields | Acceptance criteria |
|---|---|---|---|
| `module-contract.tsv` | `vendor_dlkm` and the `dlkm` fragment in `vendor_boot` | module, init-stage, `modules.load`, depends, vermagic, firmware, DT compatible, Kconfig, source path | Each module from both lists classified as **upstream / port / not needed**. |
| `dt-contract.tsv` | official DTB and DTBO and 6.18 DTS | node, compatible, reg/interrupts/clocks/resets/icc, driver, selector | No required node without a driver or binding. |
| `firmware-contract.tsv` | `vendor.img` only | path, SHA-256, driver requester, load stage, license | Every required firmware must have a 6.18 driver and correct mount location. |
| `kmi-contract.tsv` | 6.18 output | symbol, namespace, exporter, consumers, CRC, justification | No vendor module depends on a symbol not allowed in the KMI. |

The current contract must show a fundamental proven gap: the reference ROM contains 390 unique module names, of which 337 are in the ramdisk `dlkm` and 97 in the early-boot list, while the general 6.18 candidate produces only 104 modules. Therefore porting begins with early-boot modules, not camera or graphics.[3]

## 2. Port ordering: layers before features

Do not port 390 modules in one shot. Work in a topic branch per layer with a reviewable patch series and bisectable commits. A layer is considered successful when its modules load from the 6.18-built source on device, not merely by passing `make`.

| Wave | Reference paths/families | Work required on 6.18 | Stop gate |
|---|---|---|---|
| P0: early platform | SPMI, PMIC, RPMh, regulator, pinctrl, GCC, interconnect/QNoC, SCM, SMEM, GLINK, QRTR, IOMMU, GIC | Replace with ACK-provided code first. Port Qualcomm code only if hardware-specific and not available upstream; reconcile clocks/regulators/interconnects with DTS. | No driver moves to P1 if probe/defer ordering fails or if SError/panic occurs. |
| P1: storage and boot | UFS/QMP PHY, `ufs_qcom`, crypto, nvmem, RTC, watchdog, reboot reason, memory dump | Port driver+binding+DTS+Kconfig together. Install UFS before `vendor_dlkm` because partitions depend on it. | Three boots and read/write tests without timeout or I/O error. |
| P2: USB and core power | DWC3, QMP USB PHY, role switch, charger/type-C if present | Review API changes in extcon/type-C/PHY/runtime-PM instead of blind cherry-picks. | ADB, file transfer, charging, and OTG where hardware is available. |
| P3: connectivity and DSP | CNSS/WLAN/BT, IPA, MHI, PIL/remoteproc, ADSP/CDSP, GPR/SPF | Start with IPC and remoteproc and firmware-loading dependencies; do not start with WLAN UI. | No modem/SSR loop, firmware authentic loading and healthy subsystem logs. |
| P4: input and audio | Goodix/FPC, WCD/WSA codecs, SoundWire, ASoC/LPASS | Isolate each controller, and avoid adding vendor-specific ABI inside ACK structs when possible. | touch events and audio capture/playback without reset. |
| P5: display and GPU | SDE/DRM, DSI/DP, KGSL or the supported alternative, panel | Large independent port; review dma-buf, sync fence, IOMMU, PM and DRM atomic APIs. | panel stable then suspend/resume then GPU fault=0. |
| P6: camera and video | CAMSS/CCI/CSID/CSIPHY/ICP/VFE/SFE/VIDC | Separate the capture pipeline from proprietary userspace; review ioctl/UAPI and media-controller and IOMMU. | camera HAL, preview/capture, video encode/decode and ISP logs healthy. |

### Rule for choosing the source

Always start in the following order: **existing ACK 6.18 → recent upstream driver → Qualcomm 5.10 code with minimal port patches**. Do not port the entire `drivers/*` tree from 5.10; that imports old APIs and types and will break the KMI instead of fixing it. For each patch, link the source commit in `PORTING_NOTES.md` and document why the upstream alternative is not suitable.

While porting, expect API changes in IRQ and GPIO descriptors, DMA/IOMMU, dma-buf, DRM, V4L2, remoteproc, dev_pm_ops, clk/regulator, `proc_ops` and netdev. The solution is not a broad compat header; the solution is converting each caller to the 6.18 semantic API and reviewing ownership, lifetime, error paths and runtime PM.

## 3. Produce a 6.18-specific KMI before building DLKM

Create a new 6.18 baseline; do not try to treat the 5.10 ABI as an acceptable baseline. Symbol lists represent the KMI boundaries only, and vendor modules must use KMI-approved symbols; GKI rejects loading modules that need disallowed symbols.[1] [2]

1. Build the ACK 6.18 using the hermetic Android environment and the Clang matching the ACK branch; do not use the system Clang when trusting KMI results. Keeping a local Clang 18 is fine for development validation, but it is not definitive proof of production ABI.
2. Enable `CONFIG_MODVERSIONS=y` and preserve `vmlinux`, `Module.symvers`, `.config`, `System.map` and the full release for every build ID.
3. Run the official/equivalent ABI target that emits `.stg` and the symbol list; AOSP documents that the ABI tooling compares `vmlinux` and GKI modules via STG representation and symbol lists.[2]
4. Create a marble-specific symbol list, e.g. `gki/aarch64/symbols/marble` or the path the 6.18 branch requires. Add a symbol only after proving that a 6.18 module needs it, that it is `EXPORT_SYMBOL_GPL` or an allowed export, and that the extension does not break the existing ABI.
5. Use `KBUILD_SYMTYPES=1` or the branch build-system equivalent when CRC mismatches appear. Compare the `.symtypes` file of the exporter and the consumer; do not add `EXPORT_SYMBOL` arbitrarily.
6. Fail CI on: undefined symbols in modpost, missing namespace import, differing CRC, or a required symbol outside the symbol list, or an unjustified ABI diff.

> Do not address CRC mismatch by disabling `CONFIG_MODVERSIONS` or by cutting `vermagic`. That turns a clear loading protection into a hard-to-diagnose crash risk. AOSP explains that a mismatch in `module_layout` or similar symbols must intentionally fail load.[2]

## 4. Convert each Qualcomm module into a 6.18 buildable module

For each module in `module-contract.tsv` perform the following loop, and do not start the next package until all items of the current one are closed:

```text
1. Identify the driver source and Kconfig and Makefile and DTS bindings and required firmware.
2. Decide: upstream built-in / upstream module / new vendor module / not needed.
3. Move one small patch, then build kernel + M=<driver-dir> with W=1 and LLVM.
4. Fix modpost and sparse and C=1 where possible; do not hide warnings by adding a general -Wno.
5. Review imports/exports and Module.symvers and CRC and the KMI symbol list.
6. Build the .ko from the same O=<6.18 out>, then record modinfo: vermagic, depends, firmware, signer.
7. Match DTS node and resources; test probe/defer/remove and runtime suspend on device.
8. Add the module to the manifest and modules.load only after proving need and success of the previous steps.
```

### Technical checkpoints to audit for each module

| Area | Technical check |
|---|---|
| Kconfig | correct `depends on`, not forcing a general framework vendor-only, and no duplicate symbol with ACK. |
| Makefile | the `.ko` output is rebuilt from the same `O=`, and there are no objects or `Module.symvers` from 5.10. |
| KMI | `modpost` is clean, namespaces imported, CRC consistent, and every required export is listed and referenced. |
| Device Tree | every clock/reset/regulator/ICC/IRQ/GPIO/IOMMU stream ID is valid for the 6.18 driver version; do not move phandle or compatible without a matching binding. |
| firmware | requested by the driver by the correct name after mount; SHA stored outside Git; binary firmware is not modified. |
| PM/error paths | `devm_*` and runtime-PM and wake IRQ and SSR/defer/remove work; no leaks and no use-after-free. |
| userspace | any added UAPI/IOCTL or sysfs/debugfs is documented and tested against the HAL, and does not break the used ABI. |

## 5. Reproduce DLKM: build new, do not copy binaries

AOSP divides modules into common GKI and hardware-specific vendor modules. Modules required for early boot are placed in `vendor_boot`, while non-early ones can live in `vendor`/`vendor_dlkm`.[4] Do not use the reference `vendor_dlkm.img` as a modules template; use it only to extract dependency order, names, firmware and load policy.

### 5.1 staging phase

1. Create `staging/vendor_dlkm/lib/modules/<release>/` and `staging/vendor_ramdisk_dlkm/lib/modules/<release>/` from 6.18 outputs only.
2. Use a reference list limited to the **modules that have been ported**. Do not copy the 5.10 `modules.load` list as-is; regenerate it from the 6.18 dependency graph.
3. Run `depmod -b <staging-root> <release>` using the same build outputs and `System.map` to generate `modules.dep`, `modules.alias`, `modules.softdep`, and `modules.symbols`.
4. Execute an automated check: every name in `modules.load` exists, every dependency in `modules.dep` exists, staging lists do not point to the 5.10 release, and every `.ko` has `vermagic` exactly matching the expected `6.18.32-…`.
5. Separate early-boot modules into the smallest possible set: storage/UFS, PMIC/clocks/ICC, IOMMU/SMEM, then what is necessary for early mount or firmware. Leave WLAN/GPU/camera in `vendor_dlkm` unless proven required before mount.

### 5.2 vendor_boot header v4

`vendor_boot` in Android header v4 contains the vendor ramdisk table and defines fragments of types `PLATFORM`, `RECOVERY` and `DLKM`; the table allows the bootloader to select fragments and load DLKM early when needed.[5]

For marble, match the official extracted fields; do not guess them:

| Setting | Implementation rule |
|---|---|
| `BOARD_BOOT_HEADER_VERSION` | remain `4` as long as the reference ROM uses header v4. |
| vendor ramdisk compression | LZ4 when the GKI image uses an LZ4 ramdisk. |
| fragment type | `DLKM` for the early modules group, not `PLATFORM` by mistake. |
| `board_id[0..15]` | copy the selector from the ROM table after documenting it; the reference marble entry points to MSM ID `0x24f/0x10000`. Do not use a generic zero without testing. |
| `KERNEL_MODULE_DIRS` | point to the staging directories for **6.18** modules only. |
| fstab/first-stage | remain in the vendor ramdisk per the ROM contract, and must mount `vendor_dlkm` before attempting to load modules from it. |
| bootconfig | keep as the ROM requires; do not remove keys or change load addresses. |

AOSP describes the explicit variables required: `BOARD_VENDOR_RAMDISK_FRAGMENTS`, `BOARD_VENDOR_RAMDISK_FRAGMENT.<name>.KERNEL_MODULE_DIRS`, and `MKBOOTIMG_ARGS` which include `--board_id*` and `--ramdisk_type`.[5]

### 5.3 vendor_dlkm image and security policy

Build `vendor_dlkm.img` from 6.18 staging with file contexts and fs_config and fstab and the ROM's init settings. Inspect SELinux policy and mount points and `/vendor_dlkm/lib/modules` paths before testing loads. Inspect `modinfo -F signer` and `sig_id` and `sig_key` in the reference ROM; if module signing is enforced, create a new valid signing chain and matching trust policy or use the project’s official path. Do not disable verification or place a private key in Git.

## 6. Device Tree and DTBO: part of the port, not a separate artefact

Producing a raw `marble-sm7475-pm8008-overlay.dtbo` is not sufficient. The reference ROM contains a `dt_table` container with 14 entries, while the current port has a single FDT; there are also 82 reference compatible strings not visible in the 6.18 DTB. Therefore:

1. Port each node as a synchronized **binding + driver + DTS**. Do not add a compatible without a driver, nor a driver without resources in DTS.
2. Build a matrix of 82 gaps: camera, display, audio/DSP, ADSP, then classify each as `not needed / upstream / ported / blocked`.
3. Create the `dt_table` via the appropriate AOSP tools from 6.18 overlays, with the same entry order and `id/rev/custom` selector required by the bootloader; do not pass a single FDT in place of dtbo.img.
4. Unpack the resulting container and inspect the header and entry count and board selectors, then unpack each entry with DTC and compare important nodes/properties with the reference, not just hashes.
5. Make DTC warnings a review gate: fix only warnings that you own a binding and board guide for; do not modify the blob or the old vendor DTS to zero out warnings.

## 7. Test gates before any flashing

| Gate | Execution guide | Success criterion | Blocks progress if |
|---|---|---|---|
| S0: source | small commit series + license/SOB + source mapping | no blobs and no 5.10 `.ko` in tree | a single patch that merges multiple subsystems or changes ABI without analysis. |
| S1: build/KMI | hermetic build, W=1, modpost, ABI/STG, symbol list, `Module.symvers` | no undefined/CRC/namespace/KMI failure | an unauthorized symbol or an unjustified ABI diff. |
| S2: staging | depmod and `modules.load` and vermagic check | every `.ko` is 6.18 and its dependencies closed | any 5.10 file or missing dependency. |
| S3: image inspection | unpack the produced `vendor_boot`/`vendor_dlkm` read-only | header v4, LZ4, DLKM fragment, board IDs, DTB/DTBO correct | differences in size/table/load addresses/selector from contract. |
| R1: recovery | original ROM restored on device with unlocked bootloader | original ROM boots after restore test | no rollback plan or missing logs. |
| B1: early boot | first boot in a recoverable path, pstore/serial/adb | UFS and mount and init and no panic | CRC/module load failure or storage error or SSR loop. |
| B2: stability | three cycles of boot/shutdown, then P0→P6 gradually | full logs and panic=0 per wave | any unexplained reboot returns you to the previous wave. |

Use the `diagnostic` flavor in B1/B2 only, as it contains BTF and dynamic-debug and ftrace and pstore. Save with every log: commit, `build-metadata.txt`, SHA-256 of Image and vendor_boot/vendor_dlkm/dtbo, build fingerprint, serial, battery level and temperature. Do not move to display/camera before UFS and power and USB are stable.

## 8. First proposed execution backlog

1. **Generate `module-contract.tsv` automatically** from 390 modules and 97 first-stage entries and link them to the Qualcomm 5.10 source and Kconfig and DTS and firmware.
2. **Create a hermetic 6.18 KMI baseline** and preserve `.stg` and `Module.symvers` and the marble symbol list in CI.
3. **P0/P1 only:** SPMI/PMIC/RPMh/clock/ICC/SMEM/IOMMU/UFS/QMP/reboot/watchdog. Do not start GPU or camera.
4. **Build a miniature 6.18 DLKM fragment** with `depmod` and header-v4 table and a static check, but do not sign/flash until R1.
5. **Test R1 then B1** on a real device with a documented recovery path; start with storage and pstore before WLAN or audio.
6. Re-open P2–P6 only after closing the B1 gate for each dependency wave.

## References

[1]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"
[2]: https://source.android.com/docs/core/architecture/kernel/abi-monitor "AOSP — Android kernel ABI monitoring"
[3]: ./EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md "Analysis of Evolution X 17 artefacts and the marble 6.18 candidate"
[4]: https://source.android.com/docs/core/architecture/kernel/modules "AOSP — Kernel modules overview"
[5]: https://source.android.com/docs/core/architecture/partitions/vendor-boot-partitions "AOSP — Vendor boot partitions"
