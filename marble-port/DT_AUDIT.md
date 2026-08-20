# Device Tree Audit for marble

## Audit methodology

This audit covers three independent levels: the build log of `ukee.dtb` and `marble-sm7475-pm8008-overlay.dtbo`, decoding each blob with `dtc -I dtb -O dts`, then applying the DTBO to the DTB with `fdtoverlay` and decoding the result. The presence of a readable file is not evidence of valid phandle references or operability on hardware.

| Inspection level | DTC warning count | Outcome |
|---|---:|---|
| Build log of both blobs | 126 | Build does not fail, but emits structural warnings. |
| Decoding `ukee.dtb` | 50 | Base platform warnings are visible in the resulting blob. |
| Decoding the DTBO alone | 153 | Includes fragment and phandle warnings not all of which appear in the build log. |
| Decoding the merged DTB | 99 | A substantial subset of warnings remains after merging. |

## Build log warning distribution

| Category | Count |
|---|---:|
| `unit_address_vs_reg` | 75 |
| `avoid_default_addr_size` | 16 |
| `interrupt_map` | 10 |
| `reg_format` | 7 |
| `ranges_format` | 3 |
| `graph_child_address` | 0 |
| `unit_address_format` | 1 |
| Categories entailed by `reg_format` or `avoid_default_addr_size` requirements | 16 |

All files that emit warnings appear in the change list since the initial kernel commit used by the project. The most warning-dense files in the build log are `marble-sm7475.dtsi` (25 warnings), `cape.dtsi` (22), `pmk8350.dtsi` (18), `xiaomi-sm8475-common.dtsi` (12), `cape-pmic-overlay.dtsi` (12), and `cape-pcie.dtsi` (12).

## Verified structural observations

Most `unit_address_vs_reg` warnings arise from ported ADC and ADC_TM channel nodes that include `reg` without a unit-address suffix in the node name. The `reg_format` warnings arise from I²C/SPI nodes in fragments where DTC infers inherited address/size cells that do not match the length of `reg`. The `interrupt_map` warnings indicate missing `#address-cells` on the interrupt controller node referenced by PCIe nodes.

> Decode warnings for the DTBO and the merged blob—especially GPIO, thermal, and interrupt phandle references—must not be silenced by disabling DTC checks. It is necessary to demonstrate that the nodes, bindings, and definitions present in ACK represent the ported board’s properties before any modification.

## Result of a validated safe fix

The reserved-memory node was corrected from `ramoops@0xa7000000` to `ramoops@a7000000` while keeping `reg` unchanged. That reduced the build log from 130 to **129 warnings** and removed its `unit_address_format` warning. Then three single-port CoreSight containers were converted from `port@0` with `reg` and address/size cells to `port`, preserving endpoint labels and their references. This patch reduced the metrics to **126/50/153/99** for the build, DTB, DTBO, and merged DTB, and removed all `graph_child_address`. Adding address/size cells to the GIC and SPSS containers was also tested, but it caused DTC to treat the containers as simple-bus and raised the warnings to 276; therefore the change was reverted and not merged. This is a deliberate negative test that prevents a patch that appears syntactically correct but changes the tree’s semantics.

## Reproducible outputs

`tools/audit_marble_dtc_warnings.sh` generates a structured report at `marble-port/reports/dtc_warnings_current.tsv` from the build log. The decode numbers above remain a primary piece of evidence for this state, and the round-trip test must be re-run after each batch of fixes.

`tools/validate_marble_dt_build.sh` enforces a reviewed baseline budget of `126/50/153/99` for build, DTB, DTBO, and merged DTB warnings. This budget hides no messages; the tool fails upon introduction of a new warning or the return of the removed CoreSight warnings. A zero-warning condition has not yet been achieved.
