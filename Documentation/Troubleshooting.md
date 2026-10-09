# Troubleshooting

## Authentication fails

**Symptom:** `ClientCertificateCredential authentication failed`

**Checklist:**

1. Is the certificate in `Cert:\CurrentUser\My` with a private key?
   ```powershell
   Get-ChildItem Cert:\CurrentUser\My | Where-Object Thumbprint -eq "YOUR_THUMBPRINT"
   ```
2. Does `HasPrivateKey` show `True`?
3. Is the thumbprint in `Config/EngineConfig.json` correct?
4. Is the certificate uploaded to the Entra app under **Certificates & secrets**?
5. Are all four API permissions granted with admin consent?

## "No snapshot found"

You ran `-Mode Assess`, `-Mode PolicyCheck`, or `-Mode Report` before running `-Mode Collect`.

Solution: run `-Mode Collect` first, or pass `-SnapshotPath` explicitly.

## "No baseline found"

You ran `-Mode Assess` before running `-Mode Baseline`.

Solution: run `-Mode Baseline` after reviewing a snapshot.

## Tests fail with `ParameterBindingValidationException`

An empty array was passed to a `[Parameter(Mandatory)]` parameter.

Fix: add `[AllowEmptyCollection()]` to the parameter.

## JSON parse errors

Config files must be valid JSON. Validate with:

```powershell
Get-Content Config/EngineConfig.json -Raw | ConvertFrom-Json
```

## Graph throttling

The SDK retries automatically. If throttling persists:

- Reduce `maxCollectionRetries` in the config
- Run outside business hours
- Consider narrowing collector scope
