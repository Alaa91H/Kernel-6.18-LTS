# marble build verification — AOSP diagnostic

## Result

The diagnostic `aosp` flavor build from a clean Git tree succeeded at commit `5fa05535c1085fd078b81593d17c476b230189a1`. The build mode is `root_mode=none` and `package=none`, therefore the output is not a flashable image nor a claim of compatibility with any specific ROM.

| Verification item | Result |
|---|---|
| Image ARM64 | Passed; size `45,885,952` bytes; SHA-256 `ecfbb59f8b7d045e92e3b7858032ab245f94dd74be73985011b57155f5d72509`. |
| Modules | Passed; `104` `.ko` files. |
| ukee.dtb | Passed; SHA-256 `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8`. |
| marble DTBO | Passed; SHA-256 `8644bb0525008aa3ffe94394c17d6c1b95a1155b86ec73986feeeb4f93cd6ce9`. |
| BTF in `vmlinux` | Passed; `.BTF` and `.BTF_ids` sections present, and `pahole -F btf -C task_struct` extracted a valid definition. |
| Base configuration | Passed; `11` marble core path symbols. |
| Diagnostic configuration | Passed; `12` symbols for BTF, dynamic-debug, ftrace, and pstore. |
| DTB/DTBO/merge | Passed; all pieces are readable and the overlay is mergeable. |

## Xiaomi release flavor verification

A build of the `xiaomi` flavor in `release` mode also succeeded from a clean Git tree at commit `b5c3866ff10651d74a8525729e83d969d1904c69`. This flavor validates the Xiaomi selection path and output automation, but it is **not** proof of compatibility with MIUI/HyperOS or any Xiaomi ROM because matching vendor images, firmware, and ABI have not been integrated.

| Verification item | Result |
|---|---|
| Image ARM64 | Passed; size `36,489,728` bytes; SHA-256 `4fc8442447ba3766ada9b43810c9197547dab1b4cc54eea05298b0624a058257`. |
| Modules | Passed; `104` `.ko` files. |
| ukee.dtb and marble DTBO | Passed; the fingerprints match the diagnostic flavor outputs because the Device Tree does not change with ROM tag selection. |
| root layer | `none`; no KernelSU Next or APatch kernel layer integrated. |
| BTF/diagnostics | This is a release flavor; it does not enable the diagnostic file and should not be used as a substitute for the diagnostic BTF verification above. |

## Evolution X 17 diagnostic flavor verification

A build of the `evolutionx-17` flavor from a clean Git tree at commit `292a8b56c6f0264741ba551a58bdf5c614b323c7` succeeded using `PAHOLE=/home/ubuntu/tools/dwarves-install/bin/pahole` at version `v1.31`. The flavor only changes the origin tag; it does not import ROM binaries nor produce `boot.img` or `vendor_boot.img`.

| Verification item | Result |
|---|---|
| Image ARM64 | Passed; size `45,885,952` bytes; SHA-256 `cb6646c0ceba72426fd04ee74a09a78fd71d9047832112deb93b9a6f4d6cfa9a`. |
| kernel release | `6.18.32-4k-g292a8b56c6f0`. |
| Modules | Passed; `104` `.ko` files. |
| ukee.dtb | Passed; size `379,047` bytes; SHA-256 `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8`. |
| marble DTBO | Passed; size `68,799` bytes; SHA-256 `8644bb0525008aa3ffe94394c17d6c1b95a1155b86ec73986feeeb4f93cd6ce9`. |
| BTF | Passed; `vmlinux` file present prior to `pahole -F btf`. |
| config check | Passed; 11 core symbols and 12 diagnostic symbols. |
| `package=none` and `root=none` | Enforced; no flashing artefact produced. |
| Safety guard tests | Explicitly rejected `ksu-next`, `apatch`, and `--package boot` with exit code `2`; log in `reports/evolutionx17_safety_guard_tests.txt`. |

> This success does not open the packaging gate: the extracted Evolution X 17 ROM uses kernel `5.10.256-gki` and vendor_dlkm / vendor_boot modules that are ABI-incompatible with 6.18. See [`EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md`](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md) before any boot image steps.

## Reverification after enabling P0 upstream

