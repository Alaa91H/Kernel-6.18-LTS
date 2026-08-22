# Marble Vendor Module Candidate Ledger

**Status:** generated static evidence; not a boot or compatibility result.

This report classifies every filename gap reported by the existing Evolution X 17 ABI audit. It verifies only whether public-source Makefile candidates named by the earlier contract are present in the supplied Xiaomi 5.10 and ACK 6.18 trees. It does not compare binaries, preserve a 5.10 ABI, prove a matching Kconfig symbol, resolve every firmware dependency, or authorize a boot-image package.

| Metric | Value |
|---|---:|
| First-stage filename gaps | 97 |
| Vendor-load filename gaps | 285 |
| Unique filename gaps | 382 |
| Ledger rows | 382 |
| ACK revision | `34a6e975936c4cc616ce4fad1e6dec31c1e3c59c` |
| Xiaomi kernel revision | `48952ed36228217531482b39d5bef13e7fd808ec` |

## Disposition Summary

| Ledger disposition | Count | Static meaning |
|---|---:|---|
| defer/disable | 243 | No native vendor-load plan is evidenced. |
| proprietary-blocked | 55 | Unresolved public-source candidate; blocks B0. |
| upstream | 84 | ACK candidate exists; native configuration/build and KMI review remain. |

## Reading Rules

The `ack_kconfig_present` column means that a nearby Kconfig file exists for the target Makefile path; it does **not** assert that a module-specific symbol is enabled or that its value is correct. The `likely_dt_firmware_contract` column is an intentionally conservative review prompt rather than an inferred hardware fact. A `proprietary-blocked` disposition means no verified public candidate is recorded in this input set; it does not establish that the module is definitely proprietary.

Every row retains a **BLOCKED** B0 effect. The required next evidence remains a native 6.18 configuration and build plan, vendor ramdisk/load-order plan, DTB/DTBO container evidence, firmware and userspace-ABI evidence, AVB/recovery evidence, and only then controlled device logs. No 5.10 module may be copied into this plan.

See `LEDGER_INPUT_PROVENANCE.txt` for exact inputs and the ledger hash. The TSV is the normative machine-readable record.
