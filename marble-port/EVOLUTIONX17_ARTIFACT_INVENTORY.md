# Official artefacts inventory for Evolution X 17 — marble

**Receipt status:** Complete and stable. The ZIP was inspected, the Android OTA manifest was read, and specific images were extracted from the full payload using only full REPLACE operations with SHA-256 verification for each partition. No ROM file was executed, no kernel module was loaded, and no new `boot.img` was created nor flashing performed.

> **Usage limit:** These artefacts represent only the official ROM specified below. They must not be mixed with another release or another ROM or standalone firmware, and the integrity of the extraction does not imply endorsement of compatibility with kernel 6.18.

## Entry identity and transport integrity

The official Evolution X page lists device `marble` among Android 17 devices.[1] The official ROM file recorded in the source discovery report was downloaded, then subjected to a full integrity test using `unzip -t` and a local SHA-256 computation.

| Field | Recorded value |
|---|---|
| Entry name | `EvolutionX-17.0-20260812-marble-12.1-Official.zip` |
| Size | `3,531,134,618` bytes |
| SHA-256 of ZIP | `f6abd32f40252bea3e8e3a8400949c29873f919f6f57fc76f31b3db242cda528` |
| ZIP test | **Passed** (`unzip -t`) |
| Update format | A/B OTA, `CrAU` payload v2 |
| SHA-256 of payload.bin | `01ad48fb044a05a45c0c3ff94c4f2835e4f8c52c33f8d40b3fa84c0a7c92cd94` |
| payload metadata | `232,720` bytes manifest and `267` bytes metadata signature |
| `post-timestamp` time | `2026-08-12T00:34:51Z` |
| OTA device(s) | `marble,marblein` |
| Android SDK level | `37`; Android `17` |
| security patch | `2026-08-01` |

The official `update_engine` protocol separates the `CrAU` header, the manifest, and the operation blobs, and specifies the `PartitionUpdate` fields and the hash bundles used to verify the extracted partitions.[2] This payload contained 31 partition updates; there were no delta or source-copy operations in the sensitive partitions extracted, as their operation types were only `REPLACE`, `REPLACE_BZ`, and `REPLACE_XZ`.

## Build identity inside the system

There are two values that must be recorded together; do not choose one to obscure the other. `META-INF/com/android/metadata` declares a general `post-build` string of `google/mustang_beta/mustang:CANARY/ZP11.260717.006/16004061:user/release-keys`, while `system.img` itself reveals that `ro.system.build.fingerprint` is `generic/marble/marble:17/CP2A.260605.016/eng.androi:user/release-keys` and that `ro.evolution.device=marble`.

| Property read from `system.img` | Value |
|---|---|
| `ro.system.build.id` | `CP2A.260605.016` |
| `ro.system.build.version.incremental` | `1786494891` |
| `ro.system.build.version.release` | `17` |
| `ro.system.build.version.sdk` | `37` |
| `ro.build.version.security_patch` | `2026-08-01` |
| `ro.product.mod_device` | `marble_global` |
| `ro.evolution.device` | `marble` |

This note **does not imply an automatic fault**; however, it makes recording both the OTA fingerprint and the system fingerprint mandatory in manifests outside of Git, and prevents relying on a single value at the acceptance gate.

## Boot images and dynamic partitions

All images below were verified against the `new_partition_info.hash` included in the manifest, not against the filename alone.

| Partition | Size (bytes) | SHA-256 | Reading result |
|---|---:|---|---|
| `boot` | 201,326,592 | `635fdd95d1fcdec6705b36a98dfbe7bc094dcaa373bc8e5915339935b1b66530` | Android boot v4. |
| `vendor_boot` | 100,663,296 | `5d8063edc99883e59363a76f8cb5d0d56f9c854ebdb23d09671f006d34aa6de4` | Android vendor boot v4. |
| `dtbo` | 25,165,824 | `5306d0c74b9a7a9ef676e6b1f5c5da1f70d5588dfb397f9e9b2b6e21cb493cb7` | dt_table contains 14 entries. |
| `vendor_dlkm` | 94,461,952 | `6aa9f00dbc6501a2db56c6e09d3e003ada1bbab53c9c10dffeccaba5417a3336` | ext4 contains vendor 5.10 modules. |
| `system` | 1,285,353,472 | `9bf6ada82a335785344060f3a409a1f6a55ac6a3bf9753dcec23f6e749a93cbb` | ext4; used only to read build properties. |
| `vendor` | 2,112,389,120 | `19b0c11629b881beaccc367ca05cf6de6afb439d5b5a9b4e1113d17ea6f7dfbd` | ext4; used to inventory firmware names only. |

> **Important note:** The `system_dlkm` partition does not appear in the manifest for this build. You must not invent a `SYSTEM_DLKM_DIR` path in the manifest; the empty value is explicitly recorded as evidence of absence from the payload inventory.

