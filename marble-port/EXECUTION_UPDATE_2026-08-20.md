# marble execution update — 20 August 2026

**Author:** Manus AI
**Source branch:** `marble-6.18-full-port` at commit `32ffe3adde922d2b927c4849af186317d9dd8643`
**Round scope:** qualifying a reproducible static build, installing Xiaomi references, and re-measuring the Device Tree. The scope does not include producing flash images, flashing a device, or claiming a successful boot.

## Executive summary

This round succeeded in converting a build environment blocker into a successful full AOSP diagnostic build from a clean tree, producing an `Image` and 104 modules plus BTF and DTB/DTBO artifacts. Official installed Xiaomi references for the `marble-s-oss` branch were also brought in and used to check closure, bindings tree, and an inventory of transfer gaps. The full Device Tree verification passed all reviewed ceilings: `87/36/128/85` for build warnings, DTB, DTBO, and integrated DTB respectively.

> This does not prove flashability or bootability on the POCO F5. SPSS/GLINK contracts and ADC channels, Kconfig/vendor module gaps, ABI/vendor compatibility for images, and on-device recovery testing remain explicit blockers.

| Acceptance area | Result | Evidence |
|---|---|---|
| Clean source tree | Passed | `source_tree_clean=yes` in the build metadata. |
| Full AOSP diagnostic build | Passed | `Image`, `vmlinux`, and 104 modules were produced from the clean tree. |
| BTF | Passed | `pahole v1.31` read `task_struct` from `vmlinux`. |
| DTB and DTBO | Passed | `ukee.dtb` and `marble-sm7475-pm8008-overlay.dtbo` exist and are non-empty. |
| DTBO merging and unpack outputs | Passed within ceiling | The integrated checker passed at `87/36/128/85`. |
| Device Tree includes | Passed | 36 local includes and 30 external bindings; all bindings present. |
| Targeted GLINK matching | Passed within scope | `dt-validate -l qcom,glink-edge` exited 0; the log contains only a general schema ignore unrelated to the node. |
| Device compatibility or flashing | Not executed/blocked | No ROM manifest or ABI/vendor DLKM installed and no confirmed device/recovery plan. |

## Verification and reproducibility environment

`pahole` was built locally from the official tag `v1.31` of the dwarves project, then used via a local wrapper that sets dynamic library paths. This represents satisfying the BTF constraint in the build script; it does not by itself convert generic host tools into a qualified Android release toolchain.[1]

The build was run from a separate clean worktree, with:

```text
PAHOLE=/home/ubuntu/work/tools/pahole-v1.31 \
OUT_DIR=/home/ubuntu/work/Kernel-6.18-LTS-build/out/marble-aosp-diagnostic-local \
tools/build_marble_flavor.sh --flavor aosp --diagnostics diagnostic --root none --package none
```

| Artifact | Size or value | SHA-256 where applicable |
|---|---:|---|
| `Image` | 46,086,656 bytes | `403cf2aee8a049feea0ad75df481a5715af3f3ec8be0b143d53e59f1a1522a33` |
| `ukee.dtb` | 378,971 bytes | `1577e93bbae7e1e954305ec5d2d6479b4353585b3e8cdb60563482e763eb64f0` |
| `marble-sm7475-pm8008-overlay.dtbo` | 68,967 bytes | `1121e209271bf822597413508b4de8d1d050a75e2c946cff3634a1fc36ac8dba` |
| `vmlinux` | 233,344,896 bytes | Produced with readable BTF. |
| kernel modules | 104 | Produced in the diagnostic build. |

## Xiaomi references and static auditing

Two official Xiaomi references were installed on the `marble-s-oss` branch: the Device Tree repository at `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0`, and the Kernel 5.10 repository at `48952ed36228217531482b39d5bef13e7fd808ec`.[2] [3] The first was used to check DTS/DTSI/DTBO includes and to compare moved marble files; the second was used to inventory `marble_GKI.config` settings and `modules.list.msm.marble`.

| Reference audit result | Count | Verdict |
|---|---:|---|
| Local include files in closure | 36 | Closed in the current tree. |
| External `dt-bindings` required | 30 | All present; missing `0`. |
| Xiaomi 5.10 config requests | 429 | Reference for review, not for automatic enabling. |
| Symbols nominally present in ACK | 124 | Require dependency and semantic review. |
| Symbols nominally absent in ACK | 305 | Transfer gaps; must not be copied or enabled automatically. |
| Xiaomi reference modules | 111 | Require ABI and vendor auditing before any merge. |

