# Installation

## Requirements

- PowerShell 7.0 or later
- Microsoft.Graph PowerShell SDK 2.0+
- Pester 5.0+ (for tests)
- An Entra ID tenant with app registration rights

## Steps

### 1. Clone the repository

```powershell
git clone https://github.com/habibnp01-prog/Entra-ID-Configuration-Drift-Engine.git
cd Entra-ID-Configuration-Drift-Engine
```

### 2. Install dependencies

```powershell
Install-Module Microsoft.Graph -MinimumVersion 2.0.0 -Scope CurrentUser -Force -AllowClobber
Install-Module Pester -MinimumVersion 5.0.0 -Scope CurrentUser -Force -SkipPublisherCheck
```

### 3. Register an Entra app

See `Documentation/Authentication.md` for the full walkthrough.

### 4. Configure the engine

Copy the template and fill in your tenant values:

```powershell
Copy-Item Config/EngineConfig.json Config/EngineConfig.local.json
# Edit Config/EngineConfig.local.json with your tenantId, clientId, certificateThumbprint
```

### 5. Validate

```powershell
.\Start-EntraDriftEngine.ps1 -Mode Validate
```

Expected: config valid, all required modules present.

### 6. First collection

```powershell
.\Start-EntraDriftEngine.ps1 -Mode Collect
```

### 7. Approve a baseline

Review the snapshot in `Reports/JSON/`, then:

```powershell
.\Start-EntraDriftEngine.ps1 -Mode Baseline
```

### 8. Run drift detection

```powershell
.\Start-EntraDriftEngine.ps1 -Mode Assess
.\Start-EntraDriftEngine.ps1 -Mode Report
```

The HTML report opens with a summary of any drift.
