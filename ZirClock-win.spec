# -*- mode: python ; coding: utf-8 -*-
# Receta de PyInstaller para el ZirClock.exe de Windows (Ola 10, mitad Win).
#
# Se construye con:  .\build_win.ps1   (genera el .ico, corre PyInstaller y
# arma el instalador con Inno Setup). Modo onedir (igual que el .app de Mac:
# onefile arranca lento porque desempaca en %TEMP% en CADA lanzamiento).
#
# ⚠ GEMELO DE ZirClock.spec (macOS). Se mantienen SEPARADOS a propósito: ese
#   spec ya produjo los .dmg publicados y no se re-toca (regla §2.7). El
#   precio es que `datas` y `excludes` viven en dos sitios —
#   SI CAMBIAS UNO, CAMBIA EL OTRO.
#
# Diferencias con el de macOS:
# - Sin BUNDLE/Info.plist (son cosas de .app). El equivalente de Windows —
#   accesos directos, asociación de .zirchron, desinstalador — lo hace el
#   INSTALADOR (packaging/zirclock.iss), no el empaquetado.
# - icon: .ico multi-resolución en vez de .icns (packaging/make_ico.py).
# - version: metadatos VERSIONINFO que Windows muestra en Propiedades del
#   archivo. Se construyen desde ZIRCLOCK_VERSION (misma fuente única que el
#   spec de Mac) para que no puedan divergir del número de la app.
# - Sin target_arch: en Windows los wheels no son universales, cada uno trae
#   una sola arquitectura, así que no hay nada que adelgazar con lipo.
import re

from PyInstaller.utils.win32.versioninfo import (
    FixedFileInfo, StringFileInfo, StringStruct, StringTable, VarFileInfo,
    VarStruct, VSVersionInfo,
)

# Versión desde main.py (fuente única §73) SIN importarlo (importar exige Qt).
with open("main.py", encoding="utf-8") as _f:
    ZVERSION = re.search(r'^ZIRCLOCK_VERSION\s*=\s*"([^"]+)"',
                         _f.read(), re.M).group(1)

# VERSIONINFO exige exactamente 4 enteros; "1.0" → (1, 0, 0, 0).
_parts = [int(x) for x in ZVERSION.split(".")]
_VTUPLE = tuple((_parts + [0, 0, 0, 0])[:4])

_version_info = VSVersionInfo(
    ffi=FixedFileInfo(filevers=_VTUPLE, prodvers=_VTUPLE),
    kids=[
        StringFileInfo([StringTable("040904B0", [  # inglés (EE. UU.), Unicode
            StringStruct("CompanyName", "Guillermo Espejo Bautista"),
            StringStruct("FileDescription", "ZirClock — zircon petrochronology"),
            StringStruct("FileVersion", ZVERSION),
            StringStruct("InternalName", "ZirClock"),
            StringStruct("LegalCopyright", "Copyright (C) 2026 Guillermo Espejo Bautista. GPL-3.0-or-later"),
            StringStruct("OriginalFilename", "ZirClock.exe"),
            StringStruct("ProductName", "ZirClock"),
            StringStruct("ProductVersion", ZVERSION),
        ])]),
        VarFileInfo([VarStruct("Translation", [0x0409, 1200])]),
    ],
)

a = Analysis(
    ["main.py"],
    pathex=[],
    binaries=[],
    datas=[("guide_assets", "guide_assets")],
    hiddenimports=[
        # §84: matplotlib carga los backends por NOMBRE según la extensión de
        # savefig, así que PyInstaller no los ve al analizar el bytecode y los
        # dejaba FUERA: el .app/.exe publicado solo exportaba PNG y el
        # compositor no podía pintar un panel (usa savefig(format="pdf")).
        # main.py también los importa explícitamente (doble red).
        "matplotlib.backends.backend_pdf",
        "matplotlib.backends.backend_svg",
        "matplotlib.backends.backend_ps",   # .ps y .eps
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    # tkinter se cuela por matplotlib y no se usa (backend qtagg explícito).
    excludes=["tkinter"],
    noarchive=False,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="ZirClock",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,          # UPX comprime, pero los antivirus lo tratan como
                        # sospechoso — no vale la pena por unos MB
    console=False,      # app GUI: sin ventana de terminal detrás
    disable_windowed_traceback=False,  # un crash muestra el traceback en un
                                       # diálogo en vez de morir en silencio
    icon="packaging/zirclock.ico",
    version=_version_info,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    name="ZirClock",
)
