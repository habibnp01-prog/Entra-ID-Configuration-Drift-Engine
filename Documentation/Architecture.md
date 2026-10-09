# Architecture

## Module Boundaries

```
Modules/
  Authentication/     Connect-DriftGraph, Test-DriftGraphConnection, Disconnect-DriftGraph
  Collectors/         One function per resource type (CA policies, roles, apps, SPs, OAuth grants)
  Snapshots/          Normalization, snapshot creation, JSON export
  Baselines/          Approved baseline creation and validation
  Comparison/         Resource diff engine, property-level drift detection
  PolicyEngine/       Policy loading, rule evaluation, dot-path resolution
  Findings/           Structured finding creation and conversion
  History/            First/last detection tracking, resolution detection
  Remediation/        Plan generation, safe execution with -Apply gate
  Reporting/          CSV, JSON, HTML output
  Logging/            Structured console + file logging
  Validation/         Config, module, and structure checks
```

## Data Flow

```
Config/EngineConfig.json
        |
        v
Connect-DriftGraph  ->  Microsoft Graph
        |
        v
Collectors (CA policies, roles, apps, SPs, OAuth grants)
        |
        v
ConvertFrom-DriftRawResource  ->  Normalized snapshot
        |
        v
Baselines/baseline-*.json  (approved baseline)
        |
        v
Compare-DriftResources  ->  Added / Removed / Modified
        |
        v
ConvertTo-DriftFindings  ->  Structured findings
        |
        v
Invoke-DriftPolicyCheck  (independent policy evaluation)
        |
        v
Reports (CSV, JSON, HTML)  +  History tracking
        |
        v
New-DriftRemediationPlan  ->  Opt-in remediation with -Apply
```

## Design Principles

1. **Read-only by default.** No collector or analyzer modifies tenant state.
2. **Normalized snapshots.** Every resource type is projected into a common shape.
3. **Deterministic comparison.** Stable JSON serialization means stable diffs.
4. **Structured findings.** Every finding has `FindingId`, `Severity`, `ExpectedValue`, `ObservedValue`.
5. **Explicit opt-in for remediation.** `-Apply` gate + `SupportsShouldProcess`.
6. **No fabricated success.** Collectors fail loudly; findings are evidence-backed.
7. **Strict boundaries between concerns.** Collectors do not analyze; comparison does not report.

## Extension Points

To add a new resource type:

1. Add a collector under `Modules/Collectors/Get-<Type>.ps1`
2. Register it in `Invoke-ModeCollect`
3. Optionally add a policy file under `Policies/<Type>.json`
4. Add Pester tests with synthetic fixtures
5. Update `Documentation/Graph-Permissions.md`
