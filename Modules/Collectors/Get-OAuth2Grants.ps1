function Get-DriftOAuth2Grants {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching OAuth2 permission grants..." -Level Info -Component "Collect"

    $grants = Get-MgOauth2PermissionGrant -All -ErrorAction Stop
    $grants = @($grants)

    Write-DriftLog -Message ("Retrieved {0} OAuth2 permission grants." -f $grants.Count) -Level Success -Component "Collect"
    return ,$grants
}