A narrow P0 layer was added and pinned to the nodes in `cape.dtsi`: `QCOM_IPCC`, `HWSPINLOCK_QCOM`, `QCOM_SMEM`, and `QCOM_SMP2P`. The three flavors were built from the clean commit `343b9da858dd`, and all four symbols were verified in `.config` and as builtin module indices. The change only builds the IPC/SMEM base; it does not bring in vendor DLKM or alter the Evolution X 17 ABI incompatibility verdict.

| Flavor | Result | Image | Modules | BTF | Image SHA-256 |
|---|---|---:|---:|---|---|
| `aosp` / `diagnostic` | Passed | 46,021,120 bytes | 104 | valid via `pahole v1.31` | `60c8d77bfb7d16ac75c375f29c2d15ff8e237604dfa84ab79bf090ea1e5e8f0c` |
| `xiaomi` / `release` | Passed | 36,559,360 bytes | 104 | not required in release | `d6c1c60330b9dd1451ddb0b4d51ffe916c83bfed0fce2433e4bc2b952d9ffd23` |
| `evolutionx-17` / `diagnostic` | Passed | 46,021,120 bytes | 104 | valid via `pahole v1.31` | `bf0f6d639bb71e58b333cc97e627a2148f4a0af420c85136827580e82144d3c7` |

All flavors reached `6.18.32-4k-g343b9da858dd`, and `root=none` and `package=none` remained. `tools/validate_marble_dt_build.sh` now sets the reference warning caps to (`129/53/154/103` for build/DTB/DTBO/DTB merged) and rejects any regression; the actual measurement after P0 is `129/53/153/102`, i.e. no new warnings.

> Readiness decision: build, BTF, and P0 are static-successful, but the “0 warnings and 0 errors” criterion is not met: there are 129 DTC messages in the build, and 386 vendor DLKM modules cannot be reused. No boot image is produced nor DLKM enabled or flashing performed until remaining vendor bindings/drivers are ported, a KMI baseline is created, and a POCO F5 is tested physically.

## Reverification after P1 wave

`CONFIG_SPMI_MSM_PMIC_ARB=y` was added after verifying that the `spmi0_bus` and `spmi1_bus` nodes in `cape.dtsi` use `qcom,spmi-pmic-arb` which matches the ACK table for 6.18. The three flavors were built from the clean tree at commit `85ee72eaa3b3`, and each flavor verified the symbol in `.config` and the builtin module path `kernel/drivers/spmi/spmi-pmic-arb.ko` in `modules.builtin`. This does not prove hardware probing; PMIC and ADC testing still require a real POCO F5.

| Flavor | Image SHA-256 | Modules | BTF | Source |
|---|---|---:|---|---|
| `aosp` / `diagnostic` | `4c5f8dd5c8c223a5478511d1fd1dcb3d5040194c58e6d56fa81b62b50f111c0f` | 104 | valid via `pahole v1.31` | clean `85ee72eaa3b3` |
| `xiaomi` / `release` | `7779d62e5fca1b8cd6ef46dbf1e8c71f5c9b1f9e9fbcd2dbee2440850b6125f0` | 104 | not required in release | clean `85ee72eaa3b3` |
| `evolutionx-17` / `diagnostic` | `bb9d43c0ecd10aaffd5e4710e44933489ea5ebbe5159741d142d1500a4111b80` | 104 | valid via `pahole v1.31` | clean `85ee72eaa3b3` |

The static ABI/DLKM check passed again: the reference contains 390 unique modules, of which 386 are not built by name in the output, with 97 first-stage load gaps and 285 vendor load gaps. The tool verdict remains explicit: the Evolution X 17 modules built with `5.10.256-gki` are ABI-incompatible with the 6.18 Image and do not load or package.

## Handling BTF

BTF initially failed to build with `pahole v1.25` because the tool hit the per-CPU variable limit of `4096`, and then `resolve_btfids` failed to read the produced BTF. `pahole v1.31` was built locally from the official [dwarves][1] project source, and an independent test confirmed its ability to encode the kernel intermediate BTF at size `6,969,029` bytes. `tools/build_marble_flavor.sh` now passes `PAHOLE` as an explicit Make variable, and the successful build log uses `/home/ubuntu/tools/dwarves-install/bin/pahole` at version `v1.31`.

> Disabling BTF in the `diagnostic` flavor to work around a toolchain break is not permitted. Any alternate build environment must re-prove BTF success and readability before its outputs are accepted.

## Device Tree warnings

The build still records known, classified DTC warnings, and the validation tool does not hide them. Current counters are:

