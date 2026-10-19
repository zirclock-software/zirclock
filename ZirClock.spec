# -*- mode: python ; coding: utf-8 -*-
# Receta de PyInstaller para el ZirClock.app de macOS (§74, Ola 10).
#
# Se construye con:  ./build_mac.sh   (genera el .icns, corre PyInstaller y
# arma el .dmg). Modo onedir + BUNDLE (lo estándar para .app; onefile arranca
# lento porque desempaca en cada lanzamiento).
#
# ⚠ GEMELO DE ZirClock-win.spec (Windows). Se mantienen SEPARADOS a propósito
#   (este ya produjo los .dmg publicados y no se re-toca). El precio es que
#   `datas` y `excludes` viven en dos sitios — SI CAMBIAS UNO, CAMBIA EL OTRO.
#
# Decisiones clave:
# - datas: guide_assets/ (los screenshots del User guide §71). main.py los
#   resuelve relativo a __file__, que en el bundle apunta a la carpeta interna
#   de PyInstaller → funciona sin tocar código.
# - Info.plist: UIDesignRequiresCompatibility=YES apaga Liquid Glass — el tema
#   se validó bajo ese modo y Qt 6.11 tiene artefactos bajo glass
#   (QTBUG-138942; mismo fix que el lanzador ./zirclock de desarrollo).
# - CFBundleDocumentTypes: asocia .zirchron → doble-clic abre la app (el
#   QFileOpenEvent lo maneja _ZirClockApp en main.py).
# - Firma AD-HOC automática de PyInstaller (en Apple Silicon es obligatoria).
#   Sin notarización: Gatekeeper avisa al primer clic → clic derecho → Abrir.
# - target_arch lo inyecta build_mac.sh (§81): arm64 o x86_64. No es
#   cross-compile (PyInstaller empaqueta lo que su propio Python importa),
#   sino la instrucción de ADELGAZAR con lipo los binarios universales —el
#   wheel de PyQt6 trae las dos arquitecturas— a la que se está construyendo.
import os
import re

# Versión desde main.py (fuente única §73) SIN importarlo (importar exige Qt).
with open("main.py", encoding="utf-8") as _f:
    ZVERSION = re.search(r'^ZIRCLOCK_VERSION\s*=\s*"([^"]+)"',
                         _f.read(), re.M).group(1)

# Sin la variable (p.ej. corriendo pyinstaller a mano) → None = arquitectura
# nativa del intérprete, el comportamiento previo al §81.
_TARGET_ARCH = os.environ.get("ZIRCLOCK_TARGET_ARCH") or None

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
    upx=False,
    console=False,          # app GUI: sin ventana de terminal
    disable_windowed_traceback=False,
    argv_emulation=False,   # False: los FileOpen los maneja _ZirClockApp (§74)
    target_arch=_TARGET_ARCH,
    codesign_identity=None,  # None → firma ad-hoc automática
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    name="ZirClock",
)

