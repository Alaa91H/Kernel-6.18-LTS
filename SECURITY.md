# Security Policy

## Supported scope

The `main` branch and the latest tagged pre-release are the only repository states considered for security reports. This is an experimental, non-flashable source-build prototype; no claim is made that a reported issue is device-reproducible until it is independently validated.

## Reporting a vulnerability

Please **do not** open a public issue for a suspected security vulnerability. Use GitHub’s private vulnerability-reporting feature for this repository when available, or contact the repository owner privately through the contact method listed on the GitHub profile. Provide the affected revision, reproduction steps, expected and actual behaviour, impact assessment, and any proof-of-concept that can be shared safely.

Do not include secrets, private keys, proprietary firmware, personal data, account credentials, or full exploit material in a public report or pull request.

## Response process

Reports are triaged for reproducibility and scope. If confirmed, the intended sequence is acknowledgement, remediation design, private validation, coordinated disclosure, and a tagged release containing the fix. Timing depends on impact, reproducibility, maintainer availability, and upstream coordination requirements.

## Scope boundaries

The repository does not accept security claims based solely on packaging, ROM, firmware, or vendor artifacts that are absent from this tree. Reports involving Android Common Kernel or Linux upstream code may require responsible coordination with the relevant upstream maintainers.
