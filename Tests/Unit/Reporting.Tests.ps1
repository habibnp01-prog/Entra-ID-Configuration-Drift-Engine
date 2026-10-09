BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-Finding {
        param([string]$Id = "F-1", [string]$Sev = "High", [string]$Cat = "Modified")
        [PSCustomObject]@{
            FindingId = $Id; Category = $Cat; Severity = $Sev
            ResourceType = "ConditionalAccessPolicy"; ResourceId = "pol-1"; ResourceName = "Test Policy"
            ChangedProperty = "State"; ExpectedValue = "enabled"; ObservedValue = "disabled"
            DetectedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
            BusinessImpact = "test"; Recommendation = "fix it"
        }
    }
}

Describe "Export-DriftCSV" {
    It "writes CSV with header for findings" {
        $tmp = Join-Path $env:TEMP ("csv-{0}" -f (Get-Random))
        $file = Join-Path $tmp "out.csv"
        $p = Export-DriftCSV -Findings @(New-Finding) -OutputPath $file
        Test-Path $p | Should -BeTrue
        (Get-Content $p -Raw) | Should -Match "FindingId"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    It "handles empty findings" {
        $tmp = Join-Path $env:TEMP ("csv-{0}" -f (Get-Random))
        $file = Join-Path $tmp "out.csv"
        $p = Export-DriftCSV -Findings @() -OutputPath $file
        Test-Path $p | Should -BeTrue
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Export-DriftJSON" {
    It "writes valid JSON" {
        $tmp = Join-Path $env:TEMP ("json-{0}" -f (Get-Random))
        $file = Join-Path $tmp "out.json"
        $payload = [PSCustomObject]@{ Hello = "world"; Count = 3 }
        $p = Export-DriftJSON -Payload $payload -OutputPath $file
        Test-Path $p | Should -BeTrue
        $obj = Get-Content $p -Raw | ConvertFrom-Json
        $obj.Hello | Should -Be "world"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Export-DriftHTML" {
    It "writes HTML with findings and severity" {
        $tmp = Join-Path $env:TEMP ("html-{0}" -f (Get-Random))
        $file = Join-Path $tmp "report.html"
        $p = Export-DriftHTML -Findings @(New-Finding) -TenantId "test-tenant" -OutputPath $file
        Test-Path $p | Should -BeTrue
        $h = Get-Content $p -Raw
        $h | Should -Match "<html"
        $h | Should -Match "test-tenant"
        $h | Should -Match "F-1"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    It "handles empty findings" {
        $tmp = Join-Path $env:TEMP ("html-{0}" -f (Get-Random))
        $file = Join-Path $tmp "empty.html"
        $p = Export-DriftHTML -Findings @() -TenantId "t" -OutputPath $file
        Test-Path $p | Should -BeTrue
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Add-DriftHistory" {
    It "creates new history file with entries" {
        $tmp = Join-Path $env:TEMP ("hist-{0}" -f (Get-Random))
        $file = Join-Path $tmp "history.json"
        $r = Add-DriftHistory -Findings @(New-Finding) -HistoryPath $file
        $r.EntryCount | Should -Be 1
        $r.Entries[0].Status | Should -Be "Active"
        $r.Entries[0].Occurrences | Should -Be 1
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    It "increments occurrence on repeated run" {
        $tmp = Join-Path $env:TEMP ("hist-{0}" -f (Get-Random))
        $file = Join-Path $tmp "history.json"
        Add-DriftHistory -Findings @(New-Finding) -HistoryPath $file | Out-Null
        $r = Add-DriftHistory -Findings @(New-Finding) -HistoryPath $file
        $r.Entries[0].Occurrences | Should -Be 2
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    It "marks previous finding as Resolved when it disappears" {
        $tmp = Join-Path $env:TEMP ("hist-{0}" -f (Get-Random))
        $file = Join-Path $tmp "history.json"
        Add-DriftHistory -Findings @(New-Finding -Id "F-A") -HistoryPath $file | Out-Null
        $r = Add-DriftHistory -Findings @(New-Finding -Id "F-B") -HistoryPath $file
        ($r.Entries | Where-Object { $_.FindingId -eq "F-A" }).Status | Should -Be "Resolved"
        ($r.Entries | Where-Object { $_.FindingId -eq "F-B" }).Status | Should -Be "Active"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
