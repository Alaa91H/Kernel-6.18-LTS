# Pre-Device Readiness Packet — POCO F5 / `marble`

**Status:** Preparation and inference gate only. This packet does not grant permission to package, boot, or flash an image.

**Intended source baseline:** ADC_TM7 patch and SPSS/GLINK in commit `59d0b2603ef0deb3a746b5f8681ce8e27b495e4e`.
**Last static verification:** Image and 104 modules and BTF/`BTFIDS` and `ukee.dtb` and DTBO; Device Tree gates `87/36/128/85`. [1]

## 1. Start Decision

The current decision remains **STOP — no device testing**. The static build completed, but it does not satisfy two prerequisites for the first attempt: **R1**, i.e., a verified recovery of the same specified original ROM image, and **B0**, i.e., compatibility with no unknown elements between the 6.18 candidate and the ROM's KMI, vendor modules, and firmware. Current analysis shows that the examined artefacts from Evolution X 17 are built for kernel 5.10.256, and therefore DLKM or `vendor_boot` or firmware must not be reused on the assumption of compatibility with 6.18. [2] [3]

> Filling in the tables below does not turn the barrier into success. The gate only becomes green when the required evidence is preserved and reviewed, and only then does it move to the next gate in order.

| Gate | Current state | Condition to turn green | Result if condition not met |
|---|---|---|---|
| R0 — Inventory | Statically complete for a single ROM reference, not installed on device | Original images manifest complete with SHA-256 fingerprints and independent storage location | No modification to the device. |
| R1 — Recovery | **Not executed** | Return of the same original ROM to a stable boot after performing the referenced recovery | Absolute stop; no 6.18 candidate. |
| B0 — Artefact compatibility | **Blocked/Failed** | Reference KMI, compatible modules and firmware, and DTBO/vendor boot do not contain incompatible 5.10 components | No packaging nor experimental booting. |
| B1 — Early boot | Not open | R1 and B0 green, recoverable test pathway and UART/pstore logs | Immediate recovery and log retention. |
| B2 — Stability | Not open | Three stable boot/shutdown cycles after B1 | Fallback to B1; no field hardware tests. |

## 2. ROM and Device Identity File

The tester fills this section for one device and one ROM only. It is not permitted to mix boot or DTBO or vendor_boot or DLKM or firmware from different builds, and the full serial number or any personal data must not be placed in Git; a masked identifier and a private location for the image manifest must be used.

| Required field | Observed value | Evidence stored outside Git | Review status |
|---|---|---|---|
| Device model and codename | `POCO F5 / marble` only after verification | Fastboot snapshot or product definition with masked identifier | Incomplete |
| Bootloader and USB state | Documented state on the test device | Snapshot of state and stable USB connection | Incomplete |
| ROM and Android version | Full build fingerprint for a single candidate | `getprop` stored outside Git | Incomplete |
| Build id and patch level | From the original system itself | Dated properties log | Incomplete |
| Inventory date and tester name | Date/internal non-personal identifier | Process log | Incomplete |
| Recovery copies path | Private readable and restorable location | Proof of presence and fingerprints, no images in Git | Incomplete |

## 3. Recovery Manifest (R0)

A manifest file is created outside Git before any modification. Each artefact is recorded with filename, size, SHA-256, source, date acquired, and its precise linkage to the build fingerprint. Do not store proprietary images, keys, or device data in this repository.

| Artefact category | Minimum to be inventoried | Required evidence |
|---|---|---|
| Boot images | `boot`, `vendor_boot`, and `dtbo`, and the partitions required by the ROM's approved recovery procedure | Name, size, SHA-256, source, and linkage to build fingerprint. |
| vendor modules | `vendor_dlkm` and DLKM-related content inside `vendor_boot` and `system_dlkm` if present | List of modules, `vermagic`, and container fingerprints. |
| firmware | Firmware referenced by modem/DSP/WLAN/SPSS and the vendor firmware paths | List of paths and fingerprints and single ROM reference. |
| Tree definitions | Original DTBO and the relevant DTB/overlays | Fingerprints and index of labels/overlays. |
| Recovery path | maintainer-reviewed instructions matching the same release | Link/archived copy and second review before use. |

**R0 Criterion:** No empty fields, no artefact without a fingerprint, no source from a different ROM. The manifest is reviewed by a second person before opening R1.

## 4. Recovery Rehearsal (R1)

R1 does not test the 6.18 candidate. It only demonstrates that the specified device and ROM can be returned to their original state via the referenced recovery path. This is performed by the device owner, who is responsible for their data, after appropriate backups and following the matching ROM/manufacturer documentation. This repository does not provide flashing commands, images, or keys.

| Mandatory R1 evidence | Acceptance criterion |
|---|---|
| Proof that the original ROM returns to boot | ROM identity after recovery matches the build fingerprint recorded in R0. |
| USB connection in system and fastboot | Separate logs with timestamp of the test and masked device identifier. |
| Original boot log | kernel log and logcat stored outside Git; no panic or unexplained reboot. |
| Base storage inspection | No UFS, mount, or I/O errors in the initial log. |
| Recovery procedure log | Reviewable timeline with any problem and its resolution. |

