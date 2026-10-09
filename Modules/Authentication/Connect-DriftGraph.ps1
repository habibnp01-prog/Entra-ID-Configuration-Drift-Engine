function Connect-DriftGraph {
    [CmdletBinding()]
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertificateThumbprint,
        [string]$CertificateSubject = "CN=EntraDriftEngine",
        [switch]$SkipHealthCheck
    )

    # Resolve config dynamically
    $resolved = Get-DriftConfig -TenantId $TenantId -ClientId $ClientId `
                                 -CertificateThumbprint $CertificateThumbprint `
                                 -CertificateSubject $CertificateSubject

    Write-DriftLog -Message "Connecting to Microsoft Graph (app-only)..." -Level Info -Component "Auth"
    Write-DriftLog -Message ("  Tenant : {0}" -f $resolved.TenantId)   -Level Info -Component "Auth"
    Write-DriftLog -Message ("  Client : {0}" -f $resolved.ClientId)   -Level Info -Component "Auth"
    Write-DriftLog -Message ("  Cert   : {0} ({1})" -f $resolved.CertificateThumbprint, $resolved.CertificateSource) -Level Info -Component "Auth"

    # Disconnect any existing session
    $existing = Get-MgContext -ErrorAction SilentlyContinue
    if ($existing) {
        Write-DriftLog -Message "Disconnecting existing Graph session." -Level Info -Component "Auth"
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    Connect-MgGraph -TenantId $resolved.TenantId `
                    -ClientId $resolved.ClientId `
                    -CertificateThumbprint $resolved.CertificateThumbprint `
                    -NoWelcome -ErrorAction Stop

    $ctx = Get-MgContext
    Write-DriftLog -Message ("Connected. Tenant: {0} | AppId: {1} | AuthType: {2}" -f $ctx.TenantId, $ctx.ClientId, $ctx.AuthType) -Level Success -Component "Auth"

    if (-not $SkipHealthCheck) {
        if ($ctx.AuthType -ne "AppOnly") {
            throw ("Expected AuthType AppOnly but got {0}" -f $ctx.AuthType)
        }
    }

    return $ctx
}

function Test-DriftGraphConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    try {
        $ctx = Get-MgContext -ErrorAction Stop
        return ($null -ne $ctx -and $null -ne $ctx.TenantId)
    } catch {
        return $false
    }
}

function Disconnect-DriftGraph {
    [CmdletBinding()]
    param()
    try {
        Disconnect-MgGraph -ErrorAction Stop | Out-Null
        Write-DriftLog -Message "Disconnected from Graph." -Level Success -Component "Auth"
    } catch {
        Write-DriftLog -Message ("Disconnect reported: {0}" -f $_) -Level Warning -Component "Auth"
    }
}
