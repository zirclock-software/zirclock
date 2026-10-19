; Instalador de ZirClock para Windows (Ola 10, mitad Win) — Inno Setup 6.
;
; Lo compila build_win.ps1, que inyecta la versión con /DZVERSION=<x.y> leída
; de ZIRCLOCK_VERSION en main.py (misma fuente única que los dos .spec).
;
; ¿Por qué un instalador y no solo el .exe? En macOS un .app es autocontenido
; y basta arrastrarlo a Applications; el Info.plist se encarga del resto. En
; Windows no existe ese equivalente: la app es una CARPETA con el .exe y sus
; DLLs, y las tres cosas que el Info.plist daba gratis —ícono registrado,
; asociación de .zirchron y forma limpia de desinstalar— las tiene que hacer
; el instalador escribiendo en el registro. De ahí este archivo.

#ifndef ZVERSION
  #define ZVERSION "0.0"
#endif
#define AppName "ZirClock"
#define AppExe "ZirClock.exe"
#define AppPublisher "Guillermo Espejo Bautista"

[Setup]
; AppId identifica la app para actualizar/desinstalar. NO cambiarlo entre
; versiones: si cambia, Windows trata la 1.1 como un programa distinto y
; quedarían las dos instaladas a la vez.
AppId={{6CC875D6-338F-4097-AD8A-0D2A691BB371}
AppName={#AppName}
AppVersion={#ZVERSION}
AppVerName={#AppName} {#ZVERSION}
AppPublisher={#AppPublisher}
; El código fuente es público desde la 3.0 (GPL-3.0-or-later): Programs and
; Features enlaza al repositorio.
AppPublisherURL=https://github.com/zirclock-software/zirclock
AppSupportURL=https://github.com/zirclock-software/zirclock/issues
AppUpdatesURL=https://github.com/zirclock-software/zirclock/releases
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE.txt
OutputDir=..\dist
OutputBaseFilename=ZirClock-{#ZVERSION}-windows-setup
SetupIconFile=zirclock.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; ZirClock es de 64 bits (los wheels de PyQt6/numpy solo existen así).
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; "lowest" + "dialog": por defecto instala en la carpeta del usuario SIN pedir
; contraseña de administrador, y quien la tenga puede elegir instalar para
; todos. Pensado para las computadoras del laboratorio, donde el usuario no
; siempre es administrador.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Avisa a Windows que se tocaron asociaciones de archivo, para que el
; Explorador refresque los íconos sin reiniciar sesión.
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; \
    GroupDescription: "{cm:AdditionalIcons}"

[Files]
; La carpeta completa que produce PyInstaller (modo onedir): el .exe más el
; runtime de Python, las DLLs de Qt y guide_assets/.
Source: "..\dist\{#AppName}\*"; DestDir: "{app}"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; Asociación de los proyectos — el equivalente Windows del
; CFBundleDocumentTypes del Info.plist de macOS. main.py ya lee la ruta de
; sys.argv[1:], así que el "%1" le llega y el proyecto se abre solo.
; HKA = HKLM si se instaló para todos, HKCU si fue solo para este usuario.
Root: HKA; Subkey: "Software\Classes\.zirclock"; ValueType: string; \
    ValueName: ""; ValueData: "ZirClock.Project"; Flags: uninsdeletevalue
; Las extensiones heredadas: el programa se llamó "Zirchron" hasta la v1.3 y
; "Chronikon" de la 2.0 a la 2.3, y sus proyectos siguen en disco, así que el
; doble-clic los tiene que seguir abriendo.
Root: HKA; Subkey: "Software\Classes\.chronikon"; ValueType: string; \
    ValueName: ""; ValueData: "ZirClock.Project"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\.zirchron"; ValueType: string; \
    ValueName: ""; ValueData: "ZirClock.Project"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\ZirClock.Project"; ValueType: string; \
    ValueName: ""; ValueData: "ZirClock project"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\ZirClock.Project\DefaultIcon"; \
    ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExe},0"
Root: HKA; Subkey: "Software\Classes\ZirClock.Project\shell\open\command"; \
    ValueType: string; ValueName: ""; ValueData: """{app}\{#AppExe}"" ""%1"""
; Registra el .exe en App Paths: permite abrir la app desde Win+R o la
; búsqueda del menú Inicio escribiendo solo "zirclock".
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\{#AppExe}"; \
    ValueType: string; ValueName: ""; ValueData: "{app}\{#AppExe}"; \
    Flags: uninsdeletekey
; Renombres Zirchron -> Chronikon (v2.0) -> ZirClock (v3.0): las claves que
; registraban los nombres viejos y que ya nadie usa. Las asociaciones de
; .zirchron y .chronikon NO se tocan: arriba se re-apuntan a ZirClock.Project.
Root: HKA; Subkey: "Software\Classes\Zirchron.Project"; ValueType: none; Flags: deletekey
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\Zirchron.exe"; \
    ValueType: none; Flags: deletekey
Root: HKA; Subkey: "Software\Classes\Chronikon.Project"; ValueType: none; Flags: deletekey
Root: HKA; Subkey: "Software\Microsoft\Windows\CurrentVersion\App Paths\Chronikon.exe"; \
    ValueType: none; Flags: deletekey

[InstallDelete]
; PyInstaller (onedir) deja el runtime en _internal\. Vaciarlo ANTES de copiar
; evita que una DLL o un módulo de la versión anterior sobreviva junto a los
; nuevos (vale para toda actualización futura, no solo para el renombre).
Type: filesandordirs; Name: "{app}\_internal"
; Renombres: los ejecutables y los accesos directos de los nombres viejos.
Type: files; Name: "{app}\Zirchron.exe"
Type: files; Name: "{autoprograms}\Zirchron.lnk"
Type: files; Name: "{autodesktop}\Zirchron.lnk"
Type: files; Name: "{app}\Chronikon.exe"
Type: files; Name: "{autoprograms}\Chronikon.lnk"
Type: files; Name: "{autodesktop}\Chronikon.lnk"

[Run]
Filename: "{app}\{#AppExe}"; \
    Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; \
    Flags: nowait postinstall skipifsilent

[Code]
var
  OldDir, OldExe: String;

// Mismo AppId => Inno reusa la carpeta de la instalación anterior. Si esa
// carpeta se llama "...\Zirchron" o "...\Chronikon", ZirClock va a su hermana
// "...\ZirClock" (respeta dónde la había puesto el usuario) y la vieja se
// vacía al instalar.
procedure InitializeWizard;
var
  Dir, Name: String;
begin
  OldDir := '';
  OldExe := '';
  Dir := RemoveBackslashUnlessRoot(WizardForm.DirEdit.Text);
  Name := ExtractFileName(Dir);
  if (CompareText(Name, 'Zirchron') = 0) or
     (CompareText(Name, 'Chronikon') = 0) then
  begin
    OldDir := Dir;
    OldExe := Name + '.exe';
    WizardForm.DirEdit.Text := AddBackslash(ExtractFileDir(Dir)) + 'ZirClock';
  end;
end;

// Se borra SOLO lo que instaló el programa con su nombre viejo; RemoveDir no
// borra una carpeta con algo más dentro, así que un archivo del usuario nunca
// se pierde.
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssInstall) and (OldDir <> '') then
  begin
    DelTree(OldDir + '\_internal', True, True, True);
    DeleteFile(AddBackslash(OldDir) + OldExe);
    DeleteFile(OldDir + '\unins000.exe');
    DeleteFile(OldDir + '\unins000.dat');
    RemoveDir(OldDir);
  end;
end;
