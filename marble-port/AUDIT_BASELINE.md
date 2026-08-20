# Audit baseline for marble on Android/GKI 6.18

## Source state

This audit starts from commit `ccab6030dd7afc528fffd40d7ce2c1a0f8223669` on the `marble-6.18-full-port` branch, and the branch was synchronized with `origin/marble-6.18-full-port` and the working tree was clean at inspection. The declared kernel base in the `Makefile` is Linux `6.18.32` within the Android Common Kernel.

| Item | Status | Evidence or impact |
|---|---|---|
| Local BTF tool | `pahole v1.25` | The tool is present, but acceptance of BTF/KMI requires a successful build and explicit verification, not the mere presence of the tool. |
| BTF in the prototype partition | explicitly disabled | `CONFIG_DEBUG_INFO_BTF` and `CONFIG_DEBUG_INFO_BTF_MODULES` are not enabled in `marble_gki_6_18_proto.config`. |
| Current Image/modules output | not available | Full-build outputs were removed during an attempted clean rebuild that did not complete; they must not be submitted as a publishable artifact. |
| Static DT check | available and previously successful | The outputs in `out/marble-dt-6.18` are readable and mergeable, with documented warnings. |
| Device boot proof | not available | There is no serial log or `dmesg` or recovery test from the POCO F5. |

## Integrity baseline

> The phrase “100% ready” does not mean only a successful build or absence of DTC warnings. The kernel only becomes ready to flash if it passes a documented clean build with BTF/KMI, verification of required vendor components, and an actual boot and recovery log on marble.

The previous outputs that documented a successful build of Image and modules remain historical evidence of buildability, but are not currently a deliverable artifact; therefore the build will be redone after fixes are applied and verification mode is enabled.
