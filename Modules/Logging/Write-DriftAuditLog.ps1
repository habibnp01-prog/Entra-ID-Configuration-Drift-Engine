function Write-DriftAuditLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Action,
        [string]$ResourceType,
        [string]$ResourceId,
        [string]$Details,
        [string]$LogRoot = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Logs")
    )

    $auditRoot = Join-Path $LogRoot "Audit"
    if (-not (Test-Path $auditRoot)) { New-Item -ItemType Directory -Path $auditRoot -Force | Out-Null }

    $entry = [PSCustomObject]@{
        Timestamp    = (Get-Date).ToString("o")
        Action       = $Action
        ResourceType = $ResourceType
        ResourceId   = $ResourceId
        Details      = $Details
        User         = "$env:USERNAME@$env:COMPUTERNAME"
    }

    $file = Join-Path $auditRoot ("audit-{0}.log" -f (Get-Date -Format "yyyy-MM-dd"))
    $entry | ConvertTo-Json -Compress | Add-Content -Path $file -Encoding UTF8
}
