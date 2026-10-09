function Test-DriftBaseline {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$BaselinePath
    )

    $issues = @()

    if (-not (Test-Path $BaselinePath)) {
        $issues += ("Baseline file not found: {0}" -f $BaselinePath)
        return [PSCustomObject]@{ IsValid = $false; Issues = $issues; Baseline = $null }
    }

    try { $bl = Get-Content $BaselinePath -Raw | ConvertFrom-Json }
    catch {
        $issues += ("Baseline is not valid JSON: {0}" -f $_)
        return [PSCustomObject]@{ IsValid = $false; Issues = $issues; Baseline = $null }
    }

    if (-not $bl.BaselineVersion) { $issues += "Missing: BaselineVersion" }
    if (-not $bl.TenantId)        { $issues += "Missing: TenantId" }
    if ($null -eq $bl.Resources)  { $issues += "Missing: Resources" }

    [PSCustomObject]@{
        IsValid  = ($issues.Count -eq 0)
        Issues   = $issues
        Baseline = $bl
    }
}
