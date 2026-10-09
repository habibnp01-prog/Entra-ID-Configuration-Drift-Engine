function New-DriftRemediationPlan {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings = @()
    )

    $Findings = @($Findings)
    $actions = @()
    $i = 1

    foreach ($f in $Findings) {
        $actionType = switch ($f.Category) {
            "Added"    { "Review" }
            "Removed"  { "Restore" }
            "Modified" { "Revert" }
            "Policy"   { "Review" }
            default    { "Review" }
        }

        $canAutoRemediate = $false
        $autoReason = "No automated remediation for this resource type."

        if ($f.ResourceType -eq "ConditionalAccessPolicy") {
            $prop = if ($f.ChangedProperty) { $f.ChangedProperty } elseif ($f.Property) { $f.Property } else { $null }
            if ($prop -eq "State") {
                $canAutoRemediate = $true
                $autoReason = "Conditional Access policy State can be safely flipped."
            }
        }

        $actions += [PSCustomObject]@{
            ActionId         = ("ACT-{0:000}" -f $i)
            FindingId        = $f.FindingId
            Severity         = $f.Severity
            ResourceType     = $f.ResourceType
            ResourceId       = $f.ResourceId
            ResourceName     = $f.ResourceName
            ActionType       = $actionType
            Property         = if ($f.ChangedProperty) { $f.ChangedProperty } elseif ($f.Property) { $f.Property } else { $null }
            CurrentValue     = $f.ObservedValue
            DesiredValue     = $f.ExpectedValue
            CanAutoRemediate = $canAutoRemediate
            AutoReason       = $autoReason
            Recommendation   = $f.Recommendation
            BusinessImpact   = $f.BusinessImpact
        }
        $i++
    }

    [PSCustomObject]@{
        PlanVersion    = "1.0.0"
        GeneratedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        ActionCount    = $actions.Count
        AutoCount      = @($actions | Where-Object { $_.CanAutoRemediate }).Count
        ManualCount    = @($actions | Where-Object { -not $_.CanAutoRemediate }).Count
        Actions        = $actions
    }
}