app = BUNDLE(
    coll,
    name="ZirClock.app",
    icon="packaging/zirclock.icns",
    bundle_identifier="mx.zirclock.app",  # mismo id que el wrapper dev
    info_plist={
        "CFBundleName": "ZirClock",
        "CFBundleDisplayName": "ZirClock",
        "CFBundleShortVersionString": ZVERSION,
        "CFBundleVersion": ZVERSION,
        "NSHighResolutionCapable": True,
        # Piso REAL del bundle = el mayor `minos` de todos sus binarios.
        # Medido con otool (§89, no supuesto): Qt 6.11 pide 13.0, pero los
        # wheels de numpy 2.5 y scipy 1.18 son macosx_14_0 → el piso es 14.
        # Declararlo hace que macOS avise "requiere macOS 14 o posterior" en
        # vez de dejar que la app truene con un error críptico.
        # Al subir cualquier dependencia, re-medirlo:
        #   otool -l <binario> | grep -A4 LC_BUILD_VERSION | grep minos
        # §98: lo fija build_mac.sh POR ARQUITECTURA — Apple Silicon 14.0
        # (ruedas Accelerate), Intel 13.0 (ruedas OpenBLAS, para Ventura) —
        # y el propio build_mac.sh VERIFICA que ningún binario pida más.
        "LSMinimumSystemVersion": os.environ.get("ZIRCLOCK_MIN_MACOS") or "14.0",
        # Liquid Glass OFF — entorno donde se validó el tema (§31/§1).
        "UIDesignRequiresCompatibility": True,
        # Sin afiliación (2026-09-17); licencia GPL desde la 3.0 (2026-10-19).
        "NSHumanReadableCopyright": "Copyright (C) 2026 Guillermo Espejo Bautista. GPL-3.0-or-later",
        # Doble-clic en un proyecto abre la app (§74).
        # TRES tipos a propósito: la extensión nueva y las dos heredadas. El
        # programa se llamó "Zirchron" hasta la v1.3 y "Chronikon" de la 2.0 a
        # la 2.3, y sus proyectos siguen en disco; sin esas entradas, el
        # doble-clic dejaría de abrirlos.
        #
        # Ícono de los documentos (§125). Sin declarar el TIPO, macOS le pone
        # a cada .zirclock un identificador provisional ("dyn.…") y Finder
        # dibuja una hoja en blanco. Declarado aquí (UTExportedTypeDeclarations)
        # y con UTTypeIcons, el sistema compone el ícono él solo: la hoja con
        # el ícono de la app encima y el rótulo abajo — como Keynote. Probado
        # en macOS 27 con una app de prueba: solo "UTTypeIconText" basta; el
        # dibujo de la app lo pone macOS sin nombrarlo.
        "UTExportedTypeDeclarations": [{
            "UTTypeIdentifier": "mx.zirclock.project",
            "UTTypeDescription": "ZirClock project",
            "UTTypeConformsTo": ["public.data", "public.content"],
            "UTTypeIcons": {"UTTypeIconText": "ZIRCLOCK"},
            "UTTypeTagSpecification": {
                "public.filename-extension": ["zirclock"]},
        }, {
            "UTTypeIdentifier": "mx.zirclock.project-chronikon",
            "UTTypeDescription": "ZirClock project (legacy)",
            "UTTypeConformsTo": ["public.data", "public.content"],
            "UTTypeIcons": {"UTTypeIconText": "ZIRCLOCK"},
            "UTTypeTagSpecification": {
                "public.filename-extension": ["chronikon"]},
        }, {
            "UTTypeIdentifier": "mx.zirclock.project-zirchron",
            "UTTypeDescription": "ZirClock project (legacy)",
            "UTTypeConformsTo": ["public.data", "public.content"],
            "UTTypeIcons": {"UTTypeIconText": "ZIRCLOCK"},
            "UTTypeTagSpecification": {
                "public.filename-extension": ["zirchron"]},
        }],
        # LSItemContentTypes enlaza cada documento con su tipo declarado; las
        # extensiones se quedan como respaldo (y las lee verify_dmg.sh).
        "CFBundleDocumentTypes": [{
            "CFBundleTypeName": "ZirClock project",
            "LSItemContentTypes": ["mx.zirclock.project"],
            "CFBundleTypeExtensions": ["zirclock"],
            "CFBundleTypeRole": "Editor",
            "LSHandlerRank": "Owner",
            "CFBundleTypeIconSystemGenerated": 1,
        }, {
            "CFBundleTypeName": "ZirClock project (legacy)",
            "LSItemContentTypes": ["mx.zirclock.project-chronikon"],
            "CFBundleTypeExtensions": ["chronikon"],
            "CFBundleTypeRole": "Editor",
            "LSHandlerRank": "Owner",
            "CFBundleTypeIconSystemGenerated": 1,
        }, {
            "CFBundleTypeName": "ZirClock project (legacy)",
            "LSItemContentTypes": ["mx.zirclock.project-zirchron"],
            "CFBundleTypeExtensions": ["zirchron"],
            "CFBundleTypeRole": "Editor",
            "LSHandlerRank": "Owner",
            "CFBundleTypeIconSystemGenerated": 1,
        }],
    },
)
