# Assessment of High-Level Display, Media, and Connectivity Modules

## Static Match Result

The compat strings in marble's Device Tree were matched against the drivers and bindings present in ACK 6.18. `no-exact-match` means the absence of a textual match for the node's definition in the current tree; it does not prove the absence of every possible alternative, but it prevents claiming that the node will work without porting or adaptation.

| Path | marble compatible | ACK 6.18 match result | Porting status |
|---|---|---|---|
| GPU/Adreno | `qcom,adreno-gpu-gen7-4-0` | `no-exact-match` | Blocked on DRM/Adreno adaptation or KGSL port; not enabled in the test kernel. |
| Display controller | `qcom,cape-gpucc` and associated display files | `no-exact-match` | Blocked on a platform-specific clock/display driver. |
| Camera | `qcom,cape-camcc` | `no-exact-match` | Blocked on the camera/ISP driver series and matching vendor userspace. |
| ADSP | `qcom,cape-adsp-pas` | `no-exact-match` | Blocked on remoteproc/firmware path and reserved-memory matching. |
| CDSP | `qcom,cape-cdsp-pas`, `qcom,cdsp-loader`, `qcom,msm-cdsp-rm` | `no-exact-match` | Blocked on vendor DSP definitions and firmware. |
| Modem/QRTR | `qcom,cape-modem-pas`, `qcom,qrtr-mhi`, `qcom,qrtr-gunyah` | `no-exact-match` | Blocked on modem definitions, firmware, and vendor agreement. |
| Audio over Slimbus | `qcom,slim-ngd-v1.5.0` | `upstream-present` in `drivers/slimbus/qcom-ngd-ctrl.c` | Requires further adaptation of the nodes and the codec/DSP; not functionally ready. |
| USB audio QMI | `qcom,usb-audio-qmi-dev` | `no-exact-match` | Deferred until porting of the vendor QMI/USB audio path. |

## Limits of the reference source

The Xiaomi reference contains a private `drivers/gpu/msm` tree, while ACK contains `drivers/gpu/drm/msm`; this architectural difference does not allow a straight file copy. Also, the separate camera/audio/display folders are not present in the available kernel reference; therefore there is no complete source base to claim porting of those functions to 6.18.

> Do not enable GPU, display, camera, audio, or modem just because the Device Tree builds. Acceptance of these paths requires compatible drivers, firmware, vendor modules, and actual device testing.
