#Requires -Version 7.0
[CmdletBinding()]
param(
    [ValidateSet("Collect","Baseline","Assess","PolicyCheck","History","Report","Plan","Validate","Test","All")]
    [string]$Mode = "Validate",

    [string]$TenantId,
    [string]$ConfigPath   = (Join-Path $PSScriptRoot "Config/EngineConfig.json"),
    [string]$BaselinePath,
    [string]$SnapshotPath,
    [string]$PolicyPath,
    [string]$OutputPath   = (Join-Path $PSScriptRoot "Reports"),
    [datetime]$Since,
    [switch]$WhatIf,
    [switch]$PassThru,
    [switch]$Quiet,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot

function Show-EngineBanner {
    if ($Quiet) { return }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Entra-ID Configuration Drift Engine" -ForegroundColor Cyan
    Write-Host ("  v0.6.0  |  Mode: {0}" -f $Mode) -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-Config { Get-Content $ConfigPath -Raw | ConvertFrom-Json }

function Get-LatestSnapshot {
    $snapDir = Join-Path $root "Reports/JSON"
    $latest = Get-ChildItem -Path $snapDir -Filter "snapshot-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $latest
}

function Get-LatestBaseline {
    $blDir = Join-Path $root "Baselines"
    $latest = Get-ChildItem -Path $blDir -Filter "baseline-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    return $latest
}

function Invoke-ModeValidate {
    Write-DriftLog -Message "[1/2] Validating engine configuration..." -Level Info -Component "Validate"
    $configTest = Test-EngineConfiguration -ConfigPath $ConfigPath
    if (-not $configTest.IsValid) {
        foreach ($i in $configTest.Issues) { Write-DriftLog -Message ("  - {0}" -f $i) -Level Warning -Component "Validate" }
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
    $result = Invoke-Pester -Path (Join-Path $root "Tests") -Output Detailed -PassThru
    Write-DriftLog -Message ("Tests: {0} passed, {1} failed" -f $result.PassedCount, $result.FailedCount) -Level Info -Component "Test"
    if ($result.FailedCount -gt 0) { throw ("{0} test(s) failed." -f $result.FailedCount) }
    return [PSCustomObject]@{ Mode = "Test"; Passed = $result.PassedCount; Failed = $result.FailedCount }
}

function Invoke-ModeCollect {
    $cfg = Get-Config
    Write-DriftLog -Message "[1/5] Loading configuration..." -Level Info -Component "Collect"

    $tenant = if ($TenantId) { $TenantId } else { $cfg.tenant.tenantId }
    if (-not $tenant -or $tenant -like "REPLACE*") { throw "Set tenant.tenantId in Config/EngineConfig.json or pass -TenantId" }
    if (-not $cfg.tenant.clientId -or $cfg.tenant.clientId -like "REPLACE*") { throw "Set tenant.clientId in Config/EngineConfig.json" }
    if (-not $cfg.tenant.certificateThumbprint -or $cfg.tenant.certificateThumbprint -like "REPLACE*") { throw "Set tenant.certificateThumbprint in Config/EngineConfig.json" }

    Write-DriftLog -Message "[2/5] Authenticating..." -Level Info -Component "Collect"
    Connect-DriftGraph -TenantId $tenant -ClientId $cfg.tenant.clientId -CertificateThumbprint $cfg.tenant.certificateThumbprint | Out-Null

    $resources = @()
    $summary = [ordered]@{}

    try {
        Write-DriftLog -Message "[3/5] Collecting resources..." -Level Info -Component "Collect"

        # Conditional Access policies
        try {
            $ca = ConvertFrom-DriftRawResource -RawResources (Get-DriftCAPolicies) -ResourceType "ConditionalAccessPolicy"
            $resources += $ca
            $summary["ConditionalAccessPolicy"] = $ca.Count
            Write-DriftLog -Message ("  ConditionalAccessPolicy: {0}" -f $ca.Count) -Level Success -Component "Collect"
        } catch { Write-DriftLog -Message ("  CA policies failed: {0}" -f $_) -Level Warning -Component "Collect"; $summary["ConditionalAccessPolicy"] = "FAILED" }

        # Directory roles
        try {
            $roles = ConvertFrom-DriftRawResource -RawResources (Get-DriftDirectoryRoles) -ResourceType "DirectoryRole"
            $resources += $roles
            $summary["DirectoryRole"] = $roles.Count
            Write-DriftLog -Message ("  DirectoryRole: {0}" -f $roles.Count) -Level Success -Component "Collect"
        } catch { Write-DriftLog -Message ("  Directory roles failed: {0}" -f $_) -Level Warning -Component "Collect"; $summary["DirectoryRole"] = "FAILED" }

        # Role assignments
        try {
            $ra = ConvertFrom-DriftRawResource -RawResources (Get-DriftRoleAssignments) -ResourceType "RoleAssignment" -NameProperty "RoleDefinitionId"
            $resources += $ra
            $summary["RoleAssignment"] = $ra.Count
            Write-DriftLog -Message ("  RoleAssignment: {0}" -f $ra.Count) -Level Success -Component "Collect"
        } catch { Write-DriftLog -Message ("  Role assignments failed: {0}" -f $_) -Level Warning -Component "Collect"; $summary["RoleAssignment"] = "FAILED" }

        # Applications
        try {
            $apps = ConvertFrom-DriftRawResource -RawResources (Get-DriftApplications) -ResourceType "Application" -IdProperty "Id"
            $resources += $apps
            $summary["Application"] = $apps.Count
            Write-DriftLog -Message ("  Application: {0}" -f $apps.Count) -Level Success -Component "Collect"
        } catch { Write-DriftLog -Message ("  Applications failed: {0}" -f $_) -Level Warning -Component "Collect"; $summary["Application"] = "FAILED" }

        # Service principals
        try {
            $sps = ConvertFrom-DriftRawResource -RawResources (Get-DriftServicePrincipals) -ResourceType "ServicePrincipal"
            $resources += $sps
            $summary["ServicePrincipal"] = $sps.Count
            Write-DriftLog -Message ("  ServicePrincipal: {0}" -f $sps.Count) -Level Success -Component "Collect"
        } catch { Write-DriftLog -Message ("  Service principals failed: {0}" -f $_) -Level Warning -Component "Collect"; $summary["ServicePrincipal"] = "FAILED" }

        # OAuth2 grants
        try {
            $grants = ConvertFrom-DriftRawResource -RawResources (Get-DriftOAuth2Grants) -ResourceType "OAuth2PermissionGrant" -NameProperty "ClientId"
            $resources += $grants
            $summary["OAuth2PermissionGrant"] = $grants.Count
            Write-DriftLog -Message ("  OAuth2PermissionGrant: {0}" -f $grants.Count) -Level Success -Component "Collect"
        } catch { Write-DriftLog -Message ("  OAuth2 grants failed: {0}" -f $_) -Level Warning -Component "Collect"; $summary["OAuth2PermissionGrant"] = "FAILED" }

    } finally {
        Disconnect-DriftGraph | Out-Null
    }

    Write-DriftLog -Message "[4/5] Writing snapshot..." -Level Info -Component "Collect"
    $snapshot = New-DriftSnapshot -Resources $resources -TenantId $tenant

    # Attach collection summary to snapshot
    $snapshot | Add-Member -NotePropertyName "CollectionSummary" -NotePropertyValue ([PSCustomObject]$summary) -Force

    $snapDir = Join-Path $root "Reports/JSON"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $snapPath = Join-Path $snapDir ("snapshot-{0}.json" -f $timestamp)
    Export-DriftSnapshot -Snapshot $snapshot -OutputPath $snapPath | Out-Null

    Write-DriftLog -Message "[5/5] Snapshot complete: $($resources.Count) resources." -Level Success -Component "Collect"
    return [PSCustomObject]@{ Mode = "Collect"; SnapshotPath = $snapPath; Resources = $resources.Count; Summary = $summary }
}
function Invoke-ModeBaseline {
    if (-not $BaselinePath) {
        $latest = Get-LatestSnapshot
        if (-not $latest) { throw "No snapshot found. Run -Mode Collect first." }
        $BaselinePath = $latest.FullName
        Write-DriftLog -Message ("Using latest snapshot: {0}" -f $BaselinePath) -Level Info -Component "Baseline"
    }
    $baselineDir = Join-Path $root "Baselines"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $baselineOut = Join-Path $baselineDir ("baseline-{0}.json" -f $timestamp)
    $path = New-DriftBaseline -SnapshotPath $BaselinePath -BaselinePath $baselineOut -Force:$Force
    return [PSCustomObject]@{ Mode = "Baseline"; BaselinePath = $path }
}

function Invoke-ModeAssess {
    $blPath = $BaselinePath
    if (-not $blPath) {
        $latest = Get-LatestBaseline
        if (-not $latest) { throw "No baseline found. Run -Mode Baseline first." }
        $blPath = $latest.FullName
        Write-DriftLog -Message ("Using latest baseline: {0}" -f $blPath) -Level Info -Component "Assess"
    }

    $snapPath = $SnapshotPath
    if (-not $snapPath) {
        $latest = Get-LatestSnapshot
        if (-not $latest) { throw "No snapshot found. Run -Mode Collect first." }
        $snapPath = $latest.FullName
        Write-DriftLog -Message ("Using latest snapshot: {0}" -f $snapPath) -Level Info -Component "Assess"
    }

    $assessment = Invoke-DriftAssessment -BaselinePath $blPath -SnapshotPath $snapPath

    $outDir = Join-Path $root "Reports/JSON"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outFile = Join-Path $outDir ("assessment-{0}.json" -f $timestamp)
    $assessment | ConvertTo-Json -Depth 30 | Set-Content -Path $outFile -Encoding UTF8
    Write-DriftLog -Message ("Assessment written: {0}" -f $outFile) -Level Success -Component "Assess"

    return [PSCustomObject]@{ Mode = "Assess"; AssessmentPath = $outFile; FindingCount = $assessment.FindingCount }
}

function Invoke-ModePolicyCheck {
    $snapPath = $SnapshotPath
    if (-not $snapPath) {
        $latest = Get-LatestSnapshot
        if (-not $latest) { throw "No snapshot found. Run -Mode Collect first." }
        $snapPath = $latest.FullName
        Write-DriftLog -Message ("Using latest snapshot: {0}" -f $snapPath) -Level Info -Component "PolicyCheck"
    }

    $polPath = $PolicyPath
    if (-not $polPath) { $polPath = Join-Path $root "Policies" }

    Write-DriftLog -Message ("Loading policies from: {0}" -f $polPath) -Level Info -Component "PolicyCheck"
    $policies = Import-DriftAllPolicies -PolicyRoot $polPath
    Write-DriftLog -Message ("Loaded {0} policy rule(s)." -f $policies.Count) -Level Success -Component "PolicyCheck"

    $snapshot = Get-Content $snapPath -Raw | ConvertFrom-Json
    $resources = @($snapshot.Resources)

    # Load exceptions if file exists
    $exceptions = @()
    $excPath = Join-Path $root "Config/Exceptions.json"
    if (Test-Path $excPath) {
        $exc = Get-Content $excPath -Raw | ConvertFrom-Json
        if ($exc.exceptions) { $exceptions = @($exc.exceptions) }
    }

    Write-DriftLog -Message ("Evaluating {0} policies against {1} resources..." -f $policies.Count, $resources.Count) -Level Info -Component "PolicyCheck"
    $result = Invoke-DriftPolicyCheck -Resources $resources -Policies $policies -Exceptions $exceptions

    $outDir = Join-Path $root "Reports/JSON"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outFile = Join-Path $outDir ("policycheck-{0}.json" -f $timestamp)
    $result | ConvertTo-Json -Depth 30 | Set-Content -Path $outFile -Encoding UTF8
    Write-DriftLog -Message ("Policy check written: {0}" -f $outFile) -Level Success -Component "PolicyCheck"

    return [PSCustomObject]@{ Mode = "PolicyCheck"; ReportPath = $outFile; FindingCount = $result.FindingCount }
}
function Invoke-ModeReport {
    # Find latest assessment or policycheck
    $jsonDir = Join-Path $root "Reports/JSON"
    $latestAssessment = Get-ChildItem -Path $jsonDir -Filter "assessment-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $latestPolicy    = Get-ChildItem -Path $jsonDir -Filter "policycheck-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $findings = @()
    $tenantId = "unknown"
    $baselineVersion = "unknown"

    if ($latestAssessment) {
        $a = Get-Content $latestAssessment.FullName -Raw | ConvertFrom-Json
        $findings += @($a.Findings)
        $tenantId = $a.TenantId
        $baselineVersion = $a.BaselineVersion
    }
    if ($latestPolicy) {
        $p = Get-Content $latestPolicy.FullName -Raw | ConvertFrom-Json
        $findings += @($p.Findings)
    }

    if ($findings.Count -eq 0) {
        Write-DriftLog -Message "No findings to report. Run -Mode Assess or -Mode PolicyCheck first." -Level Warning -Component "Report"
    }

    $csvPath  = Join-Path $root ("Reports/CSV/drift-findings-{0}.csv"  -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $jsonPath = Join-Path $root ("Reports/JSON/report-{0}.json"        -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $htmlPath = Join-Path $root ("Reports/HTML/executive-report-{0}.html" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
    $histPath = Join-Path $root "Reports/JSON/history.json"

    Export-DriftCSV  -Findings $findings -OutputPath $csvPath  | Out-Null
    Export-DriftJSON -Payload ([PSCustomObject]@{ GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString("o"); TenantId = $tenantId; FindingCount = $findings.Count; Findings = $findings }) -OutputPath $jsonPath | Out-Null
    Export-DriftHTML -Findings $findings -TenantId $tenantId -OutputPath $htmlPath -BaselineVersion $baselineVersion | Out-Null
    $history = Add-DriftHistory -Findings $findings -HistoryPath $histPath

    return [PSCustomObject]@{
        Mode         = "Report"
        FindingCount = $findings.Count
        CSV          = $csvPath
        JSON         = $jsonPath
        HTML         = $htmlPath
        HistoryPath  = $histPath
    }
}
function Invoke-ModeNotImplemented {
    param([string]$ModeName, [string]$Reason)
    Write-DriftLog -Message ("Mode {0} is not implemented yet." -f $ModeName) -Level Warning -Component $ModeName
    Write-DriftLog -Message ("Reason: {0}" -f $Reason) -Level Info -Component $ModeName
    return [PSCustomObject]@{ Mode = $ModeName; Status = "NotImplemented"; Reason = $Reason }
}

Show-EngineBanner
. (Join-Path $root "Modules/Load-Modules.ps1")

$result = switch ($Mode) {
    "Validate"     { Invoke-ModeValidate }
    "Test"         { Invoke-ModeTest }
    "Collect"      { Invoke-ModeCollect }
    "Baseline"     { Invoke-ModeBaseline }
    "Assess"       { Invoke-ModeAssess }
    "PolicyCheck"  { Invoke-ModePolicyCheck }
    "History"      { Invoke-ModeNotImplemented -ModeName "History"     -Reason "History storage arrives in Phase 6." }
    "Report"       { Invoke-ModeReport }
    "Plan"         { Invoke-ModeNotImplemented -ModeName "Plan"        -Reason "Remediation arrives in Phase 7." }
    "All"          { Invoke-ModeNotImplemented -ModeName "All"         -Reason "Composite mode available after Phase 6." }
}

if ($PassThru) { return $result }
