# B0 Static Re-evaluation: Marble 6.18 Vendor/KMI/Boot Readiness

**Decision:** **BLOCKED**

**Decision class:** static evidence review, not a device test

**Target branch:** `marble-6.18-full-port`

**Author:** Manus AI

**Recorded:** 2026-08-22

## Executive Decision

The static-source and text-only evidence phases are complete. Public Xiaomi kernel and Device Tree references have been restored at fixed revisions, every one of the **382** reported Evolution X 17 filename gaps has a generated ledger row, and the ledger checker passes its internal completeness and integrity checks. This is meaningful progress in evidence quality, but it does **not** make B0 green.

> **B0 remains blocked.** The current evidence does not provide a complete native 6.18 vendor module set, a measured vendor ramdisk and load order, a matched DTB/DTBO container and selector mapping, firmware and userspace ABI contracts, AVB partition-policy evidence, an exercised original-ROM recovery route, or any device boot log.

The explicit B0 result is expected and correct. Converting an honest block into a pass would require unsupported assumptions about proprietary artifacts and runtime hardware behavior.

## Evidence Closed Statically

| Gate item | Result | Verification evidence | Scope limit |
|---|---|---|---|
| Xiaomi kernel reference | Closed | Public `marble-s-oss` resolved to `48952ed36228217531482b39d5bef13e7fd808ec` | Public source candidates only. |
| Xiaomi Device Tree reference | Closed | Public `marble-s-oss` resolved to `4e89193c78ea0ca0e8134a0b8d5cf0457e015df0` | Does not select the production board/overlay. |
| Gap-set coverage | Closed | 97 first-stage and 285 vendor-load names reconcile to 382 unique ledger rows | Names are not module ABI contracts. |
| Ledger schema/integrity | Closed | 14-field TSV records, no duplicate module names, source-list phase flags match, provenance SHA-256 matches | Internal consistency only. |
| Source-port policy | Closed | Any future `source-port` record is required to contain verified Xiaomi, ACK, and Kconfig candidate paths | Current ledger has zero such fully evidenced rows. |
| No 5.10 module reuse proposal | Closed | Checker rejects a ledger/provenance proposal to copy or reuse a 5.10 `.ko` | Does not prove all external workflows will obey the rule. |
| Local candidate KMI baseline | Closed previously | Reproducible local BTF/`Module.symvers` baseline is retained in the existing KMI review | It is not an Android-certified product KMI. |
| Raw candidate build/BTF checks | Closed previously | Documented diagnostic build and BTF/BTFIDS checks passed using pahole v1.31 | No hardware probe was performed. |

## Ledger Outcome

| Ledger disposition | Count | B0 interpretation |
|---|---:|---|
| `upstream` | 84 | ACK target candidate exists. Native configuration, build form, dependency/load-order, KMI, DT, firmware, and runtime review remain. |
| `source-port` | 0 | No row currently has the complete verified Xiaomi-to-ACK candidate evidence required for a source-port plan. |
| `defer/disable` | 243 | A native vendor-load disposition has not been evidenced. These names cannot be silently dropped if required by the target boot phase. |
| `proprietary-blocked` | 55 | No verified public source candidate was recorded by the input contract. This does not prove proprietary status, but it is an unresolved B0 block. |
| **Rows with a B0 block** | **382** | Every observed filename gap still needs evidence beyond static classification. |

The first-stage subset is especially restrictive: **25** names have ACK candidate paths and **72** remain deferred. The existing first-stage vendor load list therefore cannot be treated as a ready-to-stage 6.18 `vendor_boot` plan.

## Unavoidable External Dependencies

