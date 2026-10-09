function Get-DriftCAPolicies {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching Conditional Access policies..." -Level Info -Component "Collect"

    $policies = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop
    $policies = @($policies)

    Write-DriftLog -Message ("Retrieved {0} policies." -f $policies.Count) -Level Success -Component "Collect"

    return ,$policies
}
