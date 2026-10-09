function Test-EngineConfiguration {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ConfigPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Config/EngineConfig.json")
    )

    $issues = @()

    if (-not (Test-Path $ConfigPath)) {
        $issues += "Config file not found: $ConfigPath"
        return [PSCustomObject]@{ IsValid = $false; Issues = $issues; Config = $null }
    }

    try { $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json }
    catch {
        $issues += "Config is not valid JSON: $_"
        return [PSCustomObject]@{ IsValid = $false; Issues = $issues; Config = $null }
    }

    if (-not $cfg.version)        { $issues += "Missing: version" }
    if (-not $cfg.tenant)         { $issues += "Missing: tenant" }
    if (-not $cfg.graph)          { $issues += "Missing: graph" }
    if (-not $cfg.paths)          { $issues += "Missing: paths" }
    if (-not $cfg.requiredModules){ $issues += "Missing: requiredModules" }

    if ($cfg.tenant) {
        if (-not $cfg.tenant.tenantId)              { $issues += "Missing: tenant.tenantId" }
        if (-not $cfg.tenant.clientId)              { $issues += "Missing: tenant.clientId" }
        if (-not $cfg.tenant.certificateThumbprint) { $issues += "Missing: tenant.certificateThumbprint" }
    }

    [PSCustomObject]@{
        IsValid = ($issues.Count -eq 0)
        Issues  = $issues
        Config  = $cfg
    }
}
