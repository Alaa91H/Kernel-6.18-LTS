# marble inventory — Xiaomi 5.10 source vs ACK 6.18

This report is generated automatically. It compares the Kconfig symbols in `marble_GKI.config` from the Xiaomi source with the Kconfig symbols available in the current ACK tree, and records Device Tree references and the vendor modules list.

| Domain | Result | Explanation |
|---|---:|---|
| Xiaomi marble config entries | 429 | Kconfig symbols listed in `marble_GKI.config`. |
| Symbols nominally present in ACK | 124 | Manually-reviewable with respect to dependencies and meaning. |
| Symbols nominally absent from ACK | 305 | Cannot be passed automatically; require transplantation or replacement. |
| DTS/DTSI/DTBO files associated with marble or SM7475 | 4 | Extracted from Xiaomi's separate Device Tree repository. |
| marble listed modules | 111 | Reference modules from `modules.list.msm.marble`. |


## Distribution of Kconfig gaps by layer

| Layer | Number of missing symbols |
|---|---:|
| `audio` | 1 |
| `camera` | 2 |
| `diagnostics-and-vendor-hooks` | 28 |
| `graphics-and-display` | 5 |
| `memory-and-interconnect` | 21 |
| `modem-dsp-and-remoteproc` | 19 |
| `other` | 100 |
| `power-and-thermal` | 28 |
| `qualcomm-platform` | 86 |
| `storage` | 4 |
| `wireless-and-peripherals` | 11 |

## Device Tree reference files

- `qcom/marble-pinctrl.dtsi`
- `qcom/marble-sm7475-pm8008-overlay.dts`
- `qcom/marble-sm7475.dtsi`
- `qcom/xiaomi-sm7475-common.dtsi`

## Distribution of modules by functional layer

| Layer | Number of referenced modules |
|---|---:|
| `clocks-and-pinctrl` | 10 |
| `diagnostics-and-vendor-hooks` | 10 |
| `interconnect-memory-and-iommu` | 14 |
| `ipc-virtualization-and-firmware` | 14 |
| `other-vendor-modules` | 15 |
| `peripherals-and-connectivity` | 14 |
| `power-and-scheduling` | 24 |
| `storage-and-crypto` | 10 |

## Distribution of modules by name prefix

| Prefix | Number of modules |
|---|---:|
| `arm` | 1 |
| `bcl` | 1 |
| `bwmon` | 1 |
| `c1dcvs` | 2 |
| `cfg80211` | 1 |
| `clk` | 3 |
| `cmd` | 1 |
| `cpu` | 1 |
| `cqhci` | 1 |
| `crypto` | 2 |
| `dcvs` | 1 |
| `debug` | 1 |
| `deferred` | 1 |
| `dispcc` | 2 |
| `dma` | 1 |
| `extend` | 1 |
| `gcc` | 2 |
| `gdsc` | 1 |
| `gh` | 7 |
| `hwid` | 1 |
| `hwkm` | 1 |
| `icc` | 3 |
| `iommu` | 1 |
| `kryo` | 1 |
| `llcc` | 1 |
| `mac80211` | 1 |
| `mem` | 4 |
| `memory` | 1 |
| `metis` | 1 |
| `mi` | 1 |
| `minidump` | 1 |
| `msm` | 5 |
| `nfc` | 1 |
| `ns` | 1 |
| `nvmem` | 1 |
| `phy` | 5 |
| `pinctrl` | 4 |
| `pmu` | 2 |
| `proxy` | 1 |
| `qcom` | 22 |
| `qnoc` | 3 |
| `qrtr` | 1 |
| `qti` | 2 |
| `reboot` | 1 |
| `regmap` | 1 |
| `rpmh` | 1 |
| `rtc` | 1 |
| `sched` | 2 |
| `secure` | 1 |
| `smem` | 1 |
| `socinfo` | 1 |
| `spmi` | 1 |
| `stub` | 1 |
| `thermal` | 1 |
| `tmecom` | 1 |
| `ufs` | 1 |
| `ufshcd` | 1 |

## Generated files

| File | Purpose |
|---|---|
| `marble_gki_config_present.tsv` | Reference config symbols that are still nominally present in ACK. |
| `marble_gki_config_missing.tsv` | Missing symbols; represent transfer gaps that are not automatically enabled. |
| `marble_gki_missing_categories.tsv` | Distribution of Kconfig gaps by hardware layer. |
| `marble_dts_references.txt` | Reference DTS/DTSI/DTBO files. |
| `marble_module_categories.tsv` | Initial distribution of vendor modules by functional layer. |
| `marble_module_prefixes.tsv` | Initial distribution of vendor modules by name prefix. |

> The nominal presence of a symbol does not prove that its definition or dependencies are compatible with 6.18. Absence does not prove that porting is impossible; it only prevents automated, unreviewed transfer.
