BeforeAll {
    $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    . (Join-Path $root "Modules/Load-Modules.ps1")
}

Describe "ConvertTo-DriftNormalizedResource" {
    It "extracts Id and DisplayName" {
        $r = [PSCustomObject]@{ Id = "pol-1"; DisplayName = "Test Policy"; State = "enabled" }
        $n = ConvertTo-DriftNormalizedResource -Resource $r -ResourceType "ConditionalAccessPolicy"
        $n.ResourceId   | Should -Be "pol-1"
        $n.DisplayName  | Should -Be "Test Policy"
        $n.ResourceType | Should -Be "ConditionalAccessPolicy"
    }
    It "excludes volatile properties (CreatedDateTime, ModifiedDateTime)" {
        $r = [PSCustomObject]@{ Id = "pol-1"; DisplayName = "X"; State = "enabled"; CreatedDateTime = "2024-01-01"; ModifiedDateTime = "2024-06-01" }
        $n = ConvertTo-DriftNormalizedResource -Resource $r -ResourceType "ConditionalAccessPolicy"
        $n.Properties.PSObject.Properties.Name | Should -Not -Contain "CreatedDateTime"
        $n.Properties.PSObject.Properties.Name | Should -Not -Contain "ModifiedDateTime"
    }
    It "preserves State property" {
        $r = [PSCustomObject]@{ Id = "pol-1"; DisplayName = "X"; State = "enabled" }
        $n = ConvertTo-DriftNormalizedResource -Resource $r -ResourceType "ConditionalAccessPolicy"
        $n.Properties.State | Should -Be "enabled"
    }
}

Describe "New-DriftSnapshot" {
    It "builds a snapshot with correct counts" {
        $resources = @(
            [PSCustomObject]@{ ResourceType = "CAP"; ResourceId = "1"; DisplayName = "A"; Properties = [PSCustomObject]@{} }
            [PSCustomObject]@{ ResourceType = "CAP"; ResourceId = "2"; DisplayName = "B"; Properties = [PSCustomObject]@{} }
        )
        $s = New-DriftSnapshot -Resources $resources -TenantId "tenant-xyz"
        $s.ResourceCount | Should -Be 2
        $s.TenantId      | Should -Be "tenant-xyz"
        $s.Version       | Should -Not -BeNullOrEmpty
        $s.CollectedAtUtc| Should -Not -BeNullOrEmpty
    }
    It "handles empty resources" {
        $s = New-DriftSnapshot -Resources @() -TenantId "tenant-xyz"
        $s.ResourceCount | Should -Be 0
    }
}

Describe "Export-DriftSnapshot" {
    It "writes snapshot to disk" {
        $tmp = Join-Path $env:TEMP ("snap-{0}" -f (Get-Random))
        $file = Join-Path $tmp "snap.json"
        $snapshot = New-DriftSnapshot -Resources @() -TenantId "tenant-test"
        $path = Export-DriftSnapshot -Snapshot $snapshot -OutputPath $file
        Test-Path $path | Should -BeTrue
        $obj = Get-Content $path -Raw | ConvertFrom-Json
        $obj.TenantId | Should -Be "tenant-test"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "New-DriftBaseline and Test-DriftBaseline" {
    It "creates and validates a baseline" {
        $tmp = Join-Path $env:TEMP ("bl-{0}" -f (Get-Random))
        $snapFile = Join-Path $tmp "snap.json"
        $blFile   = Join-Path $tmp "baseline.json"

        $snapshot = New-DriftSnapshot -Resources @() -TenantId "tenant-test"
        Export-DriftSnapshot -Snapshot $snapshot -OutputPath $snapFile | Out-Null

        $path = New-DriftBaseline -SnapshotPath $snapFile -BaselinePath $blFile
        Test-Path $path | Should -BeTrue

        $v = Test-DriftBaseline -BaselinePath $path
        $v.IsValid | Should -BeTrue
        $v.Baseline.TenantId | Should -Be "tenant-test"

        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
    It "rejects overwrite without -Force" {
        $tmp = Join-Path $env:TEMP ("bl-{0}" -f (Get-Random))
        $snapFile = Join-Path $tmp "snap.json"
        $blFile   = Join-Path $tmp "baseline.json"

        $snapshot = New-DriftSnapshot -Resources @() -TenantId "tenant-test"
        Export-DriftSnapshot -Snapshot $snapshot -OutputPath $snapFile | Out-Null
        New-DriftBaseline -SnapshotPath $snapFile -BaselinePath $blFile | Out-Null

        { New-DriftBaseline -SnapshotPath $snapFile -BaselinePath $blFile } | Should -Throw "*already exists*"
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
