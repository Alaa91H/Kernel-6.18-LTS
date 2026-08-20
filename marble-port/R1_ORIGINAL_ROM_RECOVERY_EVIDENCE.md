# R1 Guide Template — Current ROM Recovery for POCO F5 / `marble`

**Status:** Proof-only template. Does not include download, flashing, or packaging commands, and does not authorize testing Kernel 6.18.

## Purpose

R1 does not test ADC_TM7 or SPSS nor the 6.18 filter. Its sole purpose is to prove that the POCO F5 itself can be restored to the **same Evolution X 12.1 currently running** via a known recovery path, and that the system returns to an observable healthy state. B0 or B1 are not opened automatically after R1; compatibility with 6.18, vendor modules, and firmware remains an independent barrier. [1] [2]

> Do not start R1 unless the device owner is prepared to restore the current ROM themselves, and has independent storage for copies and recovery evidence. Any ambiguity in the recovery, artifacts, or their origin means **STOP**.

## Documented target identity before R1

| Field | Available value | Status |
|---|---|---|
| Device | `Xiaomi POCO F5 / marble` | Verified from About phone screenshot. |
| Current ROM | Evolution X 12.1, Android 17 | Verified from About phone screenshot. |
| Build date | `Wed Aug 12 00:34:51 UTC 2026` | Verified from About phone screenshot. |
| Build number | `CP2A.260605.016` | Verified from About phone screenshot. |
| Current Kernel | `5.10.256-Alchemist-LTO` | Verified from About phone screenshot. |
| Reference ZIP | `EvolutionX-17.0-20260812-marble-12.1-Official.zip` | Name consistent with link; SHA-256 not calculated yet. |
| Reported recovery | `OFRP-R11.1_7_RECOVERY-Beta-marble.img` | Owner reported it works and marble maintainer recommends it; the version fingerprint and recommendation text have not been saved yet. |

## Required evidence before the R1 dry-run

Do not mark "pass" based on memory or verbal claim only. Store each piece of evidence outside Git, with serial, IMEI, and personal information redacted.

| Required evidence | Acceptance criterion | Current status |
|---|---|---|
| recovery source | Link or message from the marble maintainer proving the specified OFRP is the recommended path for the current ROM | Incomplete. |
| recovery identity | Screenshot from About page inside recovery or visible name/version, with the source filename | Incomplete. |
| recovery fingerprint | SHA-256 or MD5 computed for a local copy and matching the published reference if the source is the same | Incomplete. |
| ZIP ROM | Accessible copy of the named file, preferably with SHA-256; do not upload the archive to Git | Name present; fingerprint deferred temporarily. |
| independent recovery storage | A readable dedicated path that preserves artifacts and logs off-device | Incomplete. |
| USB connection | Proof of stable connection on the system and within recovery, if the recovery path depends on it | Incomplete. |
| supported recovery | Version-matching steps from the maintainer or a trusted source, reviewed by a second person | Incomplete. |

## Definition of R1 success

R1 is only recorded as successful if the device owner demonstrates, after using the approved recovery path on the **current ROM only**, the following items:

| Post-recovery evidence | Success criterion |
|---|---|
| System return | Phone boots into the same Evolution X 12.1, showing `marble` and Android 17 and build number `CP2A.260605.016` or the documented matching build fingerprint. |
| Boot integrity | No kernel panic or unexplained reboot during the initial boot. |
| Diagnostic logs | kernel log, logcat, and pstore if present, saved outside Git with the operation timestamp and artifact fingerprint. |
| Underlying storage | No UFS, mount, or I/O errors visible in the initial log. |
| USB | Normal USB connectivity is restored in the system, and any exception is clearly recorded. |
| Operation log | Start and end time, recovery type, ROM used, result, and any error or recovery step. |

## STOP conditions

Stop and do not proceed to B0 or B1 if any of these conditions occur: recovery file of unknown origin, mismatch of ROM or recovery, loss of the recovery path, an unclear storage or boot defect, absence of logs after the attempt, or reliance on artifacts from Android 13–15 without explicit acceptance from the current ROM maintainer. Do not let a successful compile or a general recommendation of a recovery file substitute for on-device recovery evidence.

## After R1

After all R1 evidence is complete, the decision remains **STOP regarding Kernel 6.18** until a B0 report is prepared demonstrating KMI/ABI and vendor modules and firmware and DTBO compatibility. Do not create `boot.img` or `vendor_boot.img` nor begin ADC_TM7 or SPSS testing solely because R1 succeeded. [1] [2]

## References

[1]: [R0 draft for Evolution X](R0_EVOLUTIONX17_20260812_MANIFEST_DRAFT.md)
[2]: [Device and recovery acceptance plan](DEVICE_ACCEPTANCE_PLAN.md)
