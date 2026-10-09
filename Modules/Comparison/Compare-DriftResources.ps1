function Compare-DriftResources {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$BaselineResources = @(),
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$CurrentResources  = @()
    )

    $BaselineResources = @($BaselineResources)
    $CurrentResources  = @($CurrentResources)

    $baselineIndex = @{}
    foreach ($r in $BaselineResources) { $baselineIndex[$r.ResourceId] = $r }
    $currentIndex  = @{}
    foreach ($r in $CurrentResources)  { $currentIndex[$r.ResourceId]  = $r }

    $added = @()
    $removed = @()
    $modified = @()

    # Added: in current but not baseline
    foreach ($id in $currentIndex.Keys) {
        if (-not $baselineIndex.ContainsKey($id)) { $added += $currentIndex[$id] }
    }

    # Removed: in baseline but not current
    foreach ($id in $baselineIndex.Keys) {
        if (-not $currentIndex.ContainsKey($id)) { $removed += $baselineIndex[$id] }
    }

    # Modified: in both, but properties differ
    foreach ($id in $currentIndex.Keys) {
        if (-not $baselineIndex.ContainsKey($id)) { continue }
        $b = $baselineIndex[$id]
        $c = $currentIndex[$id]

        $changes = Get-DriftPropertyChanges -Baseline $b.Properties -Current $c.Properties
        if ($changes.Count -gt 0) {
            $modified += [PSCustomObject]@{
                ResourceType = $c.ResourceType
                ResourceId   = $id
                DisplayName  = $c.DisplayName
                Changes      = $changes
            }
        }
    }

    [PSCustomObject]@{
        Added    = @($added)
        Removed  = @($removed)
        Modified = @($modified)
        Summary  = [PSCustomObject]@{
            BaselineCount = $BaselineResources.Count
            CurrentCount  = $CurrentResources.Count
            AddedCount    = $added.Count
            RemovedCount  = $removed.Count
            ModifiedCount = $modified.Count
        }
    }
}
