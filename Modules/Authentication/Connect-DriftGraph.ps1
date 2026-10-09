function Connect-DriftGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$TenantId,
        [Parameter(Mandatory)] [string]$ClientId,
        [Parameter(Mandatory)] [string]$CertificateThumbprint,
        [switch]$SkipHealthCheck
    )

    Write-DriftLog -Message "Connecting to Microsoft Graph (app-only)..." -Level Info -Component "Auth"

    $cert = Get-ChildItem "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
    if (-not $cert) {
        throw ("Certificate {0} not found in Cert:\CurrentUser\My" -f $CertificateThumbprint)
    }
    if (-not $cert.HasPrivateKey) {
        throw ("Certificate {0} has no private key" -f $CertificateThumbprint)
    }

    $existing = Get-MgContext -ErrorAction SilentlyContinue
    if ($existing) {
        Write-DriftLog -Message "Disconnecting existing Graph session." -Level Info -Component "Auth"
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -CertificateThumbprint $CertificateThumbprint -NoWelcome -ErrorAction Stop

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
