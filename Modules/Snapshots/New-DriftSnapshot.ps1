function New-DriftSnapshot {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Resources = @(),
        [Parameter(Mandatory)] [string]$TenantId,
        [string]$EngineVersion = "0.2.0"
    )

    $Resources = @($Resources)

    $snapshot = [PSCustomObject]@{
        Version         = $EngineVersion
        TenantId        = $TenantId
        CollectedAtUtc  = (Get-Date).ToUniversalTime().ToString("o")
        ResourceCount   = $Resources.Count
        Resources       = $Resources
    }

    return $snapshot
}

function Export-DriftSnapshot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] $Snapshot,
        [Parameter(Mandatory)] [string]$OutputPath
    )

    $dir = Split-Path $OutputPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $Snapshot | ConvertTo-Json -Depth 30 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-DriftLog -Message ("Snapshot written: {0}" -f $OutputPath) -Level Success -Component "Snapshot"

    return $OutputPath
}
