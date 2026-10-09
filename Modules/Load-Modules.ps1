# Modules/Load-Modules.ps1
# Dot-source all .ps1 files in Modules/ (except this one and Load-Modules itself)

$modulesRoot = $PSScriptRoot
$files = Get-ChildItem -Path $modulesRoot -Filter "*.ps1" -Recurse |
         Where-Object { $_.Name -ne "Load-Modules.ps1" } |
         Sort-Object FullName

foreach ($f in $files) {
    try { . $f.FullName }
    catch { Write-Host "[WARN] Failed to load $($f.Name): $_" -ForegroundColor Yellow }
}

Write-Host "[OK] Loaded $($files.Count) module files." -ForegroundColor Green
