# Design of marble build flavors

## Purpose and scope

The project produces a generic Android/GKI kernel, not a ROM-specific boot.img. Therefore the build interface separates the ROM flavor that determines **packaging inputs and matching vendor**, an optional root layer, and the diagnostics file. A boot package is not built, signed, or flashed before the actual ROM components are provided and KMI and device gates are passed.

| Interface option | Planned values | Impact |
|---|---|---|
| `--flavor` | `aosp`, `xiaomi` | Selects the manifest for matching inputs only; does not change the Device Tree or claim vendor modules compatibility. |
| `--root` | `none`, `ksu-next`, `apatch` | Specifies source policy and support status; the default and currently only accepted value is `none`. |
| `--diagnostics` | `release`, `diagnostic` | Specifies the Kconfig portion for monitoring after passing build tests. |
| `--package` | `none`, `boot` | Disallows `boot` unless a valid manifest is present and acceptance gates are complete. |

## Status of root layers on 6.18

| Layer | Published project support status | Decision on Android/GKI 6.18 |
|---|---|---|
| KernelSU Next | Declares support for kernels from 4.4 to 6.6 only, with GKI mode 5.10–6.6.[1] | **Not supported**; the build script must reject the request and must not fetch or apply the patch automatically. |
| APatch | Declares support for ARM64 with kernel versions 3.18–6.12, and requires `CONFIG_KALLSYMS=y`.[2] | **Not supported** on 6.18; the build script rejects the request and does not create a SuperKey or patch. |
| No root | Adds no patches outside ACK. | The currently supported flavor, and remains subject to marble, KMI, and device gaps. |

> Adding an unsupported root framework to 6.18 is not a "build flavor", but a high-risk independent kernel port. This project does not perform blind copies of patches or bypass release checks, because that may produce kernel panic or violate KMI.

## Packaging inputs required per ROM

Packaging components are not inferred from the ROM name. The flavor manifest needs the source, the matching `boot` or `vendor_boot`, `dtbo` if used, compatible `vendor_dlkm`/`system_dlkm` modules, and the agreed AVB/signing policy. KMI in GKI guarantees compatibility only within the supported branch; it does not automatically maintain compatibility between different GKI kernels or vendor modules built for a different release.[3]

## References

[1]: https://github.com/KernelSU-Next/KernelSU-Next "KernelSU Next — support matrix"
[2]: https://github.com/bmax121/APatch "APatch — supported kernels and configuration requirements"
[3]: https://source.android.com/docs/core/architecture/kernel/android-common "Android common kernels — KMI compatibility"
