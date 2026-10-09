function Get-DriftEnvInfo {
    [CmdletBinding()]
    param([string]$ConfigPath)

    Write-Host "`n=== Configuration Sources ===" -ForegroundColor Cyan

    Write-Host "`nEnvironment variables:" -ForegroundColor Yellow
    foreach ($v in @("ENTRA_DRIFT_TENANT_ID","ENTRA_DRIFT_CLIENT_ID","ENTRA_DRIFT_CERT_THUMBPRINT")) {
        $val = [Environment]::GetEnvironmentVariable($v)
        $display = if ($val) { "$($val.Substring(0, [Math]::Min(8, $val.Length)))..." } else { "(not set)" }
        Write-Host ("  {0,-32} : {1}" -f $v, $display)
    }

    Write-Host "`nConfig files:" -ForegroundColor Yellow
    if (-not $ConfigPath) {
        $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $ConfigPath = Join-Path $root "Config/EngineConfig.json"
    }
    $exists = if (Test-Path $ConfigPath) { "[exists]" } else { "[MISSING]" }
    Write-Host ("  Default : {0}  {1}" -f $ConfigPath, $exists)
    $localPath = $ConfigPath -replace '\.json$', '.local.json'
    $localExists = if (Test-Path $localPath) { "[exists]" } else { "[not present]" }
    Write-Host ("  Local   : {0}  {1}" -f $localPath, $localExists)

    Write-Host "`nCertificates (Subject=CN=EntraDriftEngine):" -ForegroundColor Yellow
    $certs = @(Get-ChildItem "Cert:\CurrentUser\My" | Where-Object { $_.Subject -like "*EntraDriftEngine*" })
    if ($certs.Count -gt 0) {
        foreach ($c in $certs) {
            Write-Host ("  {0}  Expires: {1}  HasPrivateKey: {2}" -f $c.Thumbprint, $c.NotAfter.ToString("yyyy-MM-dd"), $c.HasPrivateKey)
        }
    } else {
        Write-Host "  (none found)" -ForegroundColor DarkYellow
    }

    Write-Host "`n=== Resolved Configuration ===" -ForegroundColor Cyan
    try {
        $resolved = Get-DriftConfig -ConfigPath $ConfigPath
        Write-Host ("  TenantId              : {0}" -f $resolved.TenantId)
        Write-Host ("  ClientId              : {0}" -f $resolved.ClientId)
        Write-Host ("  CertificateThumbprint : {0}" -f $resolved.CertificateThumbprint)
        Write-Host ("  CertificateSubject    : {0}" -f $resolved.CertificateSubject)
        Write-Host ("  CertificateNotAfter   : {0}" -f $resolved.CertificateNotAfter)
        Write-Host ("  CertificateSource     : {0}" -f $resolved.CertificateSource)
    } catch {
        Write-Host ("  [ERROR] {0}" -f $_) -ForegroundColor Red
    }
}
