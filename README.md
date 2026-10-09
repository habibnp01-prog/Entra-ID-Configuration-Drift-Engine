# Entra-ID-Configuration-Drift-Engine

Detect configuration drift in Microsoft Entra ID against an approved, version-controlled security baseline.

## Status

**Phase 1 — Foundation** complete.

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 | Foundation — structure, config, logging, validation, tests | ✅ Complete |
| 2 | Snapshot engine — Graph auth, collectors, baselines | 🚧 Planned |
| 3 | Drift engine — comparison, structured findings | 🚧 Planned |
| 4 | Policy-as-code — schema, evaluator, exceptions | 🚧 Planned |
| 5 | Additional collectors | 🚧 Planned |
| 6 | Reports and history | 🚧 Planned |
| 7 | Safe remediation | 🚧 Planned |
| 8 | Production readiness | 🚧 Planned |

## Quick Start

```powershell
# Validate engine configuration and dependencies
.\Start-EntraDriftEngine.ps1 -Mode Validate

# Run all Pester tests
.\Start-EntraDriftEngine.ps1 -Mode Test
```

## Requirements

- PowerShell 7.0+
- Microsoft.Graph PowerShell SDK 2.0+ (auto-detected; install with `Install-Module Microsoft.Graph`)
- Pester 5.0+

## License

MIT
