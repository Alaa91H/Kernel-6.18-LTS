# Classification of Device Tree Warnings and Plan for Handling

## Principle of Handling

Device Tree warnings are not addressed by suppressing DTC classes or by adding cosmetic properties. The Devicetree specification states that the unit address must match the first address in `reg`, and that `#address-cells` and `#size-cells` determine the encoding of children’s `reg` and must be explicitly defined on the nodes that contain children.[1] An empty `ranges` also declares that the child’s address space matches the parent’s, so one must not change its cells or the encoding of its resources without verifying both address spaces.[1]

The base and DTBO are built and then a merged DTB is created with `fdtoverlay`, and each output is decompiled by DTC. Therefore the counts below represent actual diagnostics in the build or in the decompilation of the outputs, not a suppression of diagnostics.

| Metric | Baseline referenced | Measurement after patches applied | Reduction |
|---|---:|---:|---|
| DTS/DTBO build log | 126 | **87** | 39 |
| DTB decompile baseline | 50 | **36** | 14 |
| single DTBO decompile | 153 | **128** | 25 |
| merged DTB decompile | 99 | **85** | 14 |

## Fixes Implemented and Applied

| Group | Original issue | Source fix | Semantic verification and result |
|---|---|---|---|
| `ramoops` and `mtdoops` | Nodes used unit names in the form `@0x…` that deviate from the standard format. | Renamed to `@a7000000` without changing `reg` or any phandle. | Pure renaming correction; there are no references to the name path in the current tree. |
| `&soc` in Xiaomi overlay | `mtdoops` nodes in the overlay did not have an explicit cells context when examined standalone. | Declared `#address-cells = <1>` and `#size-cells = <1>` compatible with the Cape bus. | Diagnostics decreased from the previous baseline without any change to the reserved resource. |
| Single-port CoreSight graph | Graph containers with a single port used `port@0` and unnecessary cells. | Converted to `port` when actual numbering is absent. | Closed all `graph_child_address` warnings without changing labels or endpoint phandles. |
| GICv3/ITS | Missing GIC address/size cells left ITS nodes and PCIe mappings structurally incomplete. | Added `#address-cells = <1>` and `#size-cells = <1>`, the two-cell encoding actually used in the Cape `reg` (`address,size`). | Kept the ITS `reg` as-is, since its current representation `<0x17140000 0x20000>` already matches the new nodes. |
| PCIe `interrupt-map` | After declaring the GIC address cell, each map jumped directly from phandle to IRQ spec. | Added a zero parent-address cell after `&intc` to entries for PCIe0 and PCIe1. | Closed **10** `interrupt_map` diagnostics; IRQ numbers and MSI maps remained unchanged. |
| QUP I²C/SPI overlays | The standalone DTBO assumed default cells `2/1` while the underlying QUP buses use `1/0`; this caused `reg_format` and prerequisite errors. | Re-declared `#address-cells = <1>` and `#size-cells = <0>` in SE13 SPI, SE15 I²C and SE4 SPI overlays, with literal values from `waipio-qupv3.dtsi`. | Closed IR SPI, Smart PA, touch and related `i2c_bus_reg` and `spi_bus_reg` errors. I²C addresses and chip-selects did not change. |
| USB overlay | Modification of `dwc3@a600000` lacked USB bus context and `reg` when building the overlay standalone. | Re-declared USB cells `1/1` and `reg = <0xa600000 0xd93c>` literally matching the base. | Closed the DWC3 unit-address warning in the DTBO; the final merged DTB value did not change. |
| `reserved-memory` overlay | Repeating an empty `ranges;` within a fragment caused DTC to compare the overlay’s default cells with the target’s `2/2` cells. | Removed the duplicated `ranges` property; the correct `ranges` property remains in the base `reserved-memory`. | Closed `ranges_format` and fragment-context warnings without removing a reserved region from the merged DTB. |

## Remaining Warnings and Decision on Handling

| Group | Status after current measurement | Reason for not performing an automated change | Condition for proper closure |
|---|---:|---|---|
| `unit_address_vs_reg` for ADC/ADC_TM channels | The majority of the remaining **74** warnings. | The ADC5 binding prefers the `channel@<reg>` pattern, but the migrated PMIC tree contains multiple vendor-specific names and `reg` values that may be repeated across different PMIC/ADC sources. Changing the name alone does not prove uniqueness of the unit address nor prove that the driver or DTBO vendor does not rely on the name. | A matching binding for each PMIC with a full review of the range of each VADC, or a boot and IIO/thermal test proving that renaming each node preserves channels and calibrations. |
| SPSS/GLINK | One `reg_format` warning in `glink-edge` and its dependent prerequisites, plus `ranges_format` and cells-context warnings. | `remoteproc-spss` uses an empty `ranges`, while the migrated `glink-edge/reg` is encoded as pairs. Converting it to the standard `2/2` encoding requires changing every tuple, and there is no binding or local consumer proving the parser for `qcom,spss-addr` and `qcom,spss-size` properties. | A Qualcomm matching binding or source driver, then testing SPSS/GLINK on actual hardware. |
| Vendor nodes with `@` but no `reg`, or `reg` without a unit name | Includes LPC/PWM/clock/PCIe root-port and guest VM and CoreSight and some interconnects. | It is not permissible to add a fake `reg` or remove `@` from nodes that are selected by the driver/vendor firmware by name or by order. | An official binding or corresponding driver source, with testing of the affected functionality. |
| DTBO plugin and external references | Some warnings in the standalone DTBO are caused by phandles and targets that are resolved only by `fdtoverlay`. | They do not constitute a defect in the merged DTB, and it is not appropriate to copy the resource or phandle from the base to satisfy the standalone DTBO check except when a matching bus property is copied literally as in QUP and USB above. | Only addressed if they remain after merging or if the target property is proven to match the base literally. |

> **Current truthful result:** the counts decreased from `126/50/153/99` to **`87/36/128/85`** without disabling DTC or changing IRQ numbers or I²C/SPI/MSI resources. It is not correct to claim that the warnings are zero; the remainder requires binding/vendor source or hardware verification, not renaming or filling cosmetic properties.

## Permitted Fix Patches

A patch is accepted only when it preserves `compatible` and `reg` resources and phandles and driver behavior, or when it repeats in the overlay a bus value that exists literally in the base DTS in order to allow DTBO checking in its real context. After each patch the DTB and DTBO must be built and merged, and the four diagnostics measured again. Any increase in warnings or an unjustified resource change stops the patch and it is reanalyzed.

## Non-negotiable Barriers

The Device Tree describes hardware and is used by Linux to select and configure devices, but it does not automatically create missing vendor or firmware definitions.[2] Therefore display paths and the GPU, camera, audio, DSP and modem cannot be fixed merely by removing DTC warnings. These paths remain gated by vendor definitions and firmware and by testing on a physical POCO F5.

## References

[1]: https://devicetree-specification.readthedocs.io/en/latest/chapter2-devicetree-basics.html "Devicetree Specification — node names, cells, reg and ranges"
[2]: https://docs.kernel.org/devicetree/usage-model.html "Linux and the Devicetree"
