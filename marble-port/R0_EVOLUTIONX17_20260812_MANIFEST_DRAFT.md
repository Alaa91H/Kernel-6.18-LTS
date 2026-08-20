# R0 Manifest Draft — Evolution X 17 for POCO F5 / `marble`

**Status:** Partial preliminary inventory. This document does not prove recoverability or compatibility with Kernel 6.18, nor does it authorize downloading, flashing, or packaging any image.

## Package provided by the device owner

A single byte-range request was made to the download link to verify file metadata; the ROM archive was not downloaded, unpacked, or executed in any way.

| Field | Observed value | Field significance |
|---|---|---|
| Source URL | `https://cdn.evolution-x.org/marble/17/EvolutionX-17.0-20260812-marble-12.1-Official.zip/download` | Public link provided by the device owner. |
| Filename | `EvolutionX-17.0-20260812-marble-12.1-Official.zip` | Name includes codename `marble`, channel `17`, and build date `2026-08-12`. |
| Size from `Content-Range` | `3,531,134,618` bytes | Remote container size; does not prove content for each partition. |
| Remote modification time | `Wed, 12 Aug 2026 08:30:01 GMT` | HTTP metadata only. |
| ETag | `74e9c7f3bceb5d1acac3dfff9d7ef67a` | HTTP storage identifier, **not an endorsed SHA-256** nor a substitute for one. |
| SHA-256 of the archive | unavailable | An official published checksum is required or it should be calculated from a locally preserved ZIP copy. |
| ZIP contents/recovery images | not extracted | The link alone does not prove existence or suitability of `boot` or `vendor_boot` or `dtbo` or firmware. |

## Public ROM source and reported recovery path

The official Evolution X device page for `marble` shows Android 17 and Evolution X 12.1 with date `Wed Aug 12 2026` and status maintained, which is consistent with the snapshot and package name. The page includes a public link labelled “How to install”, but the extracted text does not reveal its steps or a specific recovery file; therefore it does not imply a recovery path or a recovery image name. [4]

The device owner provided a Telegram post `https://t.me/EvolutionXMarble/54840` as a potential reference for the recovery path. It was checked publicly in the browser but only showed an embed and “View in Group” and did not reveal the post text or files without group access. Therefore the link remains a **content-unverified reference** and is not treated as R1 evidence or as execution instructions. [5]

The filename visible in the Telegram snapshot matches a GitHub page for an OFRP release `R11.1_7 Beta` dated 15 February 2025. The source records the name `OFRP-R11.1_7_RECOVERY-Beta-marble.img` and an MD5 reference `d58cc27f10627d109ed5aa88bae7bf5c`, and the public release notes state support for Android 13–15 only. The device owner reported that this recovery actually works with the current Android 17 ROM and that the marble maintainer recommends it. This report constitutes **field operational evidence for the current ROM path**, but it does not change the scope of support stated in the public source, nor does it prove compatibility with Kernel 6.18 or success of R1. Therefore the project does not request replacing it or using a different file, but it requires the maintainer’s recommendation source and the fingerprint of the used copy before the path is considered fully documented. [6]

| Recovery item | Status | What is required before R1 |
|---|---|---|
| Historical path | Device owner reported using a recovery | Name, type, and version of the recovery, plus a cited written reference matching marble and the specific ROM. |
| Telegram post | Filename visible in snapshot, but content not exposed in public view | Post text or a clear snapshot of its contents, then review of suitability without executing it. |
| OFRP `R11.1_7 Beta` | Reported to work on current ROM and recommended by maintainer per owner; public source known | Link/text of maintainer recommendation, fingerprint of the used copy, and confirmation of recovery name/version present on the device. |
| recovery image | Candidate current recovery path, not fully documented | Filename, SHA-256 or MD5 matching the source, and evidence tying it precisely to the ROM/device. |

## Device evidence provided by the owner

The device owner provided a screenshot of **Settings → About phone** on 20 August 2026. The screenshot and any personal identifiers are not stored in Git. The screenshot shows only the following facts:

