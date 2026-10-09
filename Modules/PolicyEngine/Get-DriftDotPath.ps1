function Get-DriftDotPath {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowNull()] $Object,
        [Parameter(Mandatory)] [string]$Path
    )

    $exists = $false
    $value = $null

    if ($null -eq $Object) {
        return [PSCustomObject]@{ Exists = $false; Value = $null }
    }

    $current = $Object
    $segments = $Path -split "\."
    foreach ($seg in $segments) {
        if ($null -eq $current) { return [PSCustomObject]@{ Exists = $false; Value = $null } }
        $prop = $current.PSObject.Properties | Where-Object { $_.Name -eq $seg } | Select-Object -First 1
        if (-not $prop) { return [PSCustomObject]@{ Exists = $false; Value = $null } }
        $current = $prop.Value
    }

    return [PSCustomObject]@{ Exists = $true; Value = $current }
}
