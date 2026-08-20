# Device Tree Build Status for marble

## Deterministic Build Result

The following Device Tree targets were successfully built using LLVM and the GKI arm64 configuration with `CONFIG_OF_OVERLAY=y`:

| Output | Size | SHA-256 | Status |
|---|---:|---|---|
| `ukee.dtb` | 379,047 bytes | `1d07d5ad9da131569901f3a5656bcf06e643fb1c664d826c65414bb5cbf1f5a8` | Built with the `-@` symbols required for overlay. |
| `marble-sm7475-pm8008-overlay.dtbo` | 68,799 bytes | `5c73e0d1f6ee5ee5fbb5ba4cf9ac61a77c494bdfcd02d31c3170c3e956fd3e62` | Built successfully. |
| `ukee-marble-merged.dtb` | 427,762 bytes | `2b7970d274d6f61131f1a32e49ca7d366d67cc84310580be33ee48d7986a7d67` | Result of successfully applying the DTBO via `fdtoverlay`. |

The result can be reproduced via:

```bash
./tools/build_marble_dt.sh
```

## Remaining DTC Warnings

The build succeeded with **130 warnings**. These warnings are not compile errors, but they prevent promoting the status to `hardware-validated` or creating a flash package.

| Warning category | Count | Remediation note |
|---|---:|---|
| `unit_address_vs_reg` | 75 | Platform node unit-addresses in overlays must be normalized to the `reg` value. |
| `avoid_default_addr_size` | 16 | Address/size cells must be explicitly set in overlay nodes. |
| `interrupt_map` | 10 | Address cells for moved GIC/PCIe nodes need to be reviewed. |
| `reg_format` | 7 | The `reg` format needs review after adapting platform address cells. |
| `ranges_format` and `simple_bus_reg` | 5 | Caused by bus and address settings in the cape. |
| `graph_child_address` | 3 | Graph nodes with a single child must be normalized. |
| `pci_device_reg` and `pci_device_bus_num` and `i2c_bus_reg` and `spi_bus_reg` | 8 | Warnings secondary to `reg_format` issues. |
| `avoid_unnecessary_addr_size` and `unique_unit_address` and `unit_address_format` | 6 | Node definitions and addresses need normalization. |

## Conclusion

This stage achieves a **deterministic build** of the DTB and the DTBO and their merge process; it does not achieve booting. 29 non-conflicting files were imported from the reference closure, and 7 conflicting PMIC files from the Xiaomi reference were adapted because the overlay symbols required do not exist in ACK. Addressing the warnings, matching drivers and clock providers, and an actual boot log remain necessary preconditions before any flashing.

## Unified Kernel Rebuild

As of the current build date, `build_marble_gki_6_18_proto.sh` succeeded after merging `marble_gki_6_18_core.config` and `marble_gki_6_18_proto.config`. The `Image` and `modules` targets and only the two specified marble DT artifacts (`qcom/ukee.dtb` and `qcom/marble-sm7475-pm8008-overlay.dtbo`) were built; the script does not use the aggregate `dtbs` target because some unrelated QCM6490 boards fail in this modified tree.

| Verification item | Result |
|---|---|
| kernel release | `6.18.32-4k-g338cadfa614d-dirty` |
| Image SHA-256 | `b9779fc07a0887ed05f5cf208ae20a2e6dbc67f541890a051e847dfd31488f7c` |
| Built modules | 104 `.ko` files |
| Resulting DT artifacts | 2 (`ukee.dtb` and `marble-sm7475-pm8008-overlay.dtbo`) |
| BTF | Temporarily disabled in the proto stage; KMI validation is not accepted until it is re-enabled. |

> The `dirty` tag in the release name reflects that the build script's commit had not been created at build time. The build is repeated after the commit in a subsequent check to obtain a fingerprint from a clean source.
