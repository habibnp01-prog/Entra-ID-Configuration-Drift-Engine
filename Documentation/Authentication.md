# Authentication

The engine uses **certificate-based app-only authentication** against Microsoft Graph.

## 1. Generate a certificate

```powershell
$cert = New-SelfSignedCertificate -Subject "CN=EntraDriftEngine" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable -KeySpec Signature `
    -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears(2) `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")

Export-Certificate -Cert $cert -FilePath ".\EntraDriftEngine.cer"
$cert.Thumbprint
```

Note the thumbprint — you will need it for the config file.

## 2. Register an Entra app

1. Go to **https://entra.microsoft.com** -> **App registrations** -> **New registration**
2. Name: `EntraDriftEngine`
3. Supported account types: **Single tenant**
4. Redirect URI: leave blank
5. Register

## 3. Upload the certificate

1. In the app, go to **Certificates & secrets** -> **Certificates**
2. **Upload certificate**
3. Select `EntraDriftEngine.cer`
4. Verify the thumbprint matches

## 4. Grant API permissions

Under **API permissions** -> **Add a permission** -> **Microsoft Graph** -> **Application permissions**:

| Permission | Purpose |
|-----------|---------|
| `Policy.Read.All` | Conditional Access policies |
| `Directory.Read.All` | Directory roles, users, groups |
| `Application.Read.All` | Applications and service principals |
| `RoleManagement.Read.Directory` | Role assignments |

Then click **Grant admin consent** and confirm.

## 5. Configure the engine

Edit `Config/EngineConfig.json` (or `EngineConfig.local.json`):

```json
{
  "tenant": {
    "tenantId": "your-tenant-id",
    "clientId": "your-app-client-id",
    "certificateThumbprint": "your-cert-thumbprint"
  }
}
```

## 6. Verify

```powershell
.\Start-EntraDriftEngine.ps1 -Mode Collect
```

You should see resource counts per type. If authentication fails, check:

- Certificate is in `Cert:\CurrentUser\My` with private key
- Thumbprint in config matches the uploaded cert
- Admin consent has been granted for all four permissions
