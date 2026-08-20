# P1 Wave — PMIC and Device Tree for marble 6.18

## Decision and Scope

This wave adds the first provable PMIC control path directly into the Android Common Kernel 6.18. It does not carry over any binary or module from Evolution X 17/5.10, nor does it produce `boot.img` or `vendor_boot.img` or `vendor_dlkm.img`.

> **Acceptance criteria:** A driver is not enabled just because its name matches a reference module. There must be a Device Tree node actually in use, a `compatible` that matches an `of_match` entry in ACK 6.18, Kconfig dependencies resolved to `y`, and then building and testing a device before declaring success.

| Item | marble evidence | ACK 6.18 evidence | Decision |
|---|---|---|---|
| SPMI PMIC Arbiter | `spmi0_bus` and `spmi1_bus` in `cape.dtsi`, both `qcom,spmi-pmic-arb` | `drivers/spmi/spmi-pmic-arb.c` matches `qcom,spmi-pmic-arb`; symbol `SPMI_MSM_PMIC_ARB` | Enabled as `y` in the base fragment. |
| UFS/QMP | marble's UFS nodes use the common path; `SCSI_UFS_QCOM` and `PHY_QCOM_QMP_UFS` enabled by default | driver present and enabled by default | No change; device testing required. |
| RPMh/SCM | RPMh nodes and sources available in ACK | `QCOM_RPMH` and `QCOM_RPMHPD` and `REGULATOR_QCOM_RPMH` and `QCOM_SCM` enabled by default | No change; device testing required. |
| LLCC/AOSS/TSENS waipio | board-specific compatibles present in the DT | no direct `of_match` in ACK 6.18 for the existing compatibles | Blocked; no experimental enablement. |
| Watchdog | no marble node matching the `qcom-wdt.c` table | `QCOM_WDT` present but has no installed target node | Blocked; no experimental enablement. |

## Configuration and build changes

`marble_gki_6_18_core.config` adds the symbol `CONFIG_SPMI_MSM_PMIC_ARB=y`. `tools/validate_marble_core_config.sh` checks this symbol among 16 core symbols, and replaces previous assignments when fragments are merged so the validation/build environment does not produce artificial `override: reassigning` warnings. Ordered merging preserves `diagnostic` precedence over `proto`, including re-enabling BTF in diagnostic flavors.

## Validated Device Tree fixes

Address/size cells and unnecessary `reg` were removed from three single-port CoreSight containers, and `port@0` was changed to `port`. Endpoint labels and `remote-endpoint` references remain unchanged, and there are no references to moved node paths. Building DTB and DTBO and decoding them and applying overlays succeeded after the change.

| DTC metric | before patch | after patch | delta |
|---|---:|---:|---|
| build log | 129 | 126 | -3 |
| decode `ukee.dtb` | 53 | 50 | -3 |
| decode DTBO | 154 | 153 | -1 |
| decode merged DTB | 103 | 99 | -4 |

`tools/validate_marble_dt_build.sh` tightens its default budgets to `126/50/153/99`, therefore any regression to these warnings or any new regression will fail. This does not mean the zero-condition is met; remaining warnings require bindings or vendor drivers or hardware testing.

## Transition gates

| Gate | Status | Evidence required to pass |
|---|---|---|
| P1-C0 — configuration | Passed | `olddefconfig` and `modpost` with `SPMI_MSM_PMIC_ARB=y`. |
| P1-C1 — static DT | Passed | DTB/DTBO/merged-DTB readable and conform to the tightened budget. |
| P1-C2 — KMI/DLKM | Blocked | KMI baseline for marble and `Module.symvers` hermetic and 6.18 modules rebuilt. |
| P1-B1 — PMIC probe | Blocked | actual POCO F5 log: SPMI count, PMIC children, ADC, and absence of panic or never-ending deferred probe. |

Passing P1-C0/P1-C1 does not open packaging or flashing gates. Evolution X 17 modules with ABI 5.10 remain unusable with this 6.18 output.

## References

[1]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"
[2]: https://docs.kernel.org/devicetree/usage-model.html "Linux and the Devicetree"
