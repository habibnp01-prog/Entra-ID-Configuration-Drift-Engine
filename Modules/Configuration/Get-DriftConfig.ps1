function Get-DriftConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ConfigPath,
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertificateThumbprint,
        [string]$CertificateSubject = "CN=EntraDriftEngine"
    )

    if (-not $ConfigPath) {
        $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $ConfigPath = Join-Path $root "Config/EngineConfig.json"
    }

    if (-not (Test-Path $ConfigPath)) {
        throw ("Config file not found: {0}" -f $ConfigPath)
    }
    $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    $localPath = $ConfigPath -replace '\.json$', '.local.json'
    if (Test-Path $localPath) {
        try {
            $local = Get-Content $localPath -Raw | ConvertFrom-Json
            if ($local.tenant) {
                foreach ($prop in $local.tenant.PSObject.Properties) {
                    $cfg.tenant | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
                }
            }
        } catch {
            Write-Host ("[WARN] Could not merge local config: {0}" -f $_) -ForegroundColor Yellow
        }
    }

    $envTenant = $env:ENTRA_DRIFT_TENANT_ID
    $envClient = $env:ENTRA_DRIFT_CLIENT_ID
    $envThumb  = $env:ENTRA_DRIFT_CERT_THUMBPRINT

    $resolvedTenant = if ($TenantId)              { $TenantId }
                      elseif ($envTenant)         { $envTenant }
                      elseif ($cfg.tenant.tenantId -and $cfg.tenant.tenantId -notlike "REPLACE*") { $cfg.tenant.tenantId }
                      else                        { $null }

    $resolvedClient = if ($ClientId)              { $ClientId }
                      elseif ($envClient)         { $envClient }
                      elseif ($cfg.tenant.clientId -and $cfg.tenant.clientId -notlike "REPLACE*") { $cfg.tenant.clientId }
                      else                        { $null }

    $resolvedThumb  = if ($CertificateThumbprint) { $CertificateThumbprint }
                      elseif ($envThumb)          { $envThumb }
                      elseif ($cfg.tenant.certificateThumbprint -and $cfg.tenant.certificateThumbprint -notlike "REPLACE*") { $cfg.tenant.certificateThumbprint }
                      else                        { $null }

    $certSource = "explicit"
    if (-not $resolvedThumb) {
        $certs = Get-ChildItem "Cert:\CurrentUser\My" |
                 Where-Object { $_.Subject -eq $CertificateSubject -and $_.HasPrivateKey } |
                 Sort-Object NotAfter -Descending
        if ($certs) {
            $resolvedThumb = $certs[0].Thumbprint
            $certSource = "auto-discovered from Cert:\CurrentUser\My"
        }
    }

    $missing = @()
    if (-not $resolvedTenant) { $missing += "TenantId (config, -TenantId, or ENTRA_DRIFT_TENANT_ID)" }
    if (-not $resolvedClient) { $missing += "ClientId (config, -ClientId, or ENTRA_DRIFT_CLIENT_ID)" }
    if (-not $resolvedThumb)  { $missing += "CertificateThumbprint (config, -CertificateThumbprint, ENTRA_DRIFT_CERT_THUMBPRINT, or a cert with subject '$CertificateSubject')" }

    if ($missing.Count -gt 0) {
        throw ("Missing required configuration: {0}" -f ($missing -join "; "))
    }

    $cert = Get-ChildItem "Cert:\CurrentUser\My\$resolvedThumb" -ErrorAction SilentlyContinue
    if (-not $cert) {
        throw ("Certificate {0} not found in Cert:\CurrentUser\My." -f $resolvedThumb)
    }
    if (-not $cert.HasPrivateKey) {
        throw ("Certificate {0} has no private key." -f $resolvedThumb)
    }

    [PSCustomObject]@{
        TenantId              = $resolvedTenant
        ClientId              = $resolvedClient
        CertificateThumbprint = $resolvedThumb
        CertificateSubject    = $cert.Subject
        CertificateNotAfter   = $cert.NotAfter
        CertificateSource     = $certSource
        RawConfig             = $cfg
        ConfigPath            = $ConfigPath
    }
}

function Test-DriftConfig {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ConfigPath,
        [string]$CertificateSubject = "CN=EntraDriftEngine"
    )

    try {
        $resolved = Get-DriftConfig -ConfigPath $ConfigPath -CertificateSubject $CertificateSubject
        [PSCustomObject]@{
            IsValid  = $true
            Resolved = $resolved
            Errors   = @()
        }
    } catch {
        [PSCustomObject]@{
            IsValid  = $false
            Resolved = $null
            Errors   = @("$_")
        }
    }
}
