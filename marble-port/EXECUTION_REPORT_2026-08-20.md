# Execution Report for Experiment Readiness Round — POCO F5 (`marble`)

**Round date:** 20 August 2026

**Working branch:** `marble-6.18-full-port`

**Commit inspected:** `32ffe3add`
**Round decision:** **No Device Tree changes, no packaging, no flashing.**

> This round applied the entry rule in the readiness plan before any source modification. The authoritative tree carrying the full port and the patch history is `marble-6.18-full-port`, not the public `main` branch. Verification showed that the last documented stable check of the branch passed the four DTC gates at `87/36/128/85`, but re-verification on this host stopped before the DTC stage due to a missing LLVM toolchain. Therefore, there is no “after this round” value that can be claimed, and there is no reasonable basis to change ADC or SPSS or vendor nodes.

## Scope of execution and assurances

I reviewed the full-port branch history, the `marble` and Cape sources, the warning classification logs, the build and verification tools, and the device acceptance plan. No DTC diagnostic class was disabled, and no `reg` or `phandle` or IRQ or I²C/SPI/MSI or node-name properties were modified. No flashiable `boot.img` or `vendor_boot.img` or `dtbo.img` images were produced.

The verifier enforces explicit non-zero budgets as rollback prevention ceilings, builds DTB and DTBO and then merges them with `fdtoverlay`, and decompiles all outputs with DTC. This matches the principle that gate success does not come from silencing warnings.[1] [2]

## Four-gate table

| Scope of measurement | Before this round: last documented stable verification | After this round | Result status |
|---|---:|---:|---|
| Specified DTS/DTBO build record | 87 | Not measured | **Blocked in bootstrap**: no `clang` on the host, so `make` stopped at building `fixdep` before creating any DTB. |
| Unpack `ukee.dtb` | 36 | Not measured | **Blocked**: no new DTB was built in this environment. |
| Single DTBO unpack | 128 | Not measured | **Blocked**: no new DTBO was built, and `dtc`/`fdtoverlay` are unavailable. |
| DTB unpack after merge | 85 | Not measured | **Blocked**: no new base/overlay outputs exist to merge. |

The baseline above is the result of the documented stable verification after patching DTC bindings, not the result of this host. It decreased from `126/50/153/99` to `87/36/128/85` after GICv3/ITS fixes and PCIe interrupt maps and QUP/USB bus context and `reserved-memory` fixes, without disabling DTC.[1] [3]

## Table of new fixes

No source patches were applied in this round. This is a project-level round closure, not a shortcut: the task criteria prohibit touching nodes that do not have a proven binding or driver or tested hardware behavior.

| Group | Original issue | Source fix in this round | Semantic verification |
|---|---|---|---|
| ADC/ADC_TM channels | `unit_address_vs_reg` warnings distributed across multiple vendor/PMIC channels. | No modification. | Renaming alone is insufficient; each channel requires an appropriate PMIC binding and review of `reg` and IIO/thermal testing on the device.[3] |
| SPSS/GLINK | `reg_format` and `ranges_format` in `glink-edge` with dependent prerequisites warnings. | No modification. | There is no Qualcomm source or binding in this round’s environment that proves the parser and ownership of `qcom,spss-addr`/`qcom,spss-size`; converting cells would be a guess.[3] |
| vendor nodes and PCIe/CoreSight/guest VM | Node naming or resource is part of a driver or firmware agreement. | No modification. | Do not add fabricated `reg` properties or remove `@` without a binding or driver source and functional testing.[3] |
| external DTBO references | The plugin’s standalone check differs from the merge tree. | No modification. | Only addressed after the remaining defect post-merge or in a bus context that matches the rule literally.[3] |

## Updated remaining items

