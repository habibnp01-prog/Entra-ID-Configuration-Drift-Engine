function Test-DriftProjectStructure {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$RootPath = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
    )

    $expected = @(
        "Start-EntraDriftEngine.ps1",
        "Config/EngineConfig.json",
        "Config/RiskThresholds.json",
        "Config/Exceptions.json",
        "Modules/Logging/Write-DriftLog.ps1",
        "Modules/Validation/Test-EngineConfiguration.ps1",
        "Tests/Unit/Config.Tests.ps1"
    )

    $missing = @()
    foreach ($rel in $expected) {
        $full = Join-Path $RootPath $rel
        if (-not (Test-Path $full)) { $missing += $rel }
    }

    [PSCustomObject]@{
        IsValid = ($missing.Count -eq 0)
        Missing = $missing
    }
}
