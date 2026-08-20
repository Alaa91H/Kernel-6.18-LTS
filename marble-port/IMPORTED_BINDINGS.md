# Initial bindings patch for SM7475/marble

## Scope

This patch added 15 missing headers under `include/dt-bindings/` from Xiaomi’s reference source `marble-s-oss`, commit `48952ed36228217531482b39d5bef13e7fd808ec`. The imported files carry the `GPL-2.0-only` license present in the source.

| Group | Imported headers |
|---|---|
| clocks | AOP QMP, and camcc/dispcc/gcc/gpucc/videocc for the waipio platform. |
| platform fabric | waipio interconnect, IPCC, DCC v2, DMA heap constants. |
| power/thermal/USB | RPMh regulator levels, USB3 4nm QMP combo, QTI thermal. |
| input | HV haptics and QPnP power-on. |

The hash record for each file is in `reports/marble_dt_bindings_imported.tsv`.

## Verification completed

Device Tree includes were re-parsed after the import. The result was **30 bindings present and 0 missing** under the `include/dt-bindings` path for the ACK tree. This only closes the textual include gap.

> This verification does not prove the existence of driver definitions or clock providers or interconnect providers compatible with these numbers in Linux 6.18. These items remain within DT-002 and DT-003, and no DTB or flashable image must be produced based on headers alone.