| Status | Reason for not modifying automatically | Proper closure condition |
|---|---|---|
| **Deferred: rebuild the four gates** | The round host lacks `clang` and `ld.lld` and `llvm-ar` and `pahole` and `dtc` and `fdtoverlay` and Python `dtschema`. The verification gate failed at the first `clang` call. | Android/LLVM toolchain matching the tree, a readable installed `pahole`, DTC including `fdtoverlay`, and `dt-schema`; then run `tools/validate_marble_dt_build.sh` from a clean tree. |
| **Deferred: include closure for Xiaomi sources** | The DT completion tool expects `../reference/xiaomi-marble-devicetree/qcom`, and that reference tree is not present in the round environment. | The Xiaomi/Qualcomm source matching the target ROM at the expected path, or passing it explicitly, then regenerate the include closure report. |
| **Deferred: ADC/ADC_TM** | Remaining warnings do not prove that renaming alone preserves channels and calibration. | Matching binding for each PMIC, review of VADC range, then IIO/thermal from a real boot.[3] |
| **Deferred: SPSS/GLINK** | No proof of a parser or vendor source in the round package justifies converting cells. | Matching Qualcomm binding/driver and testing loading `remoteproc-spss` and GLINK on the device.[3] |
| **Deferred: compatibility and DLKM** | Branch history proves a known ABI incompatibility between the 6.18 filter and the Evolution X 17 ROM with 5.10; a DTB alone is not enough to overcome it. | One target ROM with reference KMI, compatible drivers/firmware and vendor modules or verified ported alternatives.[1] [4] |
| **Out of scope: Devicetree-external** | Display, GPU, camera, audio, DSP, and modem rely on drivers and firmware and vendor layers. | Per-path functional acceptance after passing boot/storage/power gates; silencing DTC is not a closure.[4] |
| **Blocked: flashing or packaging** | No POCO F5/UART device is available here, no original recovery images with a reproducible recovery result, and B0 is blocked due to ABI. | Complete R1 then B0–B2 per the acceptance plan: reproducible installer, artefact compatibility, UART/ADB/pstore, and three stable boot cycles.[4] |

## First boot log

There is no UART log nor any boot or flashing attempt in this round, by design. That cannot be substituted with a static build result or an older recorded log.

| Required field | Round result |
|---|---|
| First successful event | Not available; no boot attempt was made. |
| First blocker | Local bootstrap failed at `clang: No such file or directory` before building host tools; this is not a Device Tree-attributed failure. |
| Relevant UART excerpt | Not available; requires an actual POCO F5 with UART and matching ROM images and an exercised recovery path. |

## Deferred blockers outside this round

The next readiness step remains gated by a specific input set: a reference Device Tree synchronized with a single target ROM, bindings or Qualcomm sources required for ADC5 and SPSS/GLINK, a matching Android toolchain, original `boot`/`vendor_boot`/`dtbo`/`vendor_dlkm` images with manifest and checksums, a `marble` device with an open bootloader and UART, and a reproducible R1 recovery. The acceptance plan explicitly prohibits flashing before verifying B0–B2 and demonstrates that vendor paths are not closed merely by a successful DT build.[4]

## Impact on the tree

Only this report was added. No DTS files or bindings or drivers or Kconfig or build scripts were touched. Therefore this round does not claim a new successful build nor a new decrease in DTC counters nor readiness for experimentation nor flashability.

## References

[1]: https://github.com/Alaa91H/Kernel-6.18-LTS/blob/marble-6.18-full-port/marble-port/BUILD_VERIFICATION.md "marble build and verification log"
[2]: https://github.com/Alaa91H/Kernel-6.18-LTS/blob/marble-6.18-full-port/tools/validate_marble_dt_build.sh "Merged DTB and DTBO verification gate"
[3]: https://github.com/Alaa91H/Kernel-6.18-LTS/blob/marble-6.18-full-port/marble-port/DT_WARNING_CLASSIFICATION.md "Device Tree warning classification"
[4]: https://github.com/Alaa91H/Kernel-6.18-LTS/blob/marble-6.18-full-port/marble-port/DEVICE_ACCEPTANCE_PLAN.md "Device acceptance and recovery plan"
