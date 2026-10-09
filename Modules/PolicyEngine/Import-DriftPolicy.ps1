function Import-DriftPolicy {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$PolicyPath
    )

    if (-not (Test-Path $PolicyPath)) { throw ("Policy file not found: {0}" -f $PolicyPath) }

    try { $policy = Get-Content $PolicyPath -Raw | ConvertFrom-Json }
    catch { throw ("Policy file is not valid JSON: {0} - {1}" -f $PolicyPath, $_) }

    if (-not $policy.version)  { throw ("Policy missing version: {0}" -f $PolicyPath) }
    if (-not $policy.policies) { throw ("Policy missing policies array: {0}" -f $PolicyPath) }

    $validRules = @("Required","MustBe","MustNotBe","MustBeOneOf","MustNotBeOneOf","MustExist")

    $policies = @()
    foreach ($p in @($policy.policies)) {
        if (-not $p.id)           { throw "Policy entry missing id: $PolicyPath" }
        if (-not $p.resourceType) { throw ("Policy {0} missing resourceType" -f $p.id) }
        if (-not $p.property)     { throw ("Policy {0} missing property" -f $p.id) }
        if (-not $p.rule)         { throw ("Policy {0} missing rule" -f $p.id) }
        if ($p.rule -notin $validRules) { throw ("Policy {0} has invalid rule: {1}" -f $p.id, $p.rule) }
        if (-not $p.severity)     { throw ("Policy {0} missing severity" -f $p.id) }

        $policies += $p
    }

    return ,@($policies)
}

function Import-DriftAllPolicies {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [string]$PolicyRoot
    )

    if (-not (Test-Path $PolicyRoot)) { throw ("Policy root not found: {0}" -f $PolicyRoot) }

    $files = Get-ChildItem -Path $PolicyRoot -Filter "*.json" | Where-Object { $_.Name -ne "PolicySchema.json" }
    $all = @()
    foreach ($f in $files) {
        $all += Import-DriftPolicy -PolicyPath $f.FullName
    }
    return ,@($all)
}
