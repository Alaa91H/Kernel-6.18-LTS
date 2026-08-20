# Device Acceptance and Recovery Plan — POCO F5 / marble

## Purpose and Scope

This plan converts fixed build outputs into an actionable verification program on a POCO F5 device. This document does not authorize creation of `boot.img` or flashing any partition; inventorying Evolution X 17 provided matching boot/vendor_boot/dtbo/vendor_dlkm/vendor and firmware images, but demonstrated an ABI mismatch between ROM 5.10.256 and the 6.18 candidate and lack of a reference KMI or device boot record. Stages must be executed in order, preserving the specified evidence for each gate and the SHA-256 used.

> **Blocking rule:** Any failure in recovery or early boot or storage prevents progression to screen, audio, connectivity, or daily system use.

## Mandatory inputs before device testing

| Input | Acceptance condition | Saved evidence |
|---|---|---|
| Test device | Actual POCO F5 (marble), with unlocked bootloader and stable USB access. | Serial number, battery level, and a fastboot state image. |
| Single target ROM | Specify a single ROM version, Android version, and build fingerprint; do not mix artefacts from different releases. | `getprop` and manifest of input images and their fingerprints. |
| Recovery images | Documented copies of boot/vendor boot/dtbo and relevant ROM partitions from the same ROM. | SHA-256 and storage location outside Git and a reviewed restore procedure. |
| Modules and vendor firmware | `vendor_dlkm` and `dlkm` fragment in `vendor_boot` and firmware exactly matching the target ROM; record absence of `system_dlkm` if not present in the payload. | File list, fingerprints, and build fingerprint copy. |
| Log link | `adb` and fastboot and an off-device log preservation method. | Connection test in both system and fastboot. |

## Recovery and Boot Gates

| Gate | Required safe action | Acceptance evidence | Failure result |
|---|---|---|---|
| R0: Inventory | Document original images and their fingerprints and storage location before any modification. | Complete and restorable manifest. | **Completed silently** for Evolution X 17 release dated 2026-08-12; no device testing yet. |
| R1: Recovery | Apply maintainer-reviewed recovery to the original images only and verify system return. | Boot original ROM and matching release log. | Halt; fix the recovery plan first. |
| B0: Artifact compatibility | Compare the target ROM against the planned ABI, modules, vendor firmware, and DTBO. | Compatibility report with no unknown items. | **Failed/blocked currently:** ROM 5.10.256 and DLKM 5.10 are incompatible with 6.18; no packaging or experimental booting is performed. |
| B1: Early boot | Use a restorable test path and references for the specified ROM, then capture early console/logcat. | ADB access, no kernel panic, and an understood reason for any reboot. | Immediate restore; retain logs. |
| B2: Stability | Three consecutive boot/shutdown cycles without panic or unexplained reset. | Logs for each cycle and artefact fingerprints. | Re-isolate to B1. |

## Hardware paths matrix

| Domain | Acceptance test after B2 | Minimum evidence | Current status |
|---|---|---|---|
| UFS and storage | Mount data partitions, repeated read/write, and UFS log without errors. | `dmesg` and I/O smoke log. | DT/setup only; DLKM 5.10 is not reused. |
| RPMh and regulators | Inspect RPMh and regulator messages at boot, idle, and charging. | Regulator summary and dmesg. | DT/setup only. |
| USB and DWC3 | ADB, file transfer, charging mode, and OTG role when accessory available. | `dmesg` and `lsusb`/USB state. | ACK descriptor present; board adaptation not installed. |
| Touch and audio | Input events, speakers/microphone, and reboot after testing. | input/audio logs. | Vendor-only partially. |
| Display and graphics | Stable visible interface, suspend/resume, and no DRM/GPU fault. | logcat/dmesg and screenshots. | Vendor gap prevents claiming support. |
| WLAN and Bluetooth | Scan, connect, and reconnect after airplane mode. | Firmware loading and connectivity logs. | Matching firmware stripped, but CNSS/WLAN 5.10 modules cannot be loaded on 6.18. |
| Modem and camera/DSP | Data call, capture and processing, and power consumption. | Subsystem logs and reproducible steps. | Matching artefacts stripped; vendor porting gap to 6.18 is explicit. |

## Diagnostic logging protocol

Use the `diagnostic` flavor only in the initial investigation, because it enables BTF and dynamic-debug and ftrace and pstore. Link each log file to the commit and `build-metadata.txt` and the Image fingerprint. The tester, after obtaining project ADB access, captures kernel outputs, logcat, pstore, and the cause of the last reboot before wiping the device or attempting any subsequent change.

| Capture point | Required content |
|---|---|
| Immediately after B1 | Kernel log, logcat, properties, `uname -a`, and BTF/build metadata path. |
| After every panic or reboot | pstore/ramoops, last kernel log, reset cause, and recovery log. |
| After each hardware domain | Outputs for the relevant domain with timestamps, battery level, and temperature. |
| Upon passing B2 | Log of three cycles, panic count=0, and a complete artefact index. |

## Conditions for unsealing or flashing

Do not enable the `--package boot` flavor before meeting **all** of the following conditions: specified ROM manifest, installed recovery images, inspected reference ABI/KMI, matching modules and firmware, success of B0–B2, and proven UFS/USB/power paths. Only after that may a separate ROM-specific packaging be prepared and reviewed; this public-source branch remains free of signing keys and proprietary images.

Any future attempt begins with the package [`PRE_DEVICE_READINESS_PACKET.md`](PRE_DEVICE_READINESS_PACKET.md) which converts R0 and R1 and B0 into reviewable evidence, not into flashing instructions. The remaining definition boundaries are linked to [`KCONFIG_DRIVER_AUDIT.md`](KCONFIG_DRIVER_AUDIT.md) and [`MEDIA_VENDOR_GAPS.md`](MEDIA_VENDOR_GAPS.md), and [`EVOLUTIONX17_ARTIFACT_INVENTORY.md`](EVOLUTIONX17_ARTIFACT_INVENTORY.md) documents the ROM input, while [`EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md`](EVOLUTIONX17_COMPATIBILITY_ANALYSIS.md) preserves the reason for blocking B0 and [`BUILD_VERIFICATION.md`](BUILD_VERIFICATION.md) verifies the current build.
