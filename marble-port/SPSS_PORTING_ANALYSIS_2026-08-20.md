# Analysis of Porting SPSS to Kernel 6.18

**Date:** 20 August 2026
**Branch:** `marble-6.18-full-port`
**Status:** Source analysis complete; an SPSS source patch has not been created yet and the device node has not been enabled.

## Primary result

Supporting SPSS in marble is not just adding a compatible entry to the generic PAS driver. Xiaomi's reference runs a custom SPSS loader because it requires a two-stage boot protocol via SCSR registers and IRQ, and a GLINK transport that uses a FIFO in SMEM and announces its address to the SPSS. `RPMSG_QCOM_GLINK_SMEM` does not replace this transport, and the standard `qcom_add_glink_subdev()` cannot use it because it is tied to `qcom_glink_smem`.

| Layer | Xiaomi 5.10 reference | Available counterpart in 6.18 | Outcome |
|---|---|---|---|
| SPSS remoteproc/PAS | `drivers/remoteproc/qcom_spss.c` | PAS, remoteproc, SCM, and MDT loader are available | Requires a separate, adapted SPSS driver, not just a compatible table. |
| Firmware loading | `spss.mdt` and PAS ID `14` | SCM and MDT loader are available | Statically portable; the real firmware is not present in the tree. |
| SCSR/IRQ | `qcom,spss-scsr-bits` and named registers and PBL/SW_INIT state | The migrated node keeps the required properties | The specialized handshake logic must be preserved. |
| GLINK | `qcom_glink_spss.c` with FIFO in SMEM | Native GLINK exists but `pipe` nodes changed | A new/adapted SPSS transport is required. |
| Remote wakeup | Xiaomi variant has no `kick` in pipe nodes | 6.18 effectively requires `kick` | The mailbox in `glink-edge` must be wired as the `kick` and the IRQ should invoke `qcom_glink_native_rx()`. |
| SSC/SSR | SSR/sysmon helpers exist, and sysmon is optional | Helpers exist with stubs when `QCOM_SYSMON` is absent | Sysmon can be kept optional in the initial phase. |
| SPCOM and SPSS utils | Vendor ABI and userspace interfaces | Absent | Out of scope for the minimum; do not port before remoteproc and GLINK work on-device. |

## Installed Device Tree nodes

The `qcom,cape-spss-pas` node in `arch/arm64/boot/dts/qcom/cape.dtsi` remains `status = "disabled"`. It contains a `memory-region`, SCSR registers, bit values, a clock/regulator, and a `glink-edge` child. The GLINK child defines `qcom,remote-pid = <8>` and a mailbox and IRQ and the two registers `qcom,spss-addr` and `qcom,spss-size`.

> The node must remain disabled during the port and static testing. It must not be changed to enabled or have a flash package created before the firmware, ABI, recovery plan, and hardware tests are accepted.

## Required 6.18 interfaces

The proposed driver can reuse `qcom_scm_pas_auth_and_reset()` and `qcom_scm_pas_shutdown()` and the MDT loader and `qcom_register_dump_segments()` and SSR helpers. However, the modern PAS driver relies on `qcom_q6v5` for Q6 sequencing, which is not a substitute for SPSS state nor for SCSR signals.

The GLINK layer needs a clear adaptation from the Xiaomi API to 6.18:

| API difference | Xiaomi reference | Kernel 6.18 | Porting decision |
|---|---|---|---|
| FIFO read | `peak` | `peek` | Rename callback. |
| lifecycle | `probe()` then `start()` then `remove()` and `unregister()` | `probe()` starts negotiation, and only `remove()` | Remove the old start/unregister and allocate/register resources before `probe()`. |
| TX notification | No `kick` in pipe | `kick` is effectively required | Mailbox `spss_spss` should send a notification after write. |
| RX notification | No ISR apparent in the reference transport | `qcom_glink_native_rx()` available | IRQ in `glink-edge` should invoke RX. |

## Proposed minimal patch

1. Add an adapted `qcom_spss.c` to `drivers/remoteproc`, with an independent Kconfig that is not enabled automatically.
2. Add an adapted `qcom_glink_spss.c` to `drivers/rpmsg`, with a mailbox and IRQ and a `kick` callback.
3. Add a small internal header between the two drivers, without porting `spcom` or `spss_utils` or the vendor ABI userspace.
4. Keep `qcom,cape-spss-pas` disabled, and do not change any DTS in the static porting pass.
5. Build the two SPSS objects under `COMPILE_TEST` and then build the full marble; only after that request the firmware, ROM manifest, and a recovery plan to test on-device.

## Current blockers

SPSS runtime cannot be tested without the original `spss.mdt` file and a vendor/firmware image compatible with the target ROM. Nor can it be assumed that the FIFO address or the PAS ID or the ordering of SCSR are valid across ROMs. A successful build only proves API integration, not firmware loading or GLINK operation or boot integrity.

## Local references

1. `/home/ubuntu/work/reference/xiaomi-marble-5.10/drivers/remoteproc/qcom_spss.c`
2. `/home/ubuntu/work/reference/xiaomi-marble-5.10/drivers/rpmsg/qcom_glink_spss.c`
3. `/home/ubuntu/work/Kernel-6.18-LTS/drivers/remoteproc/qcom_q6v5_pas.c`
4. `/home/ubuntu/work/Kernel-6.18-LTS/drivers/rpmsg/qcom_glink_native.c`
5. `marble-port/reports/spss_reference_inventory_raw_2026-08-20.txt`
