# Work Log of Porting marble to GKI 6.18

## Statuses

| Status | Meaning |
|---|---|
| `blocked` | Cannot technically start until a specific dependency is closed. |
| `researched` | The reference and dependencies are documented, but there is no port patch. |
| `in-progress` | A small patch is under development or review. |
| `static-validated` | The patch has passed build and static checks only. |
| `hardware-validated` | Proven on POCO F5 with a boot log or functional test. |

## Device Tree and Platform Layout

| Identifier | Atomic task | Status | Dependencies | Acceptance criterion |
|---|---|---|---|---|
| DT-001 | Adapt 15 missing bindings in ACK or identify upstream alternatives for them. | `static-validated` | headers imported from Xiaomi and record `marble_dt_bindings_imported.tsv`. | 30 external includes textually present; providers verification deferred to DT-002/DT-003. |
| DT-002 | Port base `ukee.dtb` and `ukee.dtsi` and SoC cape/SM7475 layer. | `static-validated` | DT-001 and Qualcomm L1 layer. | Builds `ukee.dtb` and supports applying the overlay statically; DTC warnings documented. |
| DT-003 | Port reserved-memory, IOMMU, interconnect, and clocks for the platform. | `in-progress` | DT-002. | Patch-specific `dtbs_check` verification and presence of reference nodes. |
| DT-004 | Port `marble-sm7475.dtsi` and `marble-pinctrl.dtsi`. | `static-validated` | DT-002 and DT-003. | The board integrates statically over the ukee base; hardware verification still required. |
| DT-005 | Port overlay `marble-sm7475-pm8008-overlay.dtso`. | `static-validated` | DT-004 and PMIC/regulator. | Builds DTBO and applies via `fdtoverlay` on `ukee.dtb`; DTC warnings documented. |

## Kernel Configs and Modules

| Identifier | Atomic task | Status | Dependencies | Acceptance criterion |
|---|---|---|---|---|
| KC-001 | Review 124 Kconfig symbols nominally present in ACK. | `researched` | `marble_gki_config_present.tsv`. | For each symbol, a decision to enable or disable with rationale. |
| KC-002 | Categorize 305 missing symbols into upstream alternative, port patch, or unsupported. | `researched` | `marble_gki_config_missing_categories.tsv`. | No enabled symbols remain without a documented decision. |
| MOD-001 | Classify 111 reference modules into boot, vendor, and diagnostic. | `researched` | `marble_module_categories.tsv`. | A minimal list of modules buildable without vendor-only APIs. |
| MOD-002 | Rebuild core platform modules according to final KMI/BTF. | `blocked` | KC-001 and KC-002 and DT-002. | Modules load on the test device with no unresolved symbols. |

## Functional Paths

| Identifier | Path | Status | Minimal dependencies | Acceptance criteria |
|---|---|---|---|---|
| BOOT-001 | UFS, USB, serial, and reboot reason | `blocked` | DT-002, DT-003, MOD-001. | Actual boot and recovery log. |
| PWR-001 | PMIC, regulator, RPMh, and thermal | `blocked` | DT-002, DT-005, KC-002. | Suspend/resume and charging without kernel panic. |
| NET-001 | Wi-Fi/BT/CNSS and QRTR/modem | `blocked` | BOOT-001, vendor modules, firmware. | Connectivity test and modem log. |
| UI-001 | display, touch, and GPU | `researched` | PWR-001, DT-004, display/Adreno drivers. | ACK gaps documented in `MEDIA_VENDOR_GAPS.md`; device display and graphics remain unverified. |
| MEDIA-001 | audio, DSP, and camera | `researched` | NET-001 and UI-001 and vendor drivers. | ACK gaps and missing full source documented; functional testing still blocked. |

> Items marked `blocked` are not abandoned: they mean that dependency ordering prevents producing a misleading patch until the platform base is buildable and verifiable.