| Warning domain | Count |
|---|---:|
| specific marble build | 126 |
| decoding `ukee.dtb` | 50 |
| decoding single DTBO | 153 |
| decoding DTB after DTBO merge | 99 |

[`DT_WARNING_CLASSIFICATION.md`](DT_WARNING_CLASSIFICATION.md) contains the cause for each category and safe remediation boundaries. Reducing the single-port CoreSight patch lowered the warnings to `126/50/153/99`, and the validation budget was tightened to these values; no semantic change was made to zero the remainder without bindings or hardware testing.

## KMI and acceptance state

The current tree does not include a reference ABI/KMI list for marble or any targeted ROM. The actual Evolution X 17 ROM is now stripped, and `EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md` documents the difference between kernel `5.10.256-gki` and the vendor modules versus the 6.18 candidate; however, there is still no approved KMI list that would convert that into acceptance. Drivers and modules or upstream replacements must be ported, a vendor ramdisk and appropriate DTBO built, then a real device test with boot logs and UFS/USB/display/connectivity results before opening any `boot.img` gate or flashing.

[1]: https://github.com/acmel/dwarves "dwarves / pahole"

## Reverification after fixing DTC bindings

The three flavors were built from commit `09743b464` after fixing GICv3/ITS bindings and PCIe `interrupt-map` and QUP/USB contexts and `reserved-memory` in overlays. The two diagnostic flavors used `PAHOLE=/home/ubuntu/tools/dwarves-install/bin/pahole`, and root or boot image packaging was not enabled in any flavor.

| Flavor | Diagnostic mode | Image | Image SHA-256 | Modules | BTF |
|---|---|---:|---|---:|---|
| `aosp` | `diagnostic` | 46,021,120 bytes | `56172142a3fb38fc3126552e91e8b27c595953399dc0c97dcb4151eee7389324` | 104 | present in `vmlinux` |
| `xiaomi` | `release` | 36,559,360 bytes | `6c65085be1c4c75c045813566411c93c3057e669aac4f343277ec71417e3f96f` | 104 | not enabled in release as expected |
| `evolutionx-17` | `diagnostic` | 46,021,120 bytes | `e2f154e54c999d8a385051b4f54f618028fc615af121ca0b9d089a21c424ee13` | 104 | present in `vmlinux` |

The `tools/validate_marble_dt_build.sh` gate passed with the new values: **`87/36/128/85`** for build and base DTB and single DTBO and merged DTB, respectively. This represents a reduction of `39/14/25/14` from the baseline `126/50/153/99` without disabling DTC checks.

> This remains a static build and layout verification. Success does not convert to flash approval: remaining ADC/SPSS warnings and vendor bindings, together with the known ABI incompatibility with Evolution X 17 (5.10), require a suitable vendor source and a physical POCO F5 test before any `boot.img`, DLKM, or flashing actions.

## Static SPSS verification with marble diagnostic

The SPSS and GLINK patch added to the working tree was verified by building a clean marble diagnostic build with the symbols `CONFIG_QCOM_SPSS=y` and `CONFIG_RPMSG_QCOM_GLINK_SPSS=y` enabled via a temporary verification fragment outside tracked files. This method does not change `defconfig` or the default marble setup, nor does it remove `status = "disabled"` from the SPSS node. Local `pahole v1.31` was used, and BTF and `BTFIDS` passed successfully.

| Verification item | Result |
|---|---|
| Image ARM64 | Passed; SHA-256 `8a853a3be16cb777749e067d4ed890cb86944c5ac2c15207100cd5ee0c68aa47`. |
| Modules | Passed; `104` `.ko` files. |
| `ukee.dtb` | Passed; SHA-256 `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0`. |
| marble DTBO | Passed; SHA-256 `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba`. |
| SPSS and GLINK | Included in `vmlinux` after compile and link with the two symbols enabled. |
| BTF | Passed; `BTF` then `BTFIDS` sequence appeared without disabling BTF. |
| Device Tree gates | Passed; `87/36/128/85` for build/base DTB/DTBO/merged DTB, i.e. equal to the reference cap and not higher. |

The verification preserves DTC warnings as-is; these include the previously carried `glink-edge` warnings. The patch contains no changes to DTS files or `reg` or phandle or unit-address, so the known warnings are not attributed to the SPSS change. The raw logs are `reports/spss_marble_full_build_2026-08-20.log` and `reports/dt_gate_spss_recheck_2026-08-20.log`.

