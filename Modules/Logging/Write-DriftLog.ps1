function Write-DriftLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Message,
        [ValidateSet("Info","Warning","Error","Success","Verbose")] [string]$Level = "Info",
        [string]$Component = "Engine",
        [string]$LogRoot = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "Logs")
    )

    if (-not (Test-Path $LogRoot)) { New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null }

    $colors = @{ Info="Cyan"; Warning="Yellow"; Error="Red"; Success="Green"; Verbose="DarkGray" }
    Write-Host "[$Level] $Message" -ForegroundColor $colors[$Level]

    $entry = [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("o")
        Level     = $Level
        Component = $Component
        Message   = $Message
    }

    $file = Join-Path $LogRoot ("drift-{0}.log" -f (Get-Date -Format "yyyy-MM-dd"))
    $entry | ConvertTo-Json -Compress | Add-Content -Path $file -Encoding UTF8
}
