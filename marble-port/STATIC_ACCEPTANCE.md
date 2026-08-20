# Static Acceptance Record for POCO F5 (marble) on Android/GKI 6.18

## Scope of this record

This document records the results of source and Device Tree checks only. No successful entry implies the device booted, nor does it authorize creating or flashing a `boot.img`. The inspection result is valid for review against commit `02012bbe2e1edd14d49c32ef56ff5e94de8ce1e1`, whose tree was clean at the time the Device Tree check was performed.

| Acceptance Gate | Result | Evidence | Impact |
|---|---|---|---|
| Core path configuration | Statically successful | `validate_marble_core_config.sh` enabled 11 symbols. | UFS, RPMh, USB/PHY, ADC and `OF_OVERLAY` are set in the configuration. |
| Base DTB | Statically successful | `ukee.dtb` is readable via `dtc`. | Does not prove runtime availability of clocks, regulators, or drivers. |
| marble DTBO | Statically successful | `marble-sm7475-pm8008-overlay.dtbo` is readable via `dtc`. | Does not prove correctness of every phandle or availability of vendor definitions. |
| Overlay merge | Statically successful | Output of `fdtoverlay` is readable via `dtc`. | Constrains the result to build/merge capability; does not prove hardware activation. |
| Image and modules | Previously succeeded from a working tree containing the same changes before the build commit | 104 modules and Image recorded in `DT_BUILD_STATUS.md`. | Not to be treated as a clean-release fingerprint; a clean rebuild with BTF is a later condition. |
| KMI/BTF | Not acceptable | BTF temporarily disabled in `marble_gki_6_18_proto.config`. | Prevents claiming KMI compatibility or availability of a flashing package. |
| Booting on marble | Not executed | No serial log or `dmesg` or device test. | Prevents S3 and beyond. |

## Device Tree inspection fingerprints

| Output | Size (bytes) | SHA-256 |
|---|---:|---|
| `ukee.dtb` | 379,047 | `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8` |
| `marble-sm7475-pm8008-overlay.dtbo` | 68,799 | `5c73e0d1f6ee5ee5fbb5ba4cf9ac61a77c494bdfcd02d31c3170c3e956fd3e62` |
| `ukee-marble-merged.dtb` | 427,762 | `2b7970d274d6f61131f1a32e49ca7d366d67cc84310580be33ee48d7986a7d67` |

## Blocking gates before flashing

You may not produce or propose using a `boot.img`, nor pass this source result as a valid kernel for the device, until the following gates are closed. First, UFS and RPMh/power regulators and USB glue paths must be adapted to a true runtime configuration. Second, gaps in GPU, display, camera, audio, DSP, and modem must be closed or isolated via configuration proven not to prevent boot. Third, BTF must be re-enabled and a KMI test performed, then build a clean image from a recorded commit, and finally collect a boot and recovery log from a real marble device.

> The current inspection is **S1–S2: static-validated**. The remaining 129 DTC warnings in the build log, including phandle warnings in the post-merge read check, are treated as gaps that must be resolved or justified before hardware validation.
