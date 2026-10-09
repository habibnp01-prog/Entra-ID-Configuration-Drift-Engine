function Get-DriftAppRoleAssignments {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$ServicePrincipalId
    )

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message ("Fetching app role assignments for SP {0}..." -f $ServicePrincipalId) -Level Info -Component "Collect"

    try {
        $assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $ServicePrincipalId -All -ErrorAction Stop
        $assignments = @($assignments)
    } catch {
        Write-DriftLog -Message ("Failed to fetch app roles for {0}: {1}" -f $ServicePrincipalId, $_) -Level Warning -Component "Collect"
        return ,@()
    }

    return ,$assignments
}
