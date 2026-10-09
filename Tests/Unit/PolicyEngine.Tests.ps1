BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-Res {
        param([string]$Id, [hashtable]$Props = @{})
        [PSCustomObject]@{
            ResourceType = "ConditionalAccessPolicy"
            ResourceId   = $Id
            DisplayName  = "Res-$Id"
            Properties   = [PSCustomObject]$Props
        }
    }
    function New-Pol {
        param([string]$Id, [string]$Rule, $Value = $null, [string]$Severity = "High", [string]$Property = "State")
        [PSCustomObject]@{
            id = $Id; name = "Test $Id"; resourceType = "ConditionalAccessPolicy"
            property = $Property; rule = $Rule; value = $Value; severity = $Severity
            description = "test"; remediation = "fix it"; references = @()
        }
    }
}

Describe "Import-DriftPolicy" {
    It "loads the shipped ConditionalAccess policy file" {
        $p = Import-DriftPolicy -PolicyPath (Join-Path $root "Policies/ConditionalAccess.json")
        $p.Count | Should -BeGreaterThan 0
        ($p | Where-Object { $_.id -eq "POL-CA-001" }) | Should -Not -BeNullOrEmpty
    }
    It "throws on missing file" {
        { Import-DriftPolicy -PolicyPath "nonexistent.json" } | Should -Throw "*not found*"
    }
}

Describe "Get-DriftDotPath" {
    It "resolves simple property" {
        $o = [PSCustomObject]@{ State = "enabled" }
        $r = Get-DriftDotPath -Object $o -Path "State"
        $r.Exists | Should -BeTrue
        $r.Value | Should -Be "enabled"
    }
    It "returns not-exists for missing property" {
        $o = [PSCustomObject]@{ State = "enabled" }
        $r = Get-DriftDotPath -Object $o -Path "Missing"
        $r.Exists | Should -BeFalse
    }
    It "handles null object" {
        $r = Get-DriftDotPath -Object $null -Path "Anything"
        $r.Exists | Should -BeFalse
    }
}

Describe "Test-DriftPolicyRule" {
    It "MustExist passes when property exists" {
        $p = New-Pol -Id "t1" -Rule "MustExist" -Property "State"
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r1" -Props @{ State = "enabled" })
        $r.Passes | Should -BeTrue
    }
    It "MustExist fails when property missing" {
        $p = New-Pol -Id "t2" -Rule "MustExist" -Property "Missing"
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r2" -Props @{ State = "enabled" })
        $r.Passes | Should -BeFalse
    }
    It "MustBe passes on match" {
        $p = New-Pol -Id "t3" -Rule "MustBe" -Value "enabled"
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r3" -Props @{ State = "enabled" })
        $r.Passes | Should -BeTrue
    }
    It "MustBe fails on mismatch" {
        $p = New-Pol -Id "t4" -Rule "MustBe" -Value "enabled"
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r4" -Props @{ State = "disabled" })
        $r.Passes | Should -BeFalse
    }
    It "MustNotBe passes when value differs" {
        $p = New-Pol -Id "t5" -Rule "MustNotBe" -Value "disabled"
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r5" -Props @{ State = "enabled" })
        $r.Passes | Should -BeTrue
    }
    It "MustBeOneOf passes when value is in list" {
        $p = New-Pol -Id "t6" -Rule "MustBeOneOf" -Value @("enabled","reportOnly")
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r6" -Props @{ State = "enabled" })
        $r.Passes | Should -BeTrue
    }
    It "MustNotBeOneOf fails when value is prohibited" {
        $p = New-Pol -Id "t7" -Rule "MustNotBeOneOf" -Value @("disabled","other")
        $r = Test-DriftPolicyRule -Policy $p -Resource (New-Res -Id "r7" -Props @{ State = "disabled" })
        $r.Passes | Should -BeFalse
    }
}

Describe "Invoke-DriftPolicyCheck" {
    It "produces findings for failing policies" {
        $resources = @(New-Res -Id "r1" -Props @{ State = "disabled" })
        $policies  = @(New-Pol -Id "POL-TEST-1" -Rule "MustBe" -Value "enabled")
        $r = Invoke-DriftPolicyCheck -Resources $resources -Policies $policies
        $r.FindingCount | Should -Be 1
        $r.Findings[0].PolicyId | Should -Be "POL-TEST-1"
    }
    It "suppresses findings matched by exceptions" {
        $resources = @(New-Res -Id "r1" -Props @{ State = "disabled" })
        $policies  = @(New-Pol -Id "POL-TEST-2" -Rule "MustBe" -Value "enabled")
        $exceptions = @([PSCustomObject]@{ policyId = "POL-TEST-2"; resourceId = $null; expiresOn = "2099-12-31"; owner = "sec"; reason = "approved" })
        $r = Invoke-DriftPolicyCheck -Resources $resources -Policies $policies -Exceptions $exceptions
        $r.FindingCount | Should -Be 0
        $r.SuppressedCount | Should -Be 1
    }
    It "does NOT suppress when exception is expired" {
        $resources = @(New-Res -Id "r1" -Props @{ State = "disabled" })
        $policies  = @(New-Pol -Id "POL-TEST-3" -Rule "MustBe" -Value "enabled")
        $exceptions = @([PSCustomObject]@{ policyId = "POL-TEST-3"; resourceId = $null; expiresOn = "2000-01-01"; owner = "sec"; reason = "expired" })
        $r = Invoke-DriftPolicyCheck -Resources $resources -Policies $policies -Exceptions $exceptions
        $r.FindingCount | Should -Be 1
    }
}
