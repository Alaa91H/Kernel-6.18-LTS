# Out-of-tree Reference Rules for Fixing DTC

## Naming and `reg` rules

The Devicetree specification states that the unit-address portion of a node name must match the first address in the node's `reg` property, and that `@unit-address` must be omitted when there is no `reg`.[1] It also specifies that the encoding of `reg` depends on the parent's `#address-cells` and `#size-cells`, is not inherited from ancestors; cells must be explicitly defined for nodes that contain children.[1]

## Rules for `ranges`

The specification explains that an empty `ranges` declares that the child's and parent's address spaces match, whereas the encoding of a non-empty `ranges` depends on the address- and size-cells of the node and the parent.[1] Therefore cells or `ranges` must not be added or removed solely to silence a warning unless the meaning of the address space and the target node remain correct.

## Linux coding style guideline

The Linux guide recommends using unit addresses as lowercase hexadecimal numbers without leading zeros, and ordering properties as `compatible` then `reg` then `ranges`, but it does not allow sacrificing a binding node or a hardware resource for cosmetic cleanliness.[2]

## Qualcomm ADC channels

The `qcom,spmi-vadc.yaml` binding in ACK 6.18 shows that ADC channel nodes should follow the pattern `channel@[0-9a-f]+` and that `reg` represents the channel number.[3] The ADC thermal monitor binding shows that ADC_TM sensor names include the channel address and that `reg` specifies the sensor's channel.[4] Therefore renaming old channels to compliant names is only a candidate after proving there are no consumers of the name path, while keeping `label`, `reg`, and phandles unchanged.

## References

[1]: https://devicetree-specification.readthedocs.io/en/latest/chapter2-devicetree-basics.html "Devicetree Specification — node names, address cells, reg and ranges"
[2]: https://docs.kernel.org/devicetree/bindings/dts-coding-style.html "Linux Devicetree Sources Coding Style"
[3]: https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/iio/adc/qcom%2Cspmi-vadc.yaml "Qualcomm SPMI PMIC ADC binding"
[4]: https://github.com/torvalds/linux/blob/master/Documentation/devicetree/bindings/thermal/qcom%2Cadc-tm5.yaml "Qualcomm ADC thermal monitor binding"

## GICv3, ITS, and PCIe

The GICv3 binding requires that the GIC node containing the ITS define appropriate `#address-cells`, `#size-cells`, and `ranges` to encode the `reg` in the ITS, and it defines the ITS as an `msi-controller` node with `#msi-cells = <1>`.[5] Therefore MSI warnings under the GIC are not candidates for adding arbitrary cells: they must follow the GICv3/ITS structure specified in the binding and the PCIe MSI mappings should be re-reviewed against a newer Qualcomm source.[6]

[5]: https://www.kernel.org/doc/Documentation/devicetree/bindings/interrupt-controller/arm%2Cgic-v3.txt "ARM GICv3 Device Tree binding"
[6]: https://lkml.iu.edu/hypermail/linux/kernel/2301.0/00391.html "Qcom: Add GIC-ITS support to SM8450 PCIe controllers"
