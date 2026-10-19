#!/bin/zsh
# Construye el ZirClock.app + .dmg de macOS (§74 Ola 10; Intel en §81).
#
# Uso:  ./build_mac.sh            → Apple Silicon (arm64), venv del proyecto
#       ./build_mac.sh --intel    → Intel (x86_64) bajo Rosetta, venv aparte
#
# Salida:  dist/<arm64|intel>/ZirClock.app
#          dist/ZirClock-<versión>-<arm64|intel>.dmg
#
# ¿Por qué un build Intel? Los revisores del LEI trabajan en Macs Intel
# (iMac 27" 2017 y anteriores). PyInstaller NO hace cross-compile: empaqueta
# lo que su PROPIO intérprete puede importar, así que el build x86_64 exige
# un venv x86_64 completo, que corre bajo Rosetta en las Mac con chip M.
# Se crea con  ./packaging/setup_build_venv.sh --intel  y vive en ~/.zirchron-build/,
# FUERA de ~/Documents — ver el gotcha de iCloud aquí abajo.
#
# ⚠ GOTCHA iCloud (cazado 2026-07-24): este proyecto vive en ~/Documents,
# que está bajo el File Provider de iCloud. fileproviderd RE-ESTAMPA
# com.apple.FinderInfo en los directorios .framework en milisegundos
# (borrar con xattr -d no sirve: reaparece al instante) y codesign se niega
# a FIRMAR con ese "detritus". Por eso TODO el build + firma + dmg ocurre
# en un directorio temporal FUERA del árbol de iCloud, y al final solo se
# copian los artefactos de vuelta a dist/. El .dmg es inmune para siempre
# (imagen de solo lectura); el .app copiado funciona porque los xattrs
# añadidos DESPUÉS de firmar no invalidan la firma (el check de detritus
# es solo al crearla). Por lo mismo el venv Intel NO puede vivir dentro del
# proyecto: sería una fuente permanente de detritus en cada build.
#
# Requiere el venv correspondiente con pyinstaller (está en requirements.txt).
# El .exe de Windows se construye APARTE en la All-in-one (no hay
# cross-compile) — ver §6 Ola 10.
set -e

DIR="${0:A:h}"
cd "$DIR"

# --- arquitectura objetivo -------------------------------------------------
# ⚠ §89: los DOS builds usan el venv de ~/.zirchron-build, no el .venv del
# proyecto. El Python de Homebrew se compila para el macOS de la máquina que lo
# instaló: en esta MacBook (macOS 26) sus binarios salen con `minos 26.0`, dyld
# se niega a cargar una dylib que exige un macOS más nuevo que el que corre, y
# el .app moría al arrancar en cualquier Sequoia (el ícono rebota y ya) — así
# le pasó a Luigi el 2026-09-03. El intérprete standalone declara minos 11.
ARCH="arm64"; LABEL="arm64"; VENV="$HOME/.zirchron-build/venv-arm64"
MIN_MACOS="14.0"      # §98: piso declarado; el guardia de abajo lo verifica
if [[ "$1" == "--intel" || "$1" == "--x86_64" ]]; then
    ARCH="x86_64"; LABEL="intel"; VENV="$HOME/.zirchron-build/venv-intel"
    MIN_MACOS="13.0"  # Ventura: ruedas OpenBLAS de numpy/scipy (setup_build_venv.sh)
    # ⚠ macOS 27 (Command Line Tools 27.0, 2026-09): el Python x86_64 corre
    # bajo Rosetta, y /usr/bin/lipo e install_name_tool son "shims" de xcrun que
    # cargan libxcrun.dylib para la arquitectura del proceso — y las CLT 27 ya
    # NO traen su versión x86_64 → PyInstaller moría en "lipo -thin x86_64".
    # Las herramientas REALES viven en las CLT y son arm64: un proceso bajo
    # Rosetta sí puede lanzarlas (corren nativas). Se ponen primero en el PATH.
    # Es el riesgo con fecha del §6 ("Rosetta se retira"): cuando Apple quite
    # Rosetta del todo, el .dmg Intel exigirá una Mac Intel o CI.
    CLT_BIN="$(xcode-select -p 2>/dev/null)/usr/bin"
    [[ -x "$CLT_BIN/lipo" ]] || CLT_BIN="/Library/Developer/CommandLineTools/usr/bin"
    export PATH="$CLT_BIN:$PATH"
elif [[ -n "$1" ]]; then
    echo "Uso: ./build_mac.sh [--intel]" >&2
    exit 1
fi
PY="$VENV/bin/python"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Este build es solo para macOS." >&2
    exit 1