File matching showed that `marble-pinctrl.dtsi` and `xiaomi-sm7475-common.dtsi` match the Xiaomi reference literally, and the PM8008 overlay also matches its reference with a local filename extension difference `.dtso`. Differences in `marble-sm7475.dtsi` are previously-documented bus-context fixes for QUP I²C/SPI and additions of ADC bindings; this round did not add any new Device Tree source changes.

## Device Tree re-measurement

AOSP documents that DTSs are compiled into DTBs and that DTO is applied by the bootloader over a base DTB, so this round examined the base, overlays, and the integrated DTB rather than only standalone DTBO.[4]

| Verification gate | Actual result | Reviewed ceiling | Verdict |
|---|---:|---:|---|
| DTS/DTBO build warnings | 87 | 87 | Passed |
| Base DTB unpack | 36 | 36 | Passed |
| Standalone DTBO unpack | 128 | 128 | Passed |
| Integrated DTB unpack | 85 | 85 | Passed |

The log audit also produced 87 raw DTC diagnostics. The largest category is `unit_address_vs_reg` with 74 occurrences; there is one `reg_format` warning and two `avoid_default_addr_size` warnings for the `glink-edge` node belonging to SPSS. These raw categories do not map one-to-one to the four gate measurements and therefore should not be used as a substitute for the build/merge checker.

## SPSS and GLINK: decision not to modify

The definition of `remoteproc-spss@1880000` and its child `glink-edge` in `cape.dtsi` matches the installed Xiaomi reference, including the pair in `reg` and `reg-names = "qcom,spss-addr", "qcom,spss-size"`. The final SPSS node in `ukee.dtsi` also keeps state `disabled`. Searching ACK source shows that `qcom_common.c` looks for a child named `glink-edge`, but it does not establish parser significance for SPSS-specific properties nor justify changing the `reg`/`ranges` encoding.

Therefore the cells were not changed to `2/2` and no cosmetic properties were added to suppress warnings. A binding or the matching Qualcomm driver source for SPSS is required, followed by an actual on-device test before any modification. This decision aligns with Device Tree rules that make `#address-cells` and `#size-cells` and `reg` and `ranges` part of the hardware node rather than cosmetic text.[5]

## Limitations and steps required before device

A successful build is only a static gateway. The current round contains no documented original ROM images, no manifest for `boot`/`vendor_boot`/`dtbo`/`vendor_dlkm` partitions, no KMI/ABI proof for vendor modules, and no R1 recovery test. The 305 Kconfig gaps and 111 reference modules were not addressed; these are an audit to-do list, not a patch queue.

The next safe automated step is to create a review table of compatible → driver → CONFIG → ABI/vendor dependency for the integrated DTB, prioritizing storage, power, and remoteproc families. The first on-device step should not begin until receipt of a manifest for a single target ROM and recoverable original images and confirmation of UART/`pstore` access.

## Files produced by the round

| File | Purpose |
|---|---|
| `marble-port/reports/dtc_warnings_recheck_2026-08-20.tsv` | Raw DTC diagnostics for DT rebuilds. |
| `marble-port/reports/dt_validate_glink_recheck_2026-08-20.log` | Result of isolated GLINK binding check. |
| `marble-port/reports/marble_dt_include_closure.txt` | List of local Device Tree includes. |
| `marble-port/reports/marble_dt_external_includes.txt` | External bindings used. |
| `marble-port/reports/marble_dt_bindings_summary.tsv` | Result `30 present / 0 missing`. |
| `marble-port/reports/INVENTORY.md` | Inventory of Kconfig, modules, and references. |
| `marble-port/reports/execution_web_sources_2026-08-20.md` | Record of public sources and installed commits. |

## References

[1]: https://github.com/acmel/dwarves/tree/v1.31 "acmel/dwarves — v1.31"
[2]: https://github.com/MiCode/kernel_devicetree/tree/marble-s-oss "MiCode kernel_devicetree — marble-s-oss"
[3]: https://github.com/MiCode/Xiaomi_Kernel_OpenSource/tree/marble-s-oss "MiCode Xiaomi Kernel OpenSource — marble-s-oss"
[4]: https://source.android.com/docs/core/architecture/dto "Android Open Source Project — Device tree overlays"
[5]: https://devicetree-specification.readthedocs.io/en/latest/chapter2-devicetree-basics.html "Devicetree Specification — node names, cells, reg and ranges"
