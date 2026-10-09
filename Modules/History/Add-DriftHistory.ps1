function Add-DriftHistory {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Findings = @(),
        [Parameter(Mandatory)] [string]$HistoryPath
    )

    $Findings = @($Findings)
    $dir = Split-Path $HistoryPath -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    $history = @()
    if (Test-Path $HistoryPath) {
        try {
            $raw = Get-Content $HistoryPath -Raw | ConvertFrom-Json
            if ($raw.entries) { $history = @($raw.entries) }
        } catch {
            Write-DriftLog -Message ("Could not parse existing history: {0}" -f $_) -Level Warning -Component "History"
        }
    }

    $now = (Get-Date).ToUniversalTime().ToString("o")
    $activeIds = @()

    foreach ($f in $Findings) {
        $activeIds += $f.FindingId
        $existing = $history | Where-Object { $_.FindingId -eq $f.FindingId } | Select-Object -First 1
        if ($existing) {
            $existing.LastDetectedUtc = $now
            $existing.Occurrences = [int]$existing.Occurrences + 1
            $existing.Status = "Active"
        } else {
            $history += [PSCustomObject]@{
                FindingId         = $f.FindingId
                Severity          = $f.Severity
                Category          = $f.Category
                ResourceType      = $f.ResourceType
                ResourceId        = $f.ResourceId
                ResourceName      = $f.ResourceName
                FirstDetectedUtc  = $now
                LastDetectedUtc   = $now
                Occurrences       = 1
                Status            = "Active"
                ResolvedAtUtc     = $null
            }
        }
    }

    foreach ($h in $history) {
        if ($h.Status -eq "Active" -and $h.FindingId -notin $activeIds) {
            $h.Status = "Resolved"
            $h.ResolvedAtUtc = $now
        }
    }

    $payload = [PSCustomObject]@{
        Version      = "1.0.0"
        UpdatedAtUtc = $now
        EntryCount   = $history.Count
        Entries      = $history
    }
    $payload | ConvertTo-Json -Depth 20 | Set-Content -Path $HistoryPath -Encoding UTF8

    $activeCount = @($history | Where-Object { $_.Status -eq "Active" }).Count
    Write-DriftLog -Message ("History updated: {0} entries ({1} active)" -f $history.Count, $activeCount) -Level Success -Component "History"
    return $payload
}

function Get-DriftHistory {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$HistoryPath,
        [ValidateSet("All","Active","Resolved")] [string]$Status = "All"
    )

    if (-not (Test-Path $HistoryPath)) { return ,@() }
    $raw = Get-Content $HistoryPath -Raw | ConvertFrom-Json
    $entries = @($raw.Entries)
    if ($Status -ne "All") { $entries = @($entries | Where-Object { $_.Status -eq $Status }) }
    return ,$entries
}
