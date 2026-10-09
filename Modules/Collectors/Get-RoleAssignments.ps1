function Get-DriftRoleAssignments {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching directory role assignments..." -Level Info -Component "Collect"

    $assignments = Get-MgRoleManagementDirectoryRoleAssignment -All -ErrorAction Stop
    $assignments = @($assignments)

    Write-DriftLog -Message ("Retrieved {0} role assignments." -f $assignments.Count) -Level Success -Component "Collect"
    return ,$assignments
}
