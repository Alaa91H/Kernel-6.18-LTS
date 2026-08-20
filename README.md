# Android Common Kernel 6.18 — POCO F5 / Redmi Note 12 Turbo (`marble`)

> **Status: experimental, static-validation port.** This branch is a development workspace for bringing the Qualcomm SM7475-based POCO F5 / Redmi Note 12 Turbo (`marble`, also referred to by Qualcomm Device Tree sources as `cape`) forward to Android Common Kernel 6.18. It is **not** a boot-ready distribution, a recovery package, or a flashing guide.

The active development branch is [`marble-6.18-full-port`](https://github.com/Alaa91H/Kernel-6.18-LTS/tree/marble-6.18-full-port). Work on this branch follows a deliberately conservative rule: a successful compile proves static integration, not hardware support. No boot, vendor boot, DTBO image, firmware bundle, or device flash is produced by the documented build path.

## Project scope

This repository starts from Android Common Kernel 6.18 and contains a focused `marble` bring-up effort. The work is intended to establish a repeatable source build, preserve and validate the imported Device Tree graph, close specific driver/Device Tree contracts where evidence exists, and document every remaining hardware gate before a real-device attempt.

| Area | Current state | What the result means |
|---|---|---|
| Repeatable AOSP diagnostic build | **Passed** | The selected `marble` Image, modules, `ukee.dtb`, and PM8008 overlay can be built from source. This does not establish ROM or vendor-module compatibility. [1] |
| BTF | **Passed** | The verified diagnostic build completed both `BTF` and `BTFIDS` with local pahole v1.31. [1] |
| Device Tree integrity gate | **Passed at the approved non-zero baseline** | The four preserved warning counts are `87/36/128/85` for build log, base DTB, standalone DTBO, and merged DTB. Warnings are classified and retained; they are not suppressed. [2] [3] |
| ADC_TM7 support | **Statically integrated** | The existing 6.18 Qualcomm ADC TM Gen2 driver was extended for `qcom,adc-tm7`; the driver, Image, modules, BTF, DTB, and DTBO were built. Probe and thermal behaviour have not been tested on hardware. [4] |
| SPSS and GLINK transport | **Statically integrated, disabled in Device Tree** | Optional remoteproc and GLINK support was added and successfully linked into a diagnostic marble build. The SPSS node remains disabled because firmware, ABI, and device evidence are not yet available. [5] |
| On-device validation | **Not performed** | No POCO F5 was booted, flashed, or probed during this work. [6] |

## What was implemented

The port deliberately avoids broad vendor imports when the Android Common Kernel already offers a suitable interface. The code changes are narrow and are accompanied by source notes and build logs under [`marble-port/`](marble-port/).

### ADC_TM7

`drivers/thermal/qcom/qcom-spmi-adc-tm5.c` now recognises `qcom,adc-tm7` and uses the existing Gen2 path to derive the ADC SID, ADC channel, BTM channel, threshold programming, and IIO-channel validation. The change does not alter marble DTS, Kconfig, or the Makefile. It also rejects a mismatched IIO channel/SID mapping rather than silently binding the wrong thermal source. [4]

### SPSS and GLINK

The branch adds an optional Qualcomm Secure Processor Subsystem (`SPSS`) remoteproc driver and an associated GLINK transport:

| File or configuration | Purpose |
|---|---|
| `drivers/remoteproc/qcom_spss.c` | PAS/remoteproc lifecycle, reserved memory, SCSR hand-off, regulators, clocks, and GLINK subdevice management. |
| `drivers/rpmsg/qcom_glink_spss.c` | SPSS GLINK transport using the existing SMEM, mailbox, and interrupt contracts exposed by the imported DT. |
| `include/linux/rpmsg/qcom_glink_spss.h` | Internal interface and build-safe stubs for the GLINK transport. |
| `CONFIG_QCOM_SPSS` | Optional remoteproc driver; not enabled by the normal marble configuration. |
| `CONFIG_RPMSG_QCOM_GLINK_SPSS` | Optional GLINK transport selected by SPSS. |

The implementation was compiled and linked with both symbols enabled through a temporary, untracked verification fragment. This is intentional: the default marble configuration is not changed and the DT node remains `status = "disabled"`. The port does not include the proprietary `spss.mdt` firmware, SPCOM userspace ABI, or a claim that mailbox, SMEM, firmware authentication, suspend/resume, or subsystem restart works on target hardware. [5]

## Verified build evidence

The most recent SPSS-enabled diagnostic build was performed from the working tree that became commit [`59d0b2603`](https://github.com/Alaa91H/Kernel-6.18-LTS/commit/59d0b2603ef0deb3a746b5f8681ce8e27b495e4e). It used LLVM/Clang and local pahole v1.31, built only source artefacts, and did not package them.

| Output or gate | Verified result |
|---|---|
| ARM64 `Image` | SHA-256 `8a853a3be16cb777749e067d4ed890cb86944c5ac2c15207100cd5ee0c68aa47` |
| Kernel modules | `104` `.ko` files |
| `ukee.dtb` | SHA-256 `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0` |
| `marble-sm7475-pm8008-overlay.dtbo` | SHA-256 `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba` |
| BTF | `BTF` and `BTFIDS` completed successfully |
| Device Tree gate | `87/36/128/85`, equal to the allowed regression ceiling |

The raw logs and the verification record are versioned in [`marble-port/reports/`](marble-port/reports/) and [`marble-port/BUILD_VERIFICATION.md`](marble-port/BUILD_VERIFICATION.md). The logs are evidence for the exact static checks performed; they are not evidence of a device boot.

## Reproducing the normal diagnostic build

A host needs a functional LLVM/Clang toolchain, GNU build prerequisites, Device Tree Compiler tools including `fdtoverlay`, Python `dt-schema`, and a pahole version capable of processing this kernel's BTF. The project build script refuses root integrations and image packaging by design.

```bash
git clone --branch marble-6.18-full-port \
  https://github.com/Alaa91H/Kernel-6.18-LTS.git
cd Kernel-6.18-LTS

PAHOLE=/absolute/path/to/pahole-v1.31 \
OUT_DIR="$PWD/out/marble-aosp-diagnostic" \
tools/build_marble_flavor.sh \
  --flavor aosp \
  --diagnostics diagnostic \
  --root none \
  --package none
```

This command builds `Image`, modules, `ukee.dtb`, and the marble PM8008 DTBO only. The default configuration does **not** enable SPSS. SPSS was enabled only in a separate static-verification build to prove compilation and linkage; it must not be enabled on a device merely because the build succeeds. [5]

Re-run the independent Device Tree gate after any DTS, DTBO, binding, or relevant driver change:

```bash
OUT="$PWD/out/marble-dt-check" tools/validate_marble_dt_build.sh
```

The gate builds the target DTB and DTBO, applies the overlay with `fdtoverlay`, decompiles each artefact with DTC, and compares the four warning counts with the approved ceilings. Do not disable DTC warning classes or edit `reg`, phandles, unit addresses, interrupts, or bus cells solely to lower the count. [2] [3]

## What is explicitly not supported yet

The following are hard boundaries, not future-tense marketing statements:

| Boundary | Reason |
|---|---|
| Flashing, boot-image packaging, or a recovery procedure | No recovery path has been proved on a real device, and no reviewed ROM manifest exists. [6] |
| Vendor DLKM reuse from a 5.10 ROM | The repository documents a known ABI mismatch between the 6.18 candidate and the examined 5.10 Evolution X artefacts. [1] |
| SPSS enablement | The required firmware, ABI validation, mailbox/SMEM runtime evidence, UART traces, and recovery plan are not available. [5] |
| ADC_TM7 functional acceptance | IIO reads, thermal trips, interrupt behaviour, suspend/resume, and sensor calibration still require target hardware. [4] |
| Camera, GPU, display, audio, modem, DSP, and proprietary vendor services | These areas depend on additional drivers, firmware, vendor userspace, and a compatible ROM/KMI contract. [6] |

> **Do not flash an artefact from this repository.** The project presently demonstrates source-level and artifact-level consistency only. A device attempt must first satisfy the staged recovery, KMI, firmware, UART/pstore, and functional-acceptance gates in the device acceptance plan. [6]

## Documentation map

| Document | Contents |
|---|---|
| [`marble-port/BUILD_VERIFICATION.md`](marble-port/BUILD_VERIFICATION.md) | Reproducible build results, artifact hashes, BTF status, and Device Tree gate history. |
| [`marble-port/DT_WARNING_CLASSIFICATION.md`](marble-port/DT_WARNING_CLASSIFICATION.md) | Classification of known DTC warnings and rules for safe remediation. |
| [`marble-port/ADC_TM7_PORT_2026-08-20.md`](marble-port/ADC_TM7_PORT_2026-08-20.md) | ADC_TM7 port design, static checks, and device acceptance conditions. |
| [`marble-port/SPSS_PORT_2026-08-20.md`](marble-port/SPSS_PORT_2026-08-20.md) | SPSS/GLINK design, static checks, and firmware/ABI limitations. |
| [`marble-port/DRIVER_CONTRACT_MATRIX_2026-08-20.md`](marble-port/DRIVER_CONTRACT_MATRIX_2026-08-20.md) | Driver, configuration, and Device Tree contract matrix. |
| [`marble-port/DEVICE_ACCEPTANCE_PLAN.md`](marble-port/DEVICE_ACCEPTANCE_PLAN.md) | Required recovery and on-device acceptance gates before any flash attempt. |

## Contribution principles

Contributions should be small, reviewable, and backed by the appropriate evidence. A compile-only result may close a compile-only issue, but cannot close a runtime contract. Do not replace a missing binding or runtime proof with a cosmetic Device Tree change. In particular, preserve DTC diagnostics, avoid speculative `reg` or phandle edits, and retain the no-packaging rule until device acceptance gates have been met.

## References

[1]: [marble build verification record](marble-port/BUILD_VERIFICATION.md)
[2]: [Device Tree validation gate](tools/validate_marble_dt_build.sh)
[3]: [Device Tree warning classification](marble-port/DT_WARNING_CLASSIFICATION.md)
[4]: [ADC_TM7 port record](marble-port/ADC_TM7_PORT_2026-08-20.md)
[5]: [SPSS and GLINK port record](marble-port/SPSS_PORT_2026-08-20.md)
[6]: [device acceptance and recovery plan](marble-port/DEVICE_ACCEPTANCE_PLAN.md)