### boot and vendor_boot artifacts

| Property | `boot.img` | `vendor_boot.img` |
|---|---:|---|
| Header version | 4 | 4 |
| page size | 4096 | 4096 |
| Kernel size | 46,608,644 | — |
| Boot ramdisk size | 2,681,722 | — |
| Vendor ramdisk size | — | 12,855,750 |
| Included DTB size | — | 5,745,935 |
| bootconfig | — | 85 bytes |
| vendor ramdisk fragments | — | default + `dlkm` |

The release string inside `boot.img` reveals:

> `Linux version 5.10.256-gki-ge8fcf2558711 … clang version 21.0.0 … #68 SMP PREEMPT Tue Aug 11 20:16:11 UTC 2026`

The `dlkm` fragment in `vendor_boot` contains an LZ4-compressed CPIO with an uncompressed size of `34,351,872` bytes, 337 `.ko` files, 99 entries in the initial load list, and 66 entries in the blocklist. These modules are not extracted into the 6.18 output and are not used to satisfy a driver definition gap.

## ABI and DLKM modules

`vendor_dlkm.img` is an ext4 image containing 390 kernel modules, with 289 entries in `modules.load` and 66 in `modules.blocklist`. Representative modules such as `msm_drm.ko`, `qca_cld3_qca6490.ko`, and `qcom-spmi-adc5.ko` show a single vermagic value:

> `5.10.256-gki-ge8fcf2558711 SMP preempt mod_unload modversions aarch64`

| Comparison aspect | Extracted Evolution X 17 | diagnostic marble 6.18 candidate | Verdict |
|---|---:|---:|---|
| Kernel version | 5.10.256-gki | 6.18.32 | **Fundamentally different ABI**. |
| vendor_dlkm modules | 390 | 104 built modules | No direct binary substitute. |
| dlkm modules in vendor ramdisk | 337 | no approved 6.18 vendor ramdisk package | Boot gate blocked. |
| module versioning | enabled in the reference vermagic | requires new KMI proof | Reuse of the reference `.ko` is not permitted. |

This practically demonstrates, from the ROM artefacts themselves, that porting Evolution X to the Android Common Kernel 6.18 requires real porting of Qualcomm/Xiaomi paths (or equivalent upstream alternatives), not simply replacing the `Image` or copying the 5.10 DLKM.

## Device Tree and firmware

The `dtbo.img` container consists of 14 DTBs, with a logical size of `4,299,397` bytes, an entry size of `32` bytes, and a page size of `4096`. Entry `entry-03` contains indications `marble/ukee` and matches `qcom,msm-id = <0x24f 0x10000>`; all entries are subject to Qualcomm board/SOC selection, therefore comparing the local 6.18 overlay size (`68,799` bytes) with the container image is not a valid compatibility test.

`vendor.img` records 111 entries directly under `/firmware`, including firmware for the GPU (`a730_*` and `a662_gmu.bin`), the camera (`CAMERA_ICP.*`), EVA/VPU, Wi‑Fi/Touch, and audio. The payload also contains 20 firmware/boot-chain specific partitions, including `abl`, `aop`, `bluetooth`, `cpucp`, `dsp`, `modem`, `tz`, `uefi`, and `xbl`. These artefacts remain tied to the `20260812` build and are not included in Git.

## Impact of the intake on integration gates

| Gate | Status | Evidence |
|---|---|---|
| I0 — ZIP and source integrity | **Complete** | expected size, SHA-256 and `unzip -t` passed. |
| I1 — boot images and DLKM | **Complete** | extraction verified hash per partition. |
| I2 — ROM identity | **Complete with a dual note** | metadata and `system/build.prop`. |
| I3 — firmware/DT inventory | **Complete for intake** | 14 DTBO and 111 firmware root entries and 20 firmware partitions. |
| I4 — KMI/ABI for 6.18 | **Rejected for now** | reference ROM is 5.10.256 and vendor modules are not reusable. |
| I5 — packaging/flashing | **Blocked** | no completed KMI port nor an actual POCO F5 test. |

## Locally generated files

Reproducible data outside of Git exists under `artifacts/evolutionx17-marble-20260812/`: `zip_inventory/`, `payload_inspection/`, `boot_artifact_inspection.json`, `vendor_dlkm_inventory/`, `vendor_boot_dlkm_fragment/` and `vendor_firmware_inventory/`. This document and the repository do not include ROM images, binary modules, firmware, or signing keys.

## References

[1]: https://evolution-x.org/devices/marble "Evolution X — marble device page"
[2]: https://android.googlesource.com/platform/system/update_engine/+/HEAD/update_metadata.proto "AOSP update_engine payload metadata protobuf"
