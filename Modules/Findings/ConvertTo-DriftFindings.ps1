function ConvertTo-DriftFindings {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] $Comparison
    )

    $findings = @()

    # Added resources
    $i = 1
    foreach ($r in @($Comparison.Added)) {
        $findings += New-DriftFinding `
            -FindingId       ("DRIFT-ADDED-{0:000}" -f $i) `
            -Category        "Added" `
            -Severity        "High" `
            -ResourceType    $r.ResourceType `
            -ResourceId      $r.ResourceId `
            -ResourceName    $r.DisplayName `
            -ChangedProperty "Resource" `
            -ExpectedValue   $null `
            -ObservedValue   $r `
            -BusinessImpact  "A new resource appeared that is not in the approved baseline. Verify it was authorized." `
            -Recommendation  "Confirm the change was approved. If intentional, update the baseline. If not, investigate."
        $i++
    }

    # Removed resources
    $i = 1
    foreach ($r in @($Comparison.Removed)) {
        $findings += New-DriftFinding `
            -FindingId       ("DRIFT-REMOVED-{0:000}" -f $i) `
            -Category        "Removed" `
            -Severity        "Critical" `
            -ResourceType    $r.ResourceType `
            -ResourceId      $r.ResourceId `
            -ResourceName    $r.DisplayName `
            -ChangedProperty "Resource" `
            -ExpectedValue   $r `
            -ObservedValue   $null `
            -BusinessImpact  "A resource in the approved baseline is missing. This may indicate an unintended or unauthorized deletion." `
            -Recommendation  "Investigate why the resource was removed. Restore it or update the baseline if the removal was approved."
        $i++
    }

    # Modified resources — one finding per changed property
    foreach ($m in @($Comparison.Modified)) {
        $i = 1
        foreach ($c in @($m.Changes)) {
            $sev = switch ($c.ChangeType) {
                "Removed"  { "High" }
                "Added"    { "Medium" }
                "Modified" { "Medium" }
                default    { "Low" }
            }
            $findings += New-DriftFinding `
                -FindingId       ("DRIFT-MODIFIED-{0}-{1:000}" -f $m.ResourceId.Substring(0, [Math]::Min(8, $m.ResourceId.Length)), $i) `
                -Category        "Modified" `
                -Severity        $sev `
                -ResourceType    $m.ResourceType `
                -ResourceId      $m.ResourceId `
                -ResourceName    $m.DisplayName `
                -ChangedProperty $c.Property `
                -ExpectedValue   $c.ExpectedValue `
                -ObservedValue   $c.ObservedValue `
                -BusinessImpact  ("Property {0} changed from baseline. Verify the change was authorized." -f $c.Property) `
                -Recommendation  "Review the change. If approved, update the baseline. If not, investigate and revert."
            $i++
        }
    }

    return ,@($findings)
}
