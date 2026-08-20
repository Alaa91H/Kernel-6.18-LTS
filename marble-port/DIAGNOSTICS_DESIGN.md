# Monitoring and Diagnostics Policy for marble

## Diagnostic flavors

| Component | `release` | `diagnostic` | Reason for separation |
|---|---|---|---|
| BTF and debug info | Required to verify KMI when supported by the build tool. | Also required. | BTF is not a substitute for device testing but is an important precondition for interface inspection. |
| pstore/ramoops | The baseline GKI support remains enabled. | Adds persistent ftrace when the configuration build passes. | Retains panic/oops logs across reboot, but its success requires reserved memory and device testing. |
| ftrace | Only the baseline GKI support remains. | `FUNCTION_TRACER` and`FUNCTION_GRAPH_TRACER` and`FTRACE_SYSCALLS` and`BOOTTIME_TRACING`. | Enables pinpointing boot stalls or functional regressions; not enabled by default in the release. |
| dynamic debug | Disabled by default. | Enabled; debug rules are not written to cmdline by default. | Allows selective control of driver logs without flooding the release log. |
| watchdog/lockup/hung workqueue | Current GKI settings remain enabled. | Remain enabled with their output included in the health report. | They capture soft/hard lockups and RCU/workqueue stalls. |
| KASAN/KFENCE/UBSAN | No new options are added on top of GKI. | Do not force KASAN or LOCKDEP from a common fragment. | These tools have memory and performance impacts and require a separate test kernel, ROM package, and device testing. |

## State present in baseline GKI

The current GKI configuration enables `PSTORE` and `PSTORE_RAM` and `PSTORE_CONSOLE` and `PSTORE_PMSG` and `DEBUG_FS` and `FTRACE` and `KPROBE_EVENTS` and `KALLSYMS_ALL` and `STACKTRACE` and `FRAME_POINTER` and `MAGIC_SYSRQ` and watchdog/RCU stall detection and `KFENCE` and `UBSAN`. `DYNAMIC_DEBUG` and `FUNCTION_TRACER` and `PSTORE_FTRACE` are not enabled in the baseline flavor; they are appropriate to be part of a separate `diagnostic`.

## Diagnostics verification gate

A successful Kconfig or the presence of the `ramoops` node does not prove log persistence. Device testing must prove the presence of `/sys/fs/pstore` after a monitored panic or intentional reboot in a recovery environment, inspect the ftrace buffer, and prove there is no reboot loop. Do not promote panic keys or fault injection or permanent trace commands to the `release` flavor.

> Actual failure diagnosis is a chain of evidence: an image with symbols and proper debug, a preserved serial or pstore log, a post-boot `dmesg`, and source code matching the image fingerprint. There is no single Kconfig option that makes the kernel «monitored 100%».
