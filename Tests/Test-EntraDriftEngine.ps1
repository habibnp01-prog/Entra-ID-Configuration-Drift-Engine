BeforeAll {
    $root = Split-Path $PSScriptRoot -Parent
}

Describe "Entry Point Smoke Test" {
    It "starts the drift engine entry point without syntax errors" {
        $entry = Join-Path $root "Start-EntraDriftEngine.ps1"
        Test-Path $entry | Should -BeTrue
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($entry, [ref]$null, [ref]$errors) | Out-Null
        $errors.Count | Should -Be 0
    }
    It "Module loader loads all modules" {
        $loader = Join-Path $root "Modules/Load-Modules.ps1"
        . $loader | Out-Null
        (Get-Command Write-DriftLog -ErrorAction SilentlyContinue)     | Should -Not -BeNullOrEmpty
        (Get-Command Test-EngineConfiguration -ErrorAction SilentlyContinue) | Should -Not -BeNullOrEmpty
    }
}
