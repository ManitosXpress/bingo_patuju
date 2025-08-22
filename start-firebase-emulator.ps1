# Script para iniciar el emulador de Firebase Functions
Write-Host "Iniciando emulador de Firebase Functions..." -ForegroundColor Green

# Navegar al directorio del proyecto
Set-Location $PSScriptRoot

# Iniciar el emulador de Firebase Functions
Write-Host "Iniciando emulador en http://localhost:5001" -ForegroundColor Yellow
firebase emulators:start --only functions

Write-Host "Emulador iniciado. Presiona Ctrl+C para detener." -ForegroundColor Green
