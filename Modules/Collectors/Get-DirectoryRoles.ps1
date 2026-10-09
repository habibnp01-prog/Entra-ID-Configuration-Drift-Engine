function Get-DriftDirectoryRoles {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching directory roles..." -Level Info -Component "Collect"

    $roles = Get-MgDirectoryRole -All -ErrorAction Stop
    $roles = @($roles)

    Write-DriftLog -Message ("Retrieved {0} directory roles." -f $roles.Count) -Level Success -Component "Collect"
    return ,$roles
}