fi
if [[ ! -x "$PY" ]]; then
    echo "No encuentro el venv de $LABEL en $VENV" >&2
    echo "Créalo con:  ./packaging/setup_build_venv.sh --$LABEL" >&2
    exit 1
fi

# El intérprete DEBE ser de la arquitectura que vamos a construir (ver arriba:
# PyInstaller no cross-compila). Si no cuadra, el .app saldría de la
# arquitectura equivocada sin ningún aviso.
PYARCH=$("$PY" -c "import platform; print(platform.machine())")
if [[ "$PYARCH" != "$ARCH" ]]; then
    echo "El venv $VENV es $PYARCH pero se pidió $ARCH." >&2
    exit 1
fi

VER=$("$PY" -c "import re; print(re.search(r'^ZIRCLOCK_VERSION\s*=\s*\"([^\"]+)\"', open('main.py', encoding='utf-8').read(), re.M).group(1))")
BROOT="$(mktemp -d /tmp/zirchron-build.XXXXXX)"
trap "rm -rf '$BROOT'" EXIT

# Lo lee ZirClock.spec: hace que PyInstaller ADELGACE con lipo los binarios
# universales (el wheel de PyQt6 trae arm64 + x86_64) a la arquitectura
# objetivo — app más chica y sin slices muertas.
export ZIRCLOCK_TARGET_ARCH="$ARCH"
export ZIRCLOCK_MIN_MACOS="$MIN_MACOS"

echo "→ ZirClock $VER — arquitectura $ARCH ($LABEL)"

echo "→ [1/4] Ícono .icns (desde el dibujo en código)"
"$PY" packaging/make_icns.py

echo "→ [2/4] PyInstaller (onedir + bundle, en $BROOT)"
"$PY" -m PyInstaller --noconfirm --clean \
    --workpath "$BROOT/build" --distpath "$BROOT/dist" ZirClock.spec

APP="$BROOT/dist/ZirClock.app"

echo "→ [3/4] Firma ad-hoc (verificada)"
# Fuera de iCloud el bundle nace limpio; -cr por si el venv aportó basura.
xattr -cr "$APP" 2>/dev/null || true
codesign -s - --force --deep "$APP"
codesign --verify --deep --strict "$APP"
echo "   firma OK"

# §98 — GUARDIA del piso de macOS (la lección del §89, automatizada): un .app
# de PyInstaller hereda el `minos` de CADA binario que empaqueta, no el que
# declara el plist. Si alguno exige un macOS más nuevo que MIN_MACOS, el .app
# moriría sin aviso en esos sistemas → mejor no fabricar el .dmg.
MAXMIN=$(find "$APP" -type f \( -name '*.so' -o -name '*.dylib' -o -perm +111 \) \
    -exec otool -l {} \; 2>/dev/null \
    | awk '/LC_BUILD_VERSION/{f=1} f&&/minos/{print $2; f=0}' | sort -V | tail -1)
if [[ "$(printf '%s\n%s\n' "$MAXMIN" "$MIN_MACOS" | sort -V | tail -1)" != "$MIN_MACOS" ]]; then
    echo "❌ Algún binario pide macOS $MAXMIN y el .app declara $MIN_MACOS." >&2
    echo "   Míralo con: otool -l <binario> | grep -A4 LC_BUILD_VERSION" >&2
    exit 1
fi
echo "   piso de macOS: declarado $MIN_MACOS · el binario más exigente pide $MAXMIN"

echo "→ [4/4] .dmg"
STAGE="$BROOT/stage"
mkdir "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"   # arrastrar-a-Aplicaciones clásico
hdiutil create -volname "ZirClock $VER" -srcfolder "$STAGE" -ov \
    -format UDZO "$BROOT/ZirClock-$VER-$LABEL.dmg"

# Traer los artefactos de vuelta al proyecto (dist/ es solo un contenedor:
# el .app ya está firmado y el .dmg es inmutable). La limpieza es POR
# ARQUITECTURA: un `rm -rf dist` borraría el build de la otra.
OUT="$DIR/dist/$LABEL"
rm -rf "$OUT"
mkdir -p "$OUT"
cp -R "$APP" "$OUT/"
rm -f "$DIR/dist/ZirClock-$VER-$LABEL.dmg"
cp "$BROOT/ZirClock-$VER-$LABEL.dmg" "$DIR/dist/"

echo ""
echo "Listo ($ARCH):"
echo "  dist/$LABEL/ZirClock.app"
echo "  dist/ZirClock-$VER-$LABEL.dmg"
echo ""
echo "Nota Gatekeeper (sin notarización): al primer arranque en otra Mac,"
echo "System Settings ▸ Privacy & Security ▸ \"Open Anyway\" (una sola vez)."
echo "El viejo clic derecho → Abrir ya no basta desde macOS 15 (§75)."
