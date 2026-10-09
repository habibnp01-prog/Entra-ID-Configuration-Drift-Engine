function New-DriftBaseline {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [string]$SnapshotPath,
        [Parameter(Mandatory)] [string]$BaselinePath,
        [switch]$Force
    )

    if (-not (Test-Path $SnapshotPath)) { throw ("Snapshot not found: {0}" -f $SnapshotPath) }
    if ((Test-Path $BaselinePath) -and -not $Force) {
        throw ("Baseline already exists: {0}. Use -Force to overwrite." -f $BaselinePath)
    }

    $snapshot = Get-Content $SnapshotPath -Raw | ConvertFrom-Json

    $baseline = [PSCustomObject]@{
        BaselineVersion = "1.0.0"
        CreatedFrom     = $SnapshotPath
        CreatedAtUtc    = (Get-Date).ToUniversalTime().ToString("o")
        TenantId        = $snapshot.TenantId
        ResourceCount   = $snapshot.ResourceCount
        Resources       = $snapshot.Resources
    }

    $dir = Split-Path $BaselinePath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $baseline | ConvertTo-Json -Depth 30 | Set-Content -Path $BaselinePath -Encoding UTF8
    Write-DriftLog -Message ("Baseline created: {0}" -f $BaselinePath) -Level Success -Component "Baseline"

    return $BaselinePath
}
