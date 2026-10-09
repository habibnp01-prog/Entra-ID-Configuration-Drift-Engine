function Invoke-DriftAssessment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$BaselinePath,
        [Parameter(Mandatory)] [string]$SnapshotPath
    )

    if (-not (Test-Path $BaselinePath)) { throw ("Baseline not found: {0}" -f $BaselinePath) }
    if (-not (Test-Path $SnapshotPath)) { throw ("Snapshot not found: {0}" -f $SnapshotPath) }

    $baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    $snapshot = Get-Content $SnapshotPath -Raw | ConvertFrom-Json

    if ($baseline.TenantId -ne $snapshot.TenantId) {
        Write-DriftLog -Message ("Tenant mismatch: baseline={0} snapshot={1}" -f $baseline.TenantId, $snapshot.TenantId) -Level Warning -Component "Assess"
    }

    Write-DriftLog -Message ("Comparing {0} baseline vs {1} current resources..." -f @($baseline.Resources).Count, @($snapshot.Resources).Count) -Level Info -Component "Assess"

    $comparison = Compare-DriftResources -BaselineResources @($baseline.Resources) -CurrentResources @($snapshot.Resources)
    $findings   = ConvertTo-DriftFindings -Comparison $comparison

    $assessment = [PSCustomObject]@{
        AssessedAtUtc    = (Get-Date).ToUniversalTime().ToString("o")
        BaselinePath     = $BaselinePath
        SnapshotPath     = $SnapshotPath
        BaselineVersion  = $baseline.BaselineVersion
        TenantId         = $snapshot.TenantId
        Summary          = $comparison.Summary
        Findings         = $findings
        FindingCount     = $findings.Count
        SeverityCounts   = [PSCustomObject]@{
            Critical = @($findings | Where-Object { $_.Severity -eq "Critical" }).Count
            High     = @($findings | Where-Object { $_.Severity -eq "High" }).Count
            Medium   = @($findings | Where-Object { $_.Severity -eq "Medium" }).Count
            Low      = @($findings | Where-Object { $_.Severity -eq "Low" }).Count
        }
    }

    Write-DriftLog -Message ("Assessment complete: {0} finding(s)" -f $assessment.FindingCount) -Level Success -Component "Assess"
    return $assessment
}
