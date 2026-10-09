# Contributing

Thanks for your interest. Here is how to contribute.

## Development Setup

1. PowerShell 7.0+
2. Clone the repo
3. `Install-Module Microsoft.Graph -Scope CurrentUser -AllowClobber -Force`
4. `Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck`
5. `.\Start-EntraDriftEngine.ps1 -Mode Test` — confirm 66/66 pass

## Adding a New Collector

1. Create `Modules/Collectors/Get-<Type>.ps1` with a `Get-Drift<Type>` function
2. Follow the existing pattern: check `Test-DriftGraphConnection`, call Graph, return `,$results`
3. Register the collector in `Invoke-ModeCollect` in `Start-EntraDriftEngine.ps1`
4. Add a normalizer call with `ConvertFrom-DriftRawResource`
5. Add Pester tests in `Tests/Unit/Collectors.Tests.ps1` with mocked connection
6. Update `Documentation/Graph-Permissions.md` and `Documentation/Snapshot-Schema.md`

## Adding a New Policy

1. Add to the appropriate file under `Policies/`
2. Pick a stable ID (e.g., `POL-CA-003`)
3. Add a test to `Tests/Unit/PolicyEngine.Tests.ps1`

## Code Style

- PowerShell 7+ syntax only
- `[CmdletBinding()]` on every function
- `[OutputType([PSCustomObject])]` when returning objects
- Use `[AllowEmptyCollection()]` on any `[object[]]` parameter that can be empty
- Return arrays with `,` prefix (`,$result`) to prevent unwrapping
- No hardcoded tenant values, secrets, or certificates

## Testing

- All tests must pass before PR
- Use synthetic fixtures, not live tenant calls
- Mock external dependencies with Pester `Mock`

## Pull Requests

- One feature or fix per PR
- Reference the issue number if applicable
- Update `CHANGELOG.md`
