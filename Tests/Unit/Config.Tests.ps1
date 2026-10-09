BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "EngineConfig.json" {
    It "is valid JSON" {
        $p = Join-Path $root "Config/EngineConfig.json"
        { Get-Content $p -Raw | ConvertFrom-Json } | Should -Not -Throw
    }
    It "has required top-level properties" {
        $cfg = Get-Content (Join-Path $root "Config/EngineConfig.json") -Raw | ConvertFrom-Json
        $cfg.version         | Should -Not -BeNullOrEmpty
        $cfg.engine          | Should -Not -BeNullOrEmpty
        $cfg.tenant          | Should -Not -BeNullOrEmpty
        $cfg.graph           | Should -Not -BeNullOrEmpty
        $cfg.paths           | Should -Not -BeNullOrEmpty
        $cfg.requiredModules | Should -Not -BeNullOrEmpty
    }
}

Describe "RiskThresholds.json" {
    It "defines all five severity levels" {
        $r = Get-Content (Join-Path $root "Config/RiskThresholds.json") -Raw | ConvertFrom-Json
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "Critical"
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "High"
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "Medium"
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "Low"
        $r.severityLevels.PSObject.Properties.Name | Should -Contain "Info"
    }
    It "defines three drift categories" {
        $r = Get-Content (Join-Path $root "Config/RiskThresholds.json") -Raw | ConvertFrom-Json
        $r.driftCategories.PSObject.Properties.Name | Should -Contain "Added"
        $r.driftCategories.PSObject.Properties.Name | Should -Contain "Modified"
        $r.driftCategories.PSObject.Properties.Name | Should -Contain "Removed"
    }
}

Describe "Test-EngineConfiguration" {
    It "returns IsValid = true for the shipped config" {
        $r = Test-EngineConfiguration
        $r.IsValid | Should -BeTrue
    }
    It "returns IsValid = false for a missing file" {
        $r = Test-EngineConfiguration -ConfigPath (Join-Path $root "Config/does-not-exist.json")
        $r.IsValid | Should -BeFalse
        $r.Issues.Count | Should -BeGreaterThan 0
    }
}

Describe "Test-DriftRequiredModules" {
    It "reports Missing for a fake module" {
        $r = Test-DriftRequiredModules -RequiredModules @(@{ name = "ThisModuleDoesNotExist999"; minimumVersion = "1.0.0" })
        $r[0].Status | Should -Be "Missing"
    }
    It "reports OK for Pester" {
        $r = Test-DriftRequiredModules -RequiredModules @(@{ name = "Pester"; minimumVersion = "5.0.0" })
        $r[0].Status | Should -BeIn @("OK","Outdated")
    }
}

Describe "Test-DriftProjectStructure" {
    It "confirms required files exist" {
        $r = Test-DriftProjectStructure -RootPath $root
        $r.IsValid | Should -BeTrue
        $r.Missing.Count | Should -Be 0
    }
}