> This section proves only static buildability and integration of the patch. No `spss.mdt` firmware is verified, no KMI/vendor manifest, and no UART or recovery plan is implemented on a POCO F5; therefore the SPSS node remains disabled and no boot image or flashing artefact is produced.

## Building the current marble branch tip — AOSP diagnostic

A new reproducible build was run from the tip of branch `marble-6.18-full-port` at commit `d69d5a5daa894488f203f5d59edc04dc15ef4bd1`. The `aosp` flavor with `diagnostic` and `root=none` and `package=none` was used, with Clang `18.1.3` and local pahole `v1.31`. A separate output directory `out/marble-aosp-diagnostic-d69d5` was used; this output or any resulting image is not added to Git.

| Verification item | Result |
|---|---|
| Image ARM64 | Passed; SHA-256 `70cf0ed8e514bcd70bfd00ec008f558afcf94af6eaac82d3cfdcf5f83e011921`. |
| Modules | Passed; `104` `.ko` files. |
| `ukee.dtb` | Passed; SHA-256 `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0`. |
| marble DTBO | Passed; SHA-256 `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba`. |
| BTF | Passed; both `BTF` and `BTFIDS` stages passed in `vmlinux.unstripped` output. |
| Packaging/Flashing | Not performed; `package=none` and `root=none` enforced. |

Historical classified DTC warnings appeared while building `ukee.dtb` and were not hidden or reduced. This run was not an independent rerun of the four `tools/validate_marble_dt_build.sh` gates; therefore the last documented gate result remains `87/36/128/85` and is not attributed as a new result of this build alone. SPSS is also not enabled in the default marble configuration for this build; the separate SPSS verification documented above remains the proof of its static integration.

> Success of this build proves source-tree integration at the branch tip only. It does not prove compatibility with the Evolution X ROM using a 5.10 kernel or with vendor modules or firmware, nor does it open R1/B0 or produce `boot.img` or enable flashing.

## Reproduced BTF Remediation with pahole v1.31

A user-supplied Templar build log did not contain a device boot record; it failed during the kernel build at BTF generation. Its decisive sequence was `Reached the limit of per-CPU variables: 4096`, followed by `BTFIDS vmlinux.unstripped` and `FAILED: load BTF from vmlinux.unstripped: Invalid argument`. This is the same BTF tool limitation documented earlier in this record, rather than a device-runtime failure.

To reproduce the remediation in a clean environment, the official dwarves `v1.31` source tag (`1f2805b6eef104df3125143c949b391f6122e5b9`) was built locally. A small local wrapper exported the dwarves library directory and invoked pahole explicitly; `pahole --version` returned `v1.31`. The build script was verified to forward the `PAHOLE` variable to every relevant Make invocation, including configuration, merge, build, and metadata collection.

A clean `aosp` diagnostic build was then run from commit `9789d28ed8d6c408c246ce79d70fd0e526d3cac4`, with `root=none`, `package=none`, and `PAHOLE=/home/ubuntu/work/tools/pahole-v1.31`. The generated metadata records `pahole_version=v1.31`; the build passed both the `BTF` and `BTFIDS` stages. A subsequent `pahole -F btf -C task_struct vmlinux` invocation succeeded, which proves that the emitted BTF is readable by the same toolchain.

| Verification item | Result |
|---|---|
| Image ARM64 | Passed; SHA-256 `6256cec9a28c4d7fab6a9b078fe793b90436eafb7d3778ecf6aadb260ea26500`. |
| Modules | Passed; `104` `.ko` files. |
| `ukee.dtb` | Passed; SHA-256 `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0`. |
| marble DTBO | Passed; SHA-256 `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba`. |
| `BTF` and `BTFIDS` | Passed without disabling BTF. |
| BTF readability | Passed with `pahole -F btf -C task_struct vmlinux`. |
| Packaging and flashing | Not performed; `package=none` and `root=none` remained enforced. |

This verifies the BTF remediation for this reproducible marble build. It does not validate the different Templar source tree, XClang 22/O3 configuration, AnyKernel packaging, a boot image, or runtime behavior on a POCO F5. The four non-fatal `modpost` prototype warnings observed in the supplied log remain a separate code-quality item and are not suppressed by this result.
