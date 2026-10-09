BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-Finding {
        param(
            [string]$Id = "F-1",
            [string]$Cat = "Modified",
            [string]$RT = "ConditionalAccessPolicy",
            [string]$RID = "pol-1",
            [string]$Prop = "State",
            $Expected = "enabled",
            $Observed = "disabled"
        )
        [PSCustomObject]@{
            FindingId = $Id; Category = $Cat; Severity = "High"
            ResourceType = $RT; ResourceId = $RID; ResourceName = "Test"
            ChangedProperty = $Prop; Property = $Prop
            ExpectedValue = $Expected; ObservedValue = $Observed
            Recommendation = "fix"; BusinessImpact = "test"
        }
    }
}

Describe "New-DriftRemediationPlan" {
    It "creates one action per finding" {
        $plan = New-DriftRemediationPlan -Findings @(New-Finding; New-Finding -Id "F-2")
        $plan.ActionCount | Should -Be 2
    }
    It "marks CA State changes as auto-remediable" {
        $plan = New-DriftRemediationPlan -Findings @(New-Finding)
        $plan.Actions[0].CanAutoRemediate | Should -BeTrue
        $plan.AutoCount | Should -Be 1
    }
    It "marks non-CA resources as manual" {
        $plan = New-DriftRemediationPlan -Findings @(New-Finding -RT "Application" -Prop "SignInAudience")
        $plan.Actions[0].CanAutoRemediate | Should -BeFalse
        $plan.ManualCount | Should -Be 1
    }
    It "handles empty findings" {
        $plan = New-DriftRemediationPlan -Findings @()
        $plan.ActionCount | Should -Be 0
    }
}

Describe "Invoke-DriftRemediation safety" {
    It "skips when -Apply is not passed" {
        $plan = New-DriftRemediationPlan -Findings @(New-Finding)
        $result = Invoke-DriftRemediation -Plan $plan
        $result.Performed | Should -Be 0
        $result.Skipped   | Should -BeGreaterThan 0
    }
    It "reports WhatIf without performing when -WhatIf is passed" {
        $plan = New-DriftRemediationPlan -Findings @(New-Finding)
        $result = Invoke-DriftRemediation -Plan $plan -Apply -WhatIf
        $result.Performed | Should -Be 0
        ($result.Results | Where-Object { $_.Reason -match "WhatIf" }) | Should -Not -BeNullOrEmpty
    }
}
