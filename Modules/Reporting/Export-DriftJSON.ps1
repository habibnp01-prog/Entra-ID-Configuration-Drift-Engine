function Export-DriftJSON {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] $Payload,
        [Parameter(Mandatory)] [string]$OutputPath
    )

    $dir = Split-Path $OutputPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $Payload | ConvertTo-Json -Depth 40 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-DriftLog -Message ("JSON written: {0}" -f $OutputPath) -Level Success -Component "Report"
    return $OutputPath
}