| Observed field | Value |
|---|---|
| Device | `Xiaomi POCO F5 | marble` |
| Android | `17` |
| Evolution X | `12.1` |
| Android security update | `1 August 2026` |
| Baseband | `MPSS.DE.2.0.c1-GLB-May 19 2026-07:13:14` |
| Kernel | `5.10.256-Alchemist-LTO`, build time `Mon Jul 13 09:02:17 UTC 2026` |
| ROM build date | `Wed Aug 12 00:34:51 UTC 2026` |
| Build number | `CP2A.260605.016` |

The identity `marble`, Android 17, Evolution X 12.1, and the 12 August 2026 date observed on the device are consistent with the download package name. This is a strong apparent match, but it does not prove the full build fingerprint or the SHA-256 of the package nor that every artefact in the container matches the device ROM.

## What is proven and what is not

This inventory proves that the remote available file is named `marble` and could be requested as a public link at the time of measurement, and that the device snapshot is consistent with the declared release. It does not prove that this ROM is an “official” manufacturer build, or that the archive contents match Kernel 6.18. Evolution X is a custom ROM; therefore it must be treated as a specific ROM reference, not as a default replacement for Xiaomi’s official images nor as ABI evidence.

| R0 item | Status | Remaining evidence |
|---|---|---|
| Single-referenced ROM | Partially advanced | Full build fingerprint or an official manifest linking the build number to the same package. |
| Device identity | Provisionally complete | About phone screenshot proving `POCO F5 / marble` and ROM version; does not document serial or IMEI. |
| ZIP fingerprint | Incomplete | Official SHA-256 or one computed from a locally preserved archive. |
| Container index | Incomplete | List of ZIP files and image artefacts and the payload without modifying contents. |
| Matching recovery images | Incomplete | It is reported the ROM was installed via recovery; a manifest for the matching recovery image and a cited recovery procedure for the release are still required, plus the required partitions. |
| Historical install path | Partially known | The device owner confirmed the current ROM was installed via recovery; this does not document the recovery name/version or the success of a recovery dry-run. |
| DLKM and firmware | Incomplete | List of modules and `vermagic` and firmware paths/baselines from the same ROM. |
| R1 dry-run | Not executed | Proof of restoring the same ROM on the device prior to any 6.18 candidate. |
| B0 compatibility with 6.18 | Blocked | KMI and DLKM and firmware alternatives compatible; do not assume components from 5.10 are compatible with 6.18. |

## Next step required from the device owner

Do not do anything on the phone right now. Just search in your downloads or storage: do you still have the ZIP file with the exact same name `EvolutionX-17.0-20260812-marble-12.1-Official.zip`? Answer only yes or no. If it exists, the next step will be to calculate its SHA-256 locally; do not upload it to the conversation and do not flash or unpack it yet.

An official SHA-256 may also be obtainable from the Evolution X source if published. Do not commit the owned package or fingerprints tied to device identifiers into Git.

## Fixed limitations

- No R1: The reported installation path is an OFRP recovery and reportedly works according to the owner and the maintainer’s recommendation, but restoration of the specific ROM on the device has not been proven and the fingerprint of the copy or the recovery evidence has not been fully preserved.
- No B0: Artefacts from 5.10 must not be treated as compatible with Kernel 6.18.
- No B1 or ADC_TM7 or SPSS testing: these gates remain closed until R1 and B0 are passed.
- The SPSS node remains `disabled` and `spss.mdt` or any firmware owned by SPSS will not be added to the repository.

## Measurement log

Response headers were previewed locally to verify HTTP handling and a byte-range request `0-0` only; the full ROM was not downloaded. Raw headers are not published because they contain a temporary signed storage link not required for R0 auditing.

## References

[1]: [Pre-device readiness packet](PRE_DEVICE_READINESS_PACKET.md)
[2]: [Device acceptance and recovery plan](DEVICE_ACCEPTANCE_PLAN.md)
[3]: [Evolution X 17 and ABI compatibility analysis](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md)
[4]: [Evolution X official device page for marble](https://evolution-x.org/devices/marble)
[5]: [Telegram post provided by the device owner](https://t.me/EvolutionXMarble/54840)
[6]: [OFRP R11.1_7 Beta release for marble on GitHub](https://github.com/Ctapchuk/android_device_xiaomi_marble-OFRP/releases/tag/R11.1_7)