| Required evidence | Why static public sources cannot replace it | Required future action | B0 state |
|---|---|---|---|
| Matching-ROM partition and header manifest | The exact `boot`/`vendor_boot`/`init_boot`/`recovery`/`dtbo`/`vbmeta*` topology, header format, offsets, compression and slot policy are artifact-specific | Lawfully acquire and measure the matching ROM artifacts outside Git; record hashes and metadata only | Blocked |
| Native 6.18 early-module set | Public source paths do not establish config, module form, dependencies, signing policy, or loadability | Implement/review native ports or ACK selections; produce deterministic module/load metadata and KMI evidence | Blocked |
| Exact vendor ramdisk layout | Existing 5.10 module lists do not describe a valid 6.18 fragment, CPIO ownership, SELinux, fstab, init-import or load order plan | Generate and offline-validate a native staging manifest only after early-module evidence is complete | Blocked |
| DTB/DTBO container and selector mapping | DTS filenames cannot prove bootloader selection or the exact hardware variant | Extract and compare the matching container/entries; make property changes only with binding/source evidence | Blocked |
| Firmware and userspace contracts | Firmware, HAL, DSP/modem, QMI, SELinux and property behavior are not determined by kernel compilation | Complete the evidence-only BOM and source/interface review; later capture controlled runtime logs | Blocked |
| AVB policy | Root of trust, chain descriptors and rollback policy are device/build specific | Record non-secret partition-policy evidence; do not handle private signing keys in this repository | Blocked |
| R1 original-ROM recovery rehearsal | A recovery recommendation and prior success report do not prove a rehearsed rollback path for a new kernel experiment | User performs and records a matching-artifact recovery/restore rehearsal | Blocked |
| Controlled device boot evidence | A build cannot demonstrate storage, init, display, radio, thermals, charging, recovery, or safety | Only after all prior gates are green, perform a reviewed test with serial/pstore/recovery capture and restoration result | Blocked |

## Packaging Decision

No `boot.img`, `vendor_boot.img`, DTBO container, AnyKernel archive, firmware bundle, module bundle, signing key, or flashing instruction is authorized by this decision. The existing raw Image prerelease remains a **static build artifact only**. It must not be expanded into a purportedly testable package while B0 and R1 are blocked.

The next technically valid work is evidence acquisition and native-source engineering, not image assembly. The detailed workstream order and the AOSP background for vendor modules, vendor boot, generic boot, and AVB are retained in [the static evidence plan](STATIC_VENDOR_BOOT_EVIDENCE_PLAN_6.18.md).[1] [2] [3] [4]

## Reproduction Record

The following commands are intentionally text-only and do not create or flash an image. They demonstrate only that the ledger is complete relative to its committed audit inputs and that the expected B0 denial is still enforced.

```text
tools/generate_marble_vendor_ledger.sh \
  --xiaomi-root /path/to/Xiaomi_Kernel_OpenSource-marble-s-oss \
  --ack-root /path/to/Kernel-6.18-LTS \
  --audit-dir marble-port/reports/evolutionx17_rom_abi_audit \
  --contract marble-port/reports/evolutionx17_module_porting_contract.tsv \
  --output-dir marble-port/reports/marble_vendor_ledger_2026-08-22

tools/check_marble_vendor_ledger.sh --root /path/to/Kernel-6.18-LTS
# Expected: LEDGER_VALID followed by B0_STATUS BLOCKED.

tools/check_marble_vendor_ledger.sh --root /path/to/Kernel-6.18-LTS --require-b0-green
# Expected: non-zero exit because B0 is deliberately not green.
```

## References

[1]: STATIC_VENDOR_BOOT_EVIDENCE_PLAN_6.18.md "Static vendor and boot evidence plan"
[2]: XIAOMI_REFERENCE_PROVENANCE_2026-08-22.md "Xiaomi source-reference provenance"
[3]: reports/marble_vendor_ledger_2026-08-22/MARBLE_VENDOR_MODULE_LEDGER_SUMMARY.md "Generated vendor-module candidate ledger summary"
[4]: PRE_DEVICE_READINESS_PACKET.md "Existing R0/R1/B0/B1/B2 readiness packet"

<!-- cspell:ignore ACK AVB BTF DTB DTBO DTS KMI OFRP QMI SELinux SM7475 TSV -->
