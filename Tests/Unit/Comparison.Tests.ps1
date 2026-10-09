BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")

    function New-TestResource {
        param([string]$Id, [string]$Type = "CAP", [hashtable]$Props = @{})
        [PSCustomObject]@{
            ResourceType = $Type
            ResourceId   = $Id
            DisplayName  = "Resource-$Id"
            Properties   = [PSCustomObject]$Props
        }
    }
}

Describe "Compare-DriftResources" {
    It "detects added resources" {
        $b = @(New-TestResource -Id "1" -Props @{ State = "enabled" })
        $c = @(New-TestResource -Id "1" -Props @{ State = "enabled" }; New-TestResource -Id "2" -Props @{ State = "enabled" })
        $r = Compare-DriftResources -BaselineResources $b -CurrentResources $c
        $r.Summary.AddedCount    | Should -Be 1
        $r.Summary.RemovedCount  | Should -Be 0
        $r.Summary.ModifiedCount | Should -Be 0
    }
    It "detects removed resources" {
        $b = @(New-TestResource -Id "1" -Props @{ State = "enabled" }; New-TestResource -Id "2" -Props @{ State = "enabled" })
        $c = @(New-TestResource -Id "1" -Props @{ State = "enabled" })
        $r = Compare-DriftResources -BaselineResources $b -CurrentResources $c
        $r.Summary.RemovedCount | Should -Be 1
    }
    It "detects modified properties" {
        $b = @(New-TestResource -Id "1" -Props @{ State = "enabled" })
        $c = @(New-TestResource -Id "1" -Props @{ State = "disabled" })
        $r = Compare-DriftResources -BaselineResources $b -CurrentResources $c
        $r.Summary.ModifiedCount | Should -Be 1
        $r.Modified[0].Changes[0].Property | Should -Be "State"
        $r.Modified[0].Changes[0].ExpectedValue | Should -Be "enabled"
        $r.Modified[0].Changes[0].ObservedValue | Should -Be "disabled"
    }
    It "no changes for identical snapshots" {
        $b = @(New-TestResource -Id "1" -Props @{ State = "enabled" })
        $r = Compare-DriftResources -BaselineResources $b -CurrentResources $b
        $r.Summary.AddedCount    | Should -Be 0
        $r.Summary.RemovedCount  | Should -Be 0
        $r.Summary.ModifiedCount | Should -Be 0
    }
    It "handles empty baseline" {
        $b = @()
        $c = @(New-TestResource -Id "1")
        $r = Compare-DriftResources -BaselineResources $b -CurrentResources $c
        $r.Summary.AddedCount | Should -Be 1
    }
    It "handles both empty" {
        $r = Compare-DriftResources -BaselineResources @() -CurrentResources @()
        $r.Summary.AddedCount    | Should -Be 0
        $r.Summary.RemovedCount  | Should -Be 0
        $r.Summary.ModifiedCount | Should -Be 0
    }
}

Describe "ConvertTo-DriftFindings" {
    It "converts added resources to findings" {
        $cmp = [PSCustomObject]@{
            Added    = @(New-TestResource -Id "new-1")
            Removed  = @()
            Modified = @()
            Summary  = [PSCustomObject]@{ AddedCount = 1; RemovedCount = 0; ModifiedCount = 0 }
        }
        $f = ConvertTo-DriftFindings -Comparison $cmp
        $f.Count | Should -Be 1
        $f[0].Category | Should -Be "Added"
        $f[0].Severity | Should -Be "High"
        $f[0].FindingId | Should -Be "DRIFT-ADDED-001"
    }
    It "converts removed resources to Critical" {
        $cmp = [PSCustomObject]@{
            Added    = @()
            Removed  = @(New-TestResource -Id "gone-1")
            Modified = @()
            Summary  = [PSCustomObject]@{ AddedCount = 0; RemovedCount = 1; ModifiedCount = 0 }
        }
        $f = ConvertTo-DriftFindings -Comparison $cmp
        $f[0].Severity | Should -Be "Critical"
    }
    It "converts each property change to its own finding" {
        $m = [PSCustomObject]@{
            ResourceType = "CAP"
            ResourceId   = "pol-12345678"
            DisplayName  = "Test"
            Changes      = @(
                [PSCustomObject]@{ Property = "State"; ExpectedValue = "enabled"; ObservedValue = "disabled"; ChangeType = "Modified" }
                [PSCustomObject]@{ Property = "MfaRequired"; ExpectedValue = $true; ObservedValue = $false; ChangeType = "Modified" }
            )
        }
        $cmp = [PSCustomObject]@{
            Added    = @()
            Removed  = @()
            Modified = @($m)
            Summary  = [PSCustomObject]@{ AddedCount = 0; RemovedCount = 0; ModifiedCount = 1 }
        }
        $f = ConvertTo-DriftFindings -Comparison $cmp
        $f.Count | Should -Be 2
        $f[0].Category | Should -Be "Modified"
        $f[1].Category | Should -Be "Modified"
    }
}

Describe "Invoke-DriftAssessment" {
    It "runs end-to-end from baseline and snapshot files" {
        $tmp = Join-Path $env:TEMP ("assess-{0}" -f (Get-Random))
        New-Item -ItemType Directory -Path $tmp -Force | Out-Null

        $baselineObj = [PSCustomObject]@{
            BaselineVersion = "1.0.0"
            TenantId        = "tenant-test"
            ResourceCount   = 1
            Resources       = @([PSCustomObject]@{ ResourceType = "CAP"; ResourceId = "1"; DisplayName = "A"; Properties = [PSCustomObject]@{ State = "enabled" } })
        }
        $snapshotObj = [PSCustomObject]@{
            Version         = "0.3.0"
            TenantId        = "tenant-test"
            CollectedAtUtc  = (Get-Date).ToUniversalTime().ToString("o")
            ResourceCount   = 2
            Resources       = @(
                [PSCustomObject]@{ ResourceType = "CAP"; ResourceId = "1"; DisplayName = "A"; Properties = [PSCustomObject]@{ State = "disabled" } }
                [PSCustomObject]@{ ResourceType = "CAP"; ResourceId = "2"; DisplayName = "B"; Properties = [PSCustomObject]@{ State = "enabled" } }
            )
        }

        $blFile  = Join-Path $tmp "baseline.json"
        $snapFile = Join-Path $tmp "snapshot.json"
        $baselineObj | ConvertTo-Json -Depth 20 | Set-Content $blFile -Encoding UTF8
        $snapshotObj | ConvertTo-Json -Depth 20 | Set-Content $snapFile -Encoding UTF8

        $result = Invoke-DriftAssessment -BaselinePath $blFile -SnapshotPath $snapFile
        $result.FindingCount | Should -Be 2  # 1 added + 1 modified
        $result.Summary.AddedCount    | Should -Be 1
        $result.Summary.ModifiedCount | Should -Be 1

        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
