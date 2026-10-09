BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "ConvertFrom-DriftRawResource" {
    It "normalizes a basic resource" {
        $raw = [PSCustomObject]@{ Id = "r1"; DisplayName = "Resource One"; State = "enabled" }
        $n = ConvertFrom-DriftRawResource -RawResources @($raw) -ResourceType "TestType"
        $n.Count | Should -Be 1
        $n[0].ResourceId   | Should -Be "r1"
        $n[0].DisplayName  | Should -Be "Resource One"
        $n[0].ResourceType | Should -Be "TestType"
        $n[0].Properties.State | Should -Be "enabled"
    }
    It "skips volatile properties" {
        $raw = [PSCustomObject]@{ Id = "r1"; DisplayName = "X"; State = "enabled"; CreatedDateTime = "2024"; ModifiedDateTime = "2025" }
        $n = ConvertFrom-DriftRawResource -RawResources @($raw) -ResourceType "TestType"
        $n[0].Properties.PSObject.Properties.Name | Should -Not -Contain "CreatedDateTime"
        $n[0].Properties.PSObject.Properties.Name | Should -Not -Contain "ModifiedDateTime"
    }
    It "handles empty input" {
        $n = ConvertFrom-DriftRawResource -RawResources @() -ResourceType "TestType"
        $n.Count | Should -Be 0
    }
    It "handles custom id and name properties" {
        $raw = [PSCustomObject]@{ AppId = "app-1"; PublisherDomain = "contoso.com"; SignInAudience = "AzureADMyOrg" }
        $n = ConvertFrom-DriftRawResource -RawResources @($raw) -ResourceType "Application" -IdProperty "AppId" -NameProperty "PublisherDomain"
        $n[0].ResourceId  | Should -Be "app-1"
        $n[0].DisplayName | Should -Be "contoso.com"
    }
    It "throws when Get-DriftCAPolicies called without connection" {
        { Get-DriftCAPolicies } | Should -Throw "*Not connected*"
    }
    It "throws when Get-DriftDirectoryRoles called without connection" {
        { Get-DriftDirectoryRoles } | Should -Throw "*Not connected*"
    }
    It "throws when Get-DriftApplications called without connection" {
        { Get-DriftApplications } | Should -Throw "*Not connected*"
    }
    It "throws when Get-DriftServicePrincipals called without connection" {
        { Get-DriftServicePrincipals } | Should -Throw "*Not connected*"
    }
    It "throws when Get-DriftOAuth2Grants called without connection" {
        { Get-DriftOAuth2Grants } | Should -Throw "*Not connected*"
    }
    It "throws when Get-DriftRoleAssignments called without connection" {
        { Get-DriftRoleAssignments } | Should -Throw "*Not connected*"
    }
}
