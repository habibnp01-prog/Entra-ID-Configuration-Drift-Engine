function Get-DriftPropertyChanges {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [AllowNull()] $Baseline,
        [AllowNull()] $Current
    )

    $changes = @()

    # Collect all property names from both sides
    $baselineNames = @()
    if ($Baseline) {
        $baselineNames = @($Baseline.PSObject.Properties | ForEach-Object { $_.Name })
    }
    $currentNames = @()
    if ($Current) {
        $currentNames = @($Current.PSObject.Properties | ForEach-Object { $_.Name })
    }

    $allNames = @($baselineNames + $currentNames | Sort-Object -Unique)

    foreach ($name in $allNames) {
        $bVal = $null
        $cVal = $null
        $bHas = $false
        $cHas = $false

        if ($Baseline) {
            $bProp = $Baseline.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            if ($bProp) { $bVal = $bProp.Value; $bHas = $true }
        }
        if ($Current) {
            $cProp = $Current.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            if ($cProp) { $cVal = $cProp.Value; $cHas = $true }
        }

        $bJson = if ($bHas) { ConvertTo-DriftStableJson -Value $bVal } else { "<absent>" }
        $cJson = if ($cHas) { ConvertTo-DriftStableJson -Value $cVal } else { "<absent>" }

        if ($bJson -ne $cJson) {
            $changeType = if (-not $bHas) { "Added" } elseif (-not $cHas) { "Removed" } else { "Modified" }
            $changes += [PSCustomObject]@{
                Property      = $name
                ExpectedValue = $bVal
                ObservedValue = $cVal
                ChangeType    = $changeType
            }
        }
    }

    return ,$changes
}

function ConvertTo-DriftStableJson {
    [CmdletBinding()]
    param([AllowNull()] $Value)
    if ($null -eq $Value) { return "null" }
    try {
        return ($Value | ConvertTo-Json -Compress -Depth 20)
    } catch {
        return $Value.ToString()
    }
}
