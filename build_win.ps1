<#
Construye el ZirClock.exe + instalador de Windows (Ola 10, mitad Win).
Gemelo de build_mac.sh.

Uso:  .\build_win.ps1              -> app + instalador
      .\build_win.ps1 -SkipSetup   -> solo la app (sin Inno Setup)

Salida:  dist\ZirClock\ZirClock.exe            (la app, modo onedir)
         dist\ZirClock-<version>-windows-setup.exe   (el instalador)

No hay cross-compile: PyInstaller empaqueta lo que su PROPIO intérprete puede
importar, así que el .exe se construye SIEMPRE en una máquina Windows (por eso
esta mitad de la Ola 10 esperó al regreso a la All-in-one). Lo mismo aplica al
revés: el .dmg exige una Mac.

A diferencia del build de Mac aquí NO hay firma de código: Windows no la exige
para ejecutar. El costo es SmartScreen, que al primer arranque en otra
computadora avisa "Windows protegió su PC" -> Más información -> Ejecutar de
todas formas. Es el equivalente del rodeo de Gatekeeper y se documenta igual
en INSTALL.md. Firmarlo requeriría un certificado de firma de código de pago.
#>
param([switch]$SkipSetup)

$ErrorActionPreference = "Stop"
$DIR = $PSScriptRoot
Set-Location $DIR

<#
Ejecuta un programa EXTERNO y falla solo si su codigo de salida no es 0.

Por que hace falta: en Windows PowerShell 5.1, con $ErrorActionPreference =
"Stop" cualquier linea que un .exe escriba a STDERR se convierte en un error
TERMINANTE y aborta el script -- aunque el programa termine bien. PyInstaller
manda todos sus mensajes INFO por stderr, asi que el build moria en el primer
"INFO: PyInstaller: 6.21.0". El unico veredicto valido de un programa externo
es su codigo de salida, que es lo que se revisa aqui.
(PowerShell 7 lo arreglo con PSNativeCommandUseErrorActionPreference; 5.1 no.)
#>
function Invoke-Native {
    param([Parameter(Mandatory)][scriptblock]$Cmd,
          [Parameter(Mandatory)][string]$What)
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { & $Cmd } finally { $ErrorActionPreference = $prev }
    if ($LASTEXITCODE -ne 0) { throw "$What (codigo de salida $LASTEXITCODE)" }
}

if (-not $IsWindows -and $env:OS -ne "Windows_NT") {
    throw "Este build es solo para Windows."
}

# --- intérprete del venv ----------------------------------------------------
$PY = Join-Path $DIR ".venv\Scripts\python.exe"
if (-not (Test-Path $PY)) {
    throw "No encuentro $PY - crea el venv primero: python -m venv .venv; .venv\Scripts\python.exe -m pip install -r requirements.txt"
}

# --- versión, desde main.py (fuente única, igual que los .spec) -------------
$VER = Invoke-Native { & $PY -c "import re; print(re.search(r'^ZIRCLOCK_VERSION\s*=\s*\`"([^\`"]+)\`"', open('main.py', encoding='utf-8').read(), re.M).group(1))" } "No pude leer ZIRCLOCK_VERSION de main.py"
if (-not $VER) { throw "ZIRCLOCK_VERSION salio vacia" }
Write-Host "-> ZirClock $VER - Windows x64"

# --- [1/3] ícono ------------------------------------------------------------
Write-Host "-> [1/3] Icono .ico (desde el dibujo en codigo)"
Invoke-Native { & $PY packaging\make_ico.py } "Fallo la generacion del .ico"

# --- [2/3] PyInstaller ------------------------------------------------------
Write-Host "-> [2/3] PyInstaller (onedir)"
Invoke-Native { & $PY -m PyInstaller --noconfirm --clean ZirClock-win.spec } "Fallo PyInstaller"

$APPEXE = Join-Path $DIR "dist\ZirClock\ZirClock.exe"
if (-not (Test-Path $APPEXE)) { throw "PyInstaller no dejo $APPEXE" }

if ($SkipSetup) {
    Write-Host ""
    Write-Host "Listo (solo app): dist\ZirClock\ZirClock.exe"
    exit 0
}

# --- [3/3] instalador -------------------------------------------------------
# winget instala Inno Setup por usuario (LOCALAPPDATA) o para todos (Program
# Files) segun los permisos, asi que se buscan las tres rutas.
Write-Host "-> [3/3] Instalador (Inno Setup)"
$ISCC = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $ISCC) {
    throw "No encuentro ISCC.exe - instala Inno Setup:  winget install -e --id JRSoftware.InnoSetup"
}

Invoke-Native { & $ISCC "/DZVERSION=$VER" "packaging\zirclock.iss" } "Fallo Inno Setup"

Write-Host ""
Write-Host "Listo:"
Write-Host "  dist\ZirClock\ZirClock.exe"
Write-Host "  dist\ZirClock-$VER-windows-setup.exe"
Write-Host ""
Write-Host "Nota SmartScreen (sin firma de codigo): al primer arranque en otra"
Write-Host "computadora, Mas informacion -> Ejecutar de todas formas."
