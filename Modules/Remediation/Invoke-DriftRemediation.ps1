function Invoke-DriftRemediation {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] $Plan,
        [switch]$Confirm
    )

    $results = @()

    foreach ($action in @($Plan.Actions)) {
        $result = [PSCustomObject]@{
            ActionId      = $action.ActionId
            FindingId     = $action.FindingId
            ResourceId    = $action.ResourceId
            ActionType    = $action.ActionType
            Performed     = $false
            Skipped       = $false
            Reason        = $null
            VerifiedAtUtc = $null
        }

        if (-not $action.CanAutoRemediate) {
            $result.Skipped = $true
            $result.Reason  = "Manual remediation required: $($action.AutoReason)"
            $results += $result
            continue
        }

        if (-not $Confirm) {
            $result.Skipped = $true
            $result.Reason  = "Not confirmed. Re-run with -Confirm to apply."
            $results += $result
            continue
        }

        if ($action.ResourceType -eq "ConditionalAccessPolicy" -and $action.Property -eq "State") {
            $target = $action.ResourceId
            $desiredState = $action.DesiredValue

            if ($PSCmdlet.ShouldProcess($target, ("Set State to {0}" -f $desiredState))) {
                try {
                    Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $target -State $desiredState -ErrorAction Stop
                    $result.Performed = $true
                    $result.Reason    = "Set CA policy State to $desiredState"

                    Start-Sleep -Seconds 2
                    $verify = Get-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $target -ErrorAction Stop
                    if ($verify.State -eq $desiredState) {
                        $result.VerifiedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
                    } else {
                        $result.Reason = "Remediation applied but verification shows State=$($verify.State), expected $desiredState"
                    }
                } catch {
                    $result.Reason = "Remediation failed: $_"
                }
            } else {
                $result.Skipped = $true
                $result.Reason  = "WhatIf: would have set State=$desiredState on $target"
            }
        } else {
            $result.Skipped = $true
            $result.Reason  = "No auto-remediation handler for this resource type."
        }

        $results += $result
    }

    [PSCustomObject]@{
        AppliedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
        Confirmed    = [bool]$Confirm
        Total        = $results.Count
        Performed    = @($results | Where-Object { $_.Performed }).Count
        Verified     = @($results | Where-Object { $_.VerifiedAtUtc }).Count
        Skipped      = @($results | Where-Object { $_.Skipped }).Count
        Results      = $results
    }
}
