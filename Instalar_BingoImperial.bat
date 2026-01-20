@echo off
setlocal

:: ============================================================
:: CONFIGURACION - PON TU URL AQUI
:: ============================================================
set "WEB_URL=[TU_URL_FIREBASE_AQUI]"
set "SHORTCUT_NAME=Bingo Imperial"
:: ============================================================

echo.
echo ============================================================
echo      INSTALADOR DE ACCESO DIRECTO - BINGO IMPERIAL
echo ============================================================
echo.

if "%WEB_URL%"=="[TU_URL_FIREBASE_AQUI]" (
    echo [ERROR] No has configurado la URL de Firebase.
    echo Por favor, edita este archivo y reemplaza [TU_URL_FIREBASE_AQUI] con tu URL real.
    echo.
    pause
    exit /b
)

:: Determinar la ruta del Escritorio
for /f "usebackq tokens=3*" %%D in (`reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop`) do set DESKTOP_PATH=%%D
call set DESKTOP_PATH=%%DESKTOP_PATH%%

set "SHORTCUT_PATH=%DESKTOP_PATH%\%SHORTCUT_NAME%.lnk"

echo Creando acceso directo en: "%SHORTCUT_PATH%"
echo Apuntando a: %WEB_URL%
echo.

:: Crear el script de PowerShell temporal para generar el acceso directo
set "PS_SCRIPT=%TEMP%\CreateShortcut.ps1"
echo $WshShell = New-Object -comObject WScript.Shell > "%PS_SCRIPT%"
echo $Shortcut = $WshShell.CreateShortcut("%SHORTCUT_PATH%") >> "%PS_SCRIPT%"

:: Intentar usar Chrome primero, luego Edge
set "BROWSER_PATH="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "BROWSER_PATH=C:\Program Files\Google\Chrome\Application\chrome.exe"
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "BROWSER_PATH=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) else (
    set "BROWSER_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)

echo Usando navegador: "%BROWSER_PATH%"
echo $Shortcut.TargetPath = "%BROWSER_PATH%" >> "%PS_SCRIPT%"
echo $Shortcut.Arguments = "--app=%WEB_URL%" >> "%PS_SCRIPT%"
echo $Shortcut.WindowStyle = 1 >> "%PS_SCRIPT%"
echo $Shortcut.Description = "Sistema de Gestión Bingo Imperial" >> "%PS_SCRIPT%"
echo $Shortcut.Save() >> "%PS_SCRIPT%"

:: Ejecutar el script de PowerShell
powershell -ExecutionPolicy Bypass -File "%PS_SCRIPT%"

:: Limpiar
del "%PS_SCRIPT%"

echo.
echo [EXITO] Acceso directo creado correctamente en el Escritorio.
echo.
pause
