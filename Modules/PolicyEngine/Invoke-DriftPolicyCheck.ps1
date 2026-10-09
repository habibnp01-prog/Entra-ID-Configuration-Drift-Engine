function Invoke-DriftPolicyCheck {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Resources = @(),
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Policies = @(),
        [AllowEmptyCollection()] [object[]]$Exceptions = @()
    )

    $Resources = @($Resources)
    $Policies  = @($Policies)
    $Exceptions = @($Exceptions)

    $findings = @()
    $evaluated = 0
    $suppressed = 0
    $today = (Get-Date).ToString("yyyy-MM-dd")

    foreach ($res in $Resources) {
        foreach ($pol in $Policies) {
            if ($pol.resourceType -ne $res.ResourceType) { continue }
            $evaluated++

            $r = Test-DriftPolicyRule -Policy $pol -Resource $res
            if ($r.Passes) { continue }

            # Check exceptions
            $ex = $Exceptions | Where-Object {
                $_.policyId -eq $pol.id -and
                ($null -eq $_.resourceId -or $_.resourceId -eq $res.ResourceId)
            } | Select-Object -First 1

            if ($ex) {
                if ($ex.expiresOn -and $ex.expiresOn -lt $today) {
                    Write-DriftLog -Message ("Exception for {0} on {1} expired on {2}" -f $pol.id, $res.ResourceId, $ex.expiresOn) -Level Warning -Component "Policy"
                } else {
                    $suppressed++
                    continue
                }
            }

            $findings += [PSCustomObject]@{
                FindingId     = ("POLICY-{0}-{1}" -f $pol.id, $res.ResourceId.Substring(0, [Math]::Min(8, $res.ResourceId.Length)))
                PolicyId      = $pol.id
                PolicyName    = $pol.name
                Severity      = $pol.severity
                ResourceType  = $res.ResourceType
                ResourceId    = $res.ResourceId
                ResourceName  = $res.DisplayName
                Property      = $pol.property
                Rule          = $pol.rule
                ExpectedValue = $r.ExpectedValue
                ObservedValue = $r.ObservedValue
                Reason        = $r.Reason
                DetectedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
                Remediation   = $pol.remediation
                References    = $pol.references
            }
        }
    }

    return [PSCustomObject]@{
        EvaluatedCount = $evaluated
        SuppressedCount = $suppressed
        Findings       = @($findings)
        FindingCount   = $findings.Count
        SeverityCounts = [PSCustomObject]@{
            Critical = @($findings | Where-Object { $_.Severity -eq "Critical" }).Count
            High     = @($findings | Where-Object { $_.Severity -eq "High" }).Count
            Medium   = @($findings | Where-Object { $_.Severity -eq "Medium" }).Count
            Low      = @($findings | Where-Object { $_.Severity -eq "Low" }).Count
        }
    }
}
