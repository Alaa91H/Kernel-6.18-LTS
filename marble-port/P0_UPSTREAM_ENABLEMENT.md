# P0 upstream enablement for marble 6.18

## Decision and scope

The fragment `marble_gki_6_18_core.config` enables a small P0 layer of drivers present in ACK 6.18, after verifying direct Device Tree node matches in `cape.dtsi`. This is not a copy operation of Evolution X 17/5.10 modules, does not place a module in `vendor_boot` or `vendor_dlkm`, and does not open a packaging or flashing gate.

> The goal is to provision the IPC and shared-memory building blocks required by the following Qualcomm paths, then measure the build, the KMI, and the device before adding any additional driver.

| Symbol | marble node that uses it | driver/binding ACK 6.18 | Reason for enablement |
|---|---|---|---|
| `CONFIG_QCOM_IPCC=y` | `qcom,ipcc@ed18000` with `compatible = "qcom,ipcc"` | `drivers/mailbox/qcom-ipcc.c` and `qcom-ipcc.yaml` | Mailbox and interrupt controller for ADSP/CDSP/modem/AOSS paths. |
| `CONFIG_HWSPINLOCK_QCOM=y` | `hwlock` with `compatible = "qcom,tcsr-mutex"` | `drivers/hwspinlock/qcom_hwspinlock.c` and QCOM binding | Real dependency for SMEM. |
| `CONFIG_QCOM_SMEM=y` | `qcom,smem` with `memory-region = <&smem_mem>` and `hwlocks` | `drivers/soc/qcom/smem.c` | Management of shared memory between processors. |
| `CONFIG_QCOM_SMP2P=y` | `qcom,smp2p-*` nodes tied to IPCC and SMEM | `drivers/soc/qcom/smp2p.c` | Point-to-point state/signaling between APSS and the subsystems. |

`tools/validate_marble_core_config.sh` passed after merging with `olddefconfig` and demonstrated 15 core symbols enabled. `QCOM_SMEM` depends on `HWSPINLOCK`, and `QCOM_SMP2P` selects SMEM state and an IRQ domain; therefore the items are enabled in the same order in a single fragment.

## What was not intentionally enabled

The `qcom,waipio-aoss-qmp` and `qcom,waipio-llcc` nodes do not have direct matches in the current ACK 6.18 drivers/bindings, so `QCOM_AOSS_QMP` and `QCOM_LLCC` were not enabled merely due to name similarity. Also, generic `remoteproc` drivers do not automatically match vendor-specific `qcom,cape-*-pas` compatibles.

The 5.10 reference modules remain unusable, and `evolutionx17_module_porting_contract.tsv` shows only 84 names have an ACK source candidate, while 235 names appear only in the reference and 55 names are not tied to a Makefile source. Each candidate still requires review of bindings, KMI, firmware, and device testing before the DLKM stage.

## Transition gates

| Gate | Required evidence |
|---|---|
| C0 | fragment resolves to `y` in `.config`, and `olddefconfig` and `modpost` succeed. |
| C1 | Image, modules and DTB/DTBO build for each flavor with no regression in the DTC budget. **Successful** at `343b9da858dd`; see `BUILD_VERIFICATION.md`. |
| C2 | KMI list and `Module.symvers` from a hermetic ACK environment; no vendor code outside the allowlist. |
| B1 | IPCC/SMEM/SMP2P probe on POCO F5, with `dmesg` and pstore and without SSR or panic. |

**Current status:** C0 and C1 are successful. C2 and B1 have not been claimed yet, and `--package boot` remains gated.

## References

[1]: https://source.android.com/docs/core/architecture/kernel/modules "AOSP — Kernel modules overview"
[2]: https://source.android.com/docs/core/architecture/kernel/stable-kmi "AOSP — Maintain a stable kernel module interface"
[3]: https://source.android.com/docs/core/architecture/kernel/android-common "AOSP — Android common kernels"
