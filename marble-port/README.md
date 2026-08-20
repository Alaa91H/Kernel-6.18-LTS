# marble port inventory

This directory organizes the reproducible inventory results for porting the POCO F5 (`marble` / SM7475) from the Xiaomi 5.10 reference to Android/GKI 6.18. The results are produced by the following two tools:

```bash
./tools/marble_port_inventory.sh
./tools/marble_dt_closure.sh
```

## Current inventory snapshot

| Item | Result | Meaning |
|---|---:|---|
| Kconfig requests in `marble_GKI.config` | 429 | The scope of the reference configuration published by Xiaomi. |
| Symbols present nominally in ACK 6.18 | 124 | Candidate for review, not for automatic enabling. |
| Symbols nominally missing in ACK 6.18 | 305 | Porting gaps that should be addressed by an issue, patch, or upstream alternative. |
| Modules `modules.list.msm.marble` | 111 | The scope of reference vendor modules. |
| DTS files directly associated with marble/SM7475 | 4 | The starting point for the board definition. |
| Local DTS include closure | 36 | Includes the official `ukee.dtb` overlay base and necessary cape/Qualcomm platform files. |
| External DTS includes | 30 | bindings assumed to exist or be adapted in ACK. |

## Reading order

1. Review `reports/marble_gki_missing_categories.tsv` to identify Kconfig gaps by layer.
2. Review `reports/marble_module_categories.tsv` to separate core modules from diagnostic modules and vendor hooks.
3. Start the Device Tree from `reports/marble_dt_include_closure.txt`, and do not port the overlay file before analyzing its include tree.
4. Review `PORT_ACCEPTANCE.md` before declaring any level of success or creating flashing artifacts.

> The inventory is not a port patch. It prevents the incorrect inference that building a generic GKI alone makes Xiaomi 5.10 definitions compatible with 6.18.