**R1 Rule:** Any failure, unclear recovery state, or fingerprint mismatch returns the state to R0. There are no exceptions for a successful build or for low DTC warnings.

## 5. B0 Compatibility Report

Only after R1, the B0 report is prepared from the same ROM sources. The report is not intended to find a way to load 5.10 modules into 6.18; its goal is to demonstrate that every required component has a compatible replacement or that its pathway is intentionally and safely disabled.

| Comparison axis | Required B0 evidence | Known state |
|---|---|---|
| KMI/kernel release | Reference ABI/KMI list for the target ROM and comparison with the 6.18 candidate | Not available; the barrier is open. |
| DLKM | List of required modules, `vermagic`, symbols, and a 6.18 alternative plan for each module | Evolution X 17 modules built for 5.10 are not valid for reuse. [3] |
| `vendor_boot` and ramdisk | Separation of generic ramdisk components from ROM/KMI-specific components | Reuse of 5.10 components is not allowed by default. |
| firmware | Firmware manifest compatible with each enabled driver | Not demonstrated for SPSS or the remaining vendor paths. |
| Device Tree/DTBO | Semantic diff report and fingerprints, no cosmetic change | DT gates are intact; no runtime acceptance. [1] |
| Recovery | Linking candidate artefacts to a proven R1 path | Not open while B0 is blocked. |

**B0 Criterion:** Zero 'unknown' items or 'depends on ABI 5.10'. The presence of even one prevents B1.

## 6. Order of Enabling Vendors after B0

Multiple vendor paths are not enabled together on the first boot. B1 starts with the minimal possible feature set and in a recoverable manner, then stages follow with a documented decision after each evidence.

| Order | Scope | Start condition | Closure evidence | Stop rule |
|---:|---|---|---|---|
| 1 | Core boot, storage, and power | B0 green | ADB/UART, pstore, UFS and regulators without faults | Any panic or I/O error prevents the next step. |
| 2 | ADC_TM7 only | Three B2 base stable cycles | probe and IIO/SID and recorded thermal trip properly set from each critical channel | repeated defer or SID/IIO mismatch or IRQ storm returns to isolation. [4] |
| 3 | USB/charging and basic connectivity | B2 + stable ADC logs | ADB/USB and suspend/resume cycles and firmware logs | Any reset or firmware load error halts the scope. |
| 4 | SPSS without SPCOM | Firmware `spss.mdt` verified, SPSS-specific B0, UART and pstore and SSR plan | PAS/GLINK/SMEM/mailbox evidence from a single device | Still **Not open**; DT node remains disabled. [5] |
| 5 | Display, audio, camera, modem, and DSP | Acceptance of all prior dependencies and a defined vendor/KMI plan | Independent domain acceptance for each function | Support is not claimed based on DT or compile only. |

## 7. Required Logs Package for Each Future Attempt

Logs are collected outside Git, and each file is prefixed with a small header containing the source commit and SHA-256 of the Image and build fingerprint and capture time and masked device identifier. Sensitive data and serials are stored in a private store, not in public issues.

| Capture moment | Mandatory files or fields |
|---|---|
| Before B1 | Referenced R0 manifest, R1 evidence, B0 report, artefact fingerprints, and explicit review decision. |
| First B1 boot | UART if available, kernel log, logcat, `uname -a`, properties, pstore, and reason for reboot if it occurs. |
| After panic/reboot | pstore/ramoops before clearing, last kernel log, timing, artefact SHA, and a reproducible description. |
| After each hardware domain | domain logs, temperature/charge if relevant, and a specific verification or failure step. |
| B2 | Index of three consecutive cycles, panics=0, and shutdown/boot log for each cycle. |

## 8. Immediate Rejection Conditions

The state remains STOP immediately upon any of the following: absence of R1 evidence, mixing artefacts from different ROMs, attempt to reuse 5.10 DLKM in 6.18, lack of KMI/firmware evidence, unproven DT changes to silence DTC, absence of UART/pstore in the first high-risk attempt, or desire to enable SPSS while firmware or ABI remain unknown. Work returns to documentation and analysis rather than further hardware attempts.

## 9. Next Work Gate

The next step is not B1. The device owner must provide an R0 manifest for a single ROM and an R1 guide to recover the original ROM and B0 materials that explain the KMI/DLKM/firmware. Only after these are available should this packet be reviewed to determine whether B0 can be opened or whether additional drivers/vendor transfers are required.

## References

[1]: [Build verification and gates](BUILD_VERIFICATION.md)
[2]: [Device acceptance plan and recovery](DEVICE_ACCEPTANCE_PLAN.md)
[3]: [Evolution X 17 and ABI compatibility analysis](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md)
[4]: [ADC_TM7 port log](ADC_TM7_PORT_2026-08-20.md)
[5]: [SPSS and GLINK port log](SPSS_PORT_2026-08-20.md)
