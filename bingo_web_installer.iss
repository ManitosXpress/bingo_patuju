; Script generado para Inno Setup
; Objetivo: Crear un instalador que solo genere accesos directos a la PWA Web
; Documentación: http://www.jrsoftware.org/ishelp/

#define MyAppName "Bingo Imperial"
#define MyAppVersion "1.3"
#define MyAppPublisher "Imperial"
#define MyAppURL "https://bingo-baitty.web.app"
#define MyAppExeName "msedge.exe"

[Setup]
; NOTA: El valor de AppId identifica esta aplicación de forma única.
; No lo cambies en actualizaciones futuras.
AppId={{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableDirPage=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Ubicación del icono (DEBES CONVERTIR TU PNG A ICO PRIMERO)
SetupIconFile=web\icons\setup_icon.ico
OutputBaseFilename=Instalador_BingoImperial
Compression=lzma
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\icon.ico

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
Source: "web\icons\setup_icon.ico"; DestDir: "{app}"; DestName: "icon.ico"
; No copiamos archivos de la aplicación porque es Web.
; Solo necesitamos un archivo dummy o simplemente crear los accesos directos.
; Inno Setup requiere al menos una entrada o configuración.
; En este caso, no instalamos archivos, solo creamos accesos directos.

[Icons]
; Acceso directo en el Escritorio
Name: "{autodesktop}\{#MyAppName}"; Filename: "{code:GetBrowserPath}"; Parameters: "--app={#MyAppURL} --start-maximized"; IconFilename: "{app}\icon.ico"; Tasks: desktopicon

; Acceso directo en el Menú Inicio
Name: "{group}\{#MyAppName}"; Filename: "{code:GetBrowserPath}"; Parameters: "--app={#MyAppURL} --start-maximized"; IconFilename: "{app}\icon.ico"

; Enlace para desinstalar
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Code]
// Verificamos si Edge está instalado, si no, intentamos Chrome
function GetBrowserPath(Param: String): String;
begin
  if FileExists(ExpandConstant('{pf}\Microsoft\Edge\Application\msedge.exe')) then
    Result := ExpandConstant('{pf}\Microsoft\Edge\Application\msedge.exe')
  else if FileExists(ExpandConstant('{pf86}\Microsoft\Edge\Application\msedge.exe')) then
    Result := ExpandConstant('{pf86}\Microsoft\Edge\Application\msedge.exe')
  else if FileExists(ExpandConstant('{pf}\Google\Chrome\Application\chrome.exe')) then
    Result := ExpandConstant('{pf}\Google\Chrome\Application\chrome.exe')
  else if FileExists(ExpandConstant('{pf86}\Google\Chrome\Application\chrome.exe')) then
    Result := ExpandConstant('{pf86}\Google\Chrome\Application\chrome.exe')
  else
    // Fallback a Edge por defecto (el sistema lo manejará o fallará si no existe)
    Result := 'msedge.exe';
end;

// Nota: En la sección [Icons] usamos msedge.exe directamente por simplicidad,
// asumiendo Windows 10/11 donde Edge es estándar.
