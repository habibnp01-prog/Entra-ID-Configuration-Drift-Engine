function Export-DriftCSV {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings = @(),
        [Parameter(Mandatory)] [string]$OutputPath
    )

    $Findings = @($Findings)
    $dir = Split-Path $OutputPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if ($Findings.Count -eq 0) {
        "# No findings" | Set-Content -Path $OutputPath -Encoding UTF8
        Write-DriftLog -Message ("CSV written (empty): {0}" -f $OutputPath) -Level Info -Component "Report"
        return $OutputPath
    }

    $Findings |
        Select-Object FindingId, Category, Severity, ResourceType, ResourceId, ResourceName, ChangedProperty, ExpectedValue, ObservedValue, DetectedAtUtc, BusinessImpact, Recommendation |
        Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-DriftLog -Message ("CSV written: {0}" -f $OutputPath) -Level Success -Component "Report"
    return $OutputPath
}
