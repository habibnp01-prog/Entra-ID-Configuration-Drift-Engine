# Entra-ID Configuration Drift Engine

[![Test](https://github.com/habibnp01-prog/Entra-ID-Configuration-Drift-Engine/actions/workflows/test.yml/badge.svg)](https://github.com/habibnp01-prog/Entra-ID-Configuration-Drift-Engine/actions/workflows/test.yml)
![PowerShell](https://img.shields.io/badge/PowerShell-7.0%2B-blue)
![Tests](https://img.shields.io/badge/tests-66%20passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

**Detect configuration drift in Microsoft Entra ID against an approved, version-controlled baseline.**

## What It Does

1. **Collects** normalized snapshots of Entra ID configuration (CA policies, roles, apps, service principals, OAuth grants)
2. **Approves** baselines from reviewed snapshots
3. **Detects** drift — added, removed, and modified resources
4. **Evaluates** declarative security policies in JSON
5. **Tracks** findings across runs with first/last-detected timestamps
6. **Reports** as CSV, JSON, or a styled HTML dashboard
7. **Plans** remediation without touching the tenant
8. **Applies** safe remediation only when explicitly confirmed

## Quick Start

```powershell
git clone https://github.com/habibnp01-prog/Entra-ID-Configuration-Drift-Engine.git
cd Entra-ID-Configuration-Drift-Engine
.\Start-EntraDriftEngine.ps1 -Mode Validate
.\Start-EntraDriftEngine.ps1 -Mode Collect
.\Start-EntraDriftEngine.ps1 -Mode Baseline
.\Start-EntraDriftEngine.ps1 -Mode Assess
.\Start-EntraDriftEngine.ps1 -Mode Report
```

## Modes

| Mode | Purpose |
|------|---------|
| `Validate` | Config + module check |
| `Collect` | Fetch tenant config, write normalized snapshot |
| `Baseline` | Promote a snapshot to an approved baseline |
| `Assess` | Compare latest baseline vs latest snapshot |
| `PolicyCheck` | Evaluate JSON policies against a snapshot |
| `Report` | Generate CSV, JSON, HTML from findings |
| `Plan` | Generate a remediation plan without changes |
| `Test` | Run Pester tests |

## Requirements

- PowerShell 7.0+
- Microsoft.Graph PowerShell SDK 2.0+
- Entra ID tenant with these app permissions (Application, admin consent required):
  - `Policy.Read.All`
  - `Directory.Read.All`
  - `Application.Read.All`
  - `RoleManagement.Read.Directory`

## Documentation

- [Architecture](Documentation/Architecture.md)
- [Installation](Documentation/Installation.md)
- [Authentication](Documentation/Authentication.md)
- [Graph Permissions](Documentation/Graph-Permissions.md)
- [Snapshot Schema](Documentation/Snapshot-Schema.md)
- [Policy Authoring](Documentation/Policy-Authoring.md)
- [Risk Model](Documentation/Risk-Model.md)
- [Remediation Safety](Documentation/Remediation-Safety.md)
- [Troubleshooting](Documentation/Troubleshooting.md)
- [Limitations](Documentation/Limitations.md)

## Running Tests

```powershell
.\Start-EntraDriftEngine.ps1 -Mode Test
```

66 tests, all mocked — no live tenant required.

## Safety

Read-only by default. No tenant changes without `-Apply`. Every applied change is verified.

## License

MIT — see [LICENSE](LICENSE)
