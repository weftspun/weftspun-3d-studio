# Remove legacy CharacterStudio folder after migration to Weftspun3DStudio.
# Run on Surface when Cursor is opened on Weftspun3DStudio (not the old folder).
$ErrorActionPreference = 'Stop'
$old = 'C:\Users\alfao\Documents\GitHub\CharacterStudio'
$new = 'C:\Users\alfao\Documents\GitHub\Weftspun3DStudio'
if (-not (Test-Path (Join-Path $new 'package.json'))) {
    Write-Error "Weftspun3DStudio not ready: $new"
}
if (-not (Test-Path $old)) {
    Write-Host 'Legacy CharacterStudio folder already removed.'
    exit 0
}
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Remove-Item -LiteralPath $old -Recurse -Force
Write-Host "Removed legacy folder: $old"
