#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet("Collect","Baseline","Assess","PolicyCheck","History","Report","Plan","Validate","Test","All")]
    [string]$Mode = "Validate",

    [string]$TenantId,
    [string]$ConfigPath   = (Join-Path $PSScriptRoot "Config/EngineConfig.json"),
    [string]$BaselinePath,
    [string]$PolicyPath,
    [string]$OutputPath   = (Join-Path $PSScriptRoot "Reports"),
    [datetime]$Since,
    [switch]$WhatIf,
    [switch]$PassThru,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

function Show-EngineBanner {
    if ($Quiet) { return }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Entra-ID Configuration Drift Engine" -ForegroundColor Cyan
    Write-Host ("  v0.1.0  |  Mode: {0}" -f $Mode) -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Invoke-ModeValidate {
    Write-DriftLog -Message "[1/2] Validating engine configuration..." -Level Info -Component "Validate"
    $configTest = Test-EngineConfiguration -ConfigPath $ConfigPath
    if (-not $configTest.IsValid) {
        foreach ($i in $configTest.Issues) {
            Write-DriftLog -Message ("  - {0}" -f $i) -Level Warning -Component "Validate"
        }
        throw ("Configuration validation failed with {0} issue(s)." -f $configTest.Issues.Count)
    }
    Write-DriftLog -Message "[OK] Configuration valid." -Level Success -Component "Validate"

    Write-DriftLog -Message "[2/2] Checking required modules..." -Level Info -Component "Validate"
    $mods = Test-DriftRequiredModules -RequiredModules $configTest.Config.requiredModules
    $mods | Format-Table Name, MinimumVersion, InstalledVersion, Status -AutoSize | Out-String | Write-Host

    $missing = @($mods | Where-Object { $_.Status -ne "OK" })
    if ($missing.Count -gt 0) {
        $names = ($missing | ForEach-Object { $_.Name }) -join ", "
        Write-DriftLog -Message ("Install missing modules: {0}" -f $names) -Level Warning -Component "Validate"
        return [PSCustomObject]@{ Mode = "Validate"; IsValid = $false; Issues = $missing }
    }
    Write-DriftLog -Message "[OK] All required modules present." -Level Success -Component "Validate"
    return [PSCustomObject]@{ Mode = "Validate"; IsValid = $true; Issues = @() }
}

function Invoke-ModeTest {
    Write-DriftLog -Message "Running Pester tests..." -Level Info -Component "Test"
    $testsPath = Join-Path $root "Tests"
    if (-not (Test-Path $testsPath)) { throw ("Tests directory not found: {0}" -f $testsPath) }
    $result = Invoke-Pester -Path $testsPath -Output Detailed -PassThru
    Write-DriftLog -Message ("Tests: {0} passed, {1} failed" -f $result.PassedCount, $result.FailedCount) -Level Info -Component "Test"
    if ($result.FailedCount -gt 0) { throw ("{0} test(s) failed." -f $result.FailedCount) }
    return [PSCustomObject]@{ Mode = "Test"; Passed = $result.PassedCount; Failed = $result.FailedCount }
}

function Invoke-ModeNotImplemented {
    param([string]$ModeName, [string]$Reason)
    Write-DriftLog -Message ("Mode {0} is not implemented yet." -f $ModeName) -Level Warning -Component $ModeName
    Write-DriftLog -Message ("Reason: {0}" -f $Reason) -Level Info -Component $ModeName
    Write-DriftLog -Message "This will be delivered in a later phase." -Level Info -Component $ModeName
    return [PSCustomObject]@{ Mode = $ModeName; Status = "NotImplemented"; Reason = $Reason }
}

Show-EngineBanner
. (Join-Path $root "Modules/Load-Modules.ps1")

$result = switch ($Mode) {
    "Validate"     { Invoke-ModeValidate }
    "Test"         { Invoke-ModeTest }
    "Collect"      { Invoke-ModeNotImplemented -ModeName "Collect"     -Reason "Requires Graph authentication and collector modules (Phase 2)." }
    "Baseline"     { Invoke-ModeNotImplemented -ModeName "Baseline"    -Reason "Requires snapshot engine (Phase 2)." }
    "Assess"       { Invoke-ModeNotImplemented -ModeName "Assess"      -Reason "Requires drift comparison engine (Phase 3)." }
    "PolicyCheck"  { Invoke-ModeNotImplemented -ModeName "PolicyCheck" -Reason "Requires policy engine (Phase 4)." }
    "History"      { Invoke-ModeNotImplemented -ModeName "History"     -Reason "Requires history storage (Phase 6)." }
    "Report"       { Invoke-ModeNotImplemented -ModeName "Report"      -Reason "Requires reporting modules (Phase 6)." }
    "Plan"         { Invoke-ModeNotImplemented -ModeName "Plan"        -Reason "Requires remediation engine (Phase 7)." }
    "All"          { Invoke-ModeNotImplemented -ModeName "All"         -Reason "Composite mode not available until Phases 2-6 complete." }
}

if ($PassThru) { return $result }
