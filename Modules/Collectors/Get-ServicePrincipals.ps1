function Get-DriftServicePrincipals {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching service principals..." -Level Info -Component "Collect"

    $sps = Get-MgServicePrincipal -All -Property "Id,AppId,DisplayName,ServicePrincipalType,AccountEnabled,AppRoleAssignmentRequired,Tags" -ErrorAction Stop
    $sps = @($sps)

    Write-DriftLog -Message ("Retrieved {0} service principals." -f $sps.Count) -Level Success -Component "Collect"
    return ,$sps
}
