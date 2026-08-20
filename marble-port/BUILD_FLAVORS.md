# Running marble build flavors

## Source-only builds

`tools/build_marble_flavor.sh` supports the flavors `aosp`, `xiaomi`, and `evolutionx-17` as a traceable source tag, and the `release` and `diagnostic` modes. Choosing the ROM does not change hardware definitions, does not import binaries from the ROM, and does not create `boot.img`; the real differences between ROMs are in the vendor images, modules, and signing, which are inputs that cannot be guessed from the ROM name.

| Command | Output | Status |
|---|---|---|
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor aosp --root none --diagnostics release` | Image, modules, and DTB/DTBO tagged as AOSP. | Allowed as source-only output. |
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor xiaomi --root none --diagnostics release` | Image, modules, and DTB/DTBO tagged as Xiaomi. | Allowed as source-only output. |
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor evolutionx-17 --root none --diagnostics diagnostic` | Image, modules, and DTB/DTBO tagged as Evolution X 17 with BTF/diagnostics. | Allowed for static verification only; does not replace 5.10 DLKM and does not produce a flash package. |
| `JOBS=8 ./tools/build_marble_flavor.sh --flavor aosp --root none --diagnostics diagnostic` | Output with BTF and dynamic-debug and ftrace/pstore tracing. | Allowed for verification; not a flash package. |
| `--root ksu-next` or `--root apatch` | Explicitly rejected. | Not supported by upstream on Linux 6.18. |
| `--package boot` | Explicitly rejected. | Blocked until manifest, KMI, and device testing. |

## Required BTF tool

The script checks for the `pahole` tool and passes it explicitly to the build system via the `PAHOLE` variable. BTF should not be disabled in the `diagnostic` flavor to hide a build-tool failure. In the current work environment the kernel requires a newer tool than the system package which has reached the per-CPU variables limit; the following example uses a local isolated tool:

```bash
PAHOLE=/home/ubuntu/tools/dwarves-install/bin/pahole \\
  JOBS=8 ./tools/build_marble_flavor.sh --flavor aosp --root none --diagnostics diagnostic
```

The `build-metadata.txt` records the tool path and version along with output checksums.

## Templates for packaging inputs

Upon completion of the acceptance gates, the user copies the appropriate example file to a location outside Git and fills in the artifact paths that were extracted **from the ROM matching the device and the same build**. Images, keys, or firmware must not be uploaded to the repository.

| Flavor | Template |
|---|---|
| AOSP | `marble-port/manifests/aosp.env.example` |
| Xiaomi | `marble-port/manifests/xiaomi.env.example` |
| Evolution X 17 | `marble-port/manifests/evolutionx-17.env.example` |

> Each build prints `build-metadata.txt` and includes the commit, flavor, diagnostic mode, fingerprints of Image and DTB/DTBO, and the number of modules. These data are saved with the device record when testing recovery.
