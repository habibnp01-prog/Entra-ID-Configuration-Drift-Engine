function Get-DriftRoleAssignments {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param()

    if (-not (Test-DriftGraphConnection)) {
        throw "Not connected to Microsoft Graph. Call Connect-DriftGraph first."
    }

    Write-DriftLog -Message "Fetching directory role assignments..." -Level Info -Component "Collect"

    $assignments = Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty "Principal" -ErrorAction Stop
    $assignments = @($assignments)

    # Enrich each assignment with AssignmentType
    $enriched = foreach ($a in $assignments) {
        [PSCustomObject]@{
            Id               = $a.Id
            PrincipalId      = $a.PrincipalId
            RoleDefinitionId = $a.RoleDefinitionId
            DirectoryScopeId = $a.DirectoryScopeId
            AssignmentType   = "Active"  # Directory assignments are always active by default
            AssignmentSource = $a.AssignmentSource
        }
    }

    Write-DriftLog -Message ("Retrieved {0} role assignments." -f $enriched.Count) -Level Success -Component "Collect"
    return ,@($enriched)
}
