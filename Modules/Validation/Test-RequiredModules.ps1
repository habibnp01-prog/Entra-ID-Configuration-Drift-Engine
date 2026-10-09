function Test-DriftRequiredModules {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory)] [array]$RequiredModules
    )

    $results = @()
    foreach ($req in $RequiredModules) {
        $installed = Get-Module -ListAvailable -Name $req.name |
                     Sort-Object Version -Descending | Select-Object -First 1
        $isInstalled  = $null -ne $installed
        $meetsVersion = $isInstalled -and ($installed.Version -ge [version]$req.minimumVersion)

        $results += [PSCustomObject]@{
            Name             = $req.name
            MinimumVersion   = $req.minimumVersion
            InstalledVersion = if ($isInstalled) { $installed.Version.ToString() } else { $null }
            IsInstalled      = $isInstalled
            MeetsVersion     = $meetsVersion
            Status           = if (-not $isInstalled) { "Missing" } elseif (-not $meetsVersion) { "Outdated" } else { "OK" }
        }
    }

    return ,$results
}
