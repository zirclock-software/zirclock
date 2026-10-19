#!/bin/zsh
# Crea el toolchain de build de macOS para ./build_mac.sh   (§81, §89).
#
# Uso:  ./packaging/setup_build_venv.sh --arm64     (Apple Silicon)
#       ./packaging/setup_build_venv.sh --intel     (x86_64, bajo Rosetta)
#
# ¿Por qué existe? Dos razones, una por arquitectura:
#
#  • INTEL (§81): PyInstaller no hace cross-compile, así que para producir un
#    ZirClock.app de Intel hace falta un venv x86_64 COMPLETO (con sus wheels
#    Intel de numpy/scipy/PyQt6…), que en una Mac con chip M corre bajo Rosetta.
#
#  • ARM64 (§89, el crash de Luigi en Sequoia): el Python de HOMEBREW se compila
#    para el macOS de la máquina que lo instala. En la MacBook (macOS 26) sus
#    binarios salen con `minos 26.0`, y dyld se NIEGA a cargar una dylib que
#    exige un macOS más nuevo que el que corre → la app moría al arrancar en
#    cualquier Mac con Sequoia (15.x): el ícono rebotaba y nada más. Medido:
#    57 binarios del bundle arm64 exigían macOS 26. Con este intérprete
#    standalone bajan a 11-13 y el piso vuelve a ser el de los wheels.
#    Comprobación rápida sobre cualquier build:
#        otool -l <binario> | grep -A4 LC_BUILD_VERSION | grep minos
#
# Dónde vive y por qué AHÍ: ~/.zirchron-build/, fuera de ~/Documents. El File
# Provider de iCloud re-estampa com.apple.FinderInfo en los .framework y
# codesign se niega a firmar con ese "detritus" (gotcha §74) — un venv Intel
# dentro del proyecto envenenaría cada build.
#
# El intérprete es un CPython "standalone" de python-build-standalone (el
# mismo que usan uv y Rye): es relocalizable, no toca el sistema y no pide
# contraseña. Se verifica su SHA256 contra el SHA256SUMS de la release.
set -e

# Versión del intérprete: debe COINCIDIR con la del venv arm64 del proyecto,
# para que los dos builds salgan del mismo Python (mismas versiones de wheels,
# mismo comportamiento). Si actualizas uno, actualiza el otro.
PY_VERSION="3.14.6"
PY_RELEASE="20260718"

DIR="${0:A:h:h}"          # raíz del proyecto (este script vive en packaging/)
ROOT="$HOME/.zirchron-build"
BASE="https://github.com/astral-sh/python-build-standalone/releases/download/$PY_RELEASE"

# --- arquitectura objetivo -------------------------------------------------
case "${1:---intel}" in
    --intel|--x86_64) TARGET="x86_64";  TRIPLE="x86_64-apple-darwin";  LABEL="intel" ;;
    --arm64|--arm)    TARGET="arm64";   TRIPLE="aarch64-apple-darwin"; LABEL="arm64" ;;
    *) echo "Uso: ./packaging/setup_build_venv.sh [--arm64|--intel]" >&2; exit 1 ;;
esac
PYDIR="$ROOT/python-$TARGET"
VENV="$ROOT/venv-$LABEL"
ASSET="cpython-$PY_VERSION+$PY_RELEASE-$TRIPLE-install_only.tar.gz"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "Solo para macOS." >&2
    exit 1
fi
# El Python Intel corre nativo en una Mac Intel; en una con chip M pide Rosetta.
if [[ "$TARGET" == "x86_64" && "$(uname -m)" == "arm64" ]] \
   && ! /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
    echo "Falta Rosetta 2 (necesaria para correr el Python Intel)." >&2
    echo "Instálala con:  softwareupdate --install-rosetta" >&2
    exit 1
fi
if [[ "$TARGET" == "arm64" && "$(uname -m)" != "arm64" ]]; then
    echo "El venv arm64 hay que crearlo en una Mac con chip M." >&2
    exit 1
fi

mkdir -p "$ROOT"

if [[ -x "$PYDIR/bin/python3" ]]; then
    echo "→ [1/3] Python $TARGET ya presente en $PYDIR"
else
    echo "→ [1/3] Descargando CPython $PY_VERSION $TARGET (~26 MB)"
    TMP="$(mktemp -d /tmp/zirchron-py.XXXXXX)"
    trap "rm -rf '$TMP'" EXIT
    # --data-urlencode no: el '+' del nombre debe ir como %2B en la URL.
    curl -fsSL -o "$TMP/py.tar.gz" "$BASE/${ASSET//+/%2B}"
    curl -fsSL -o "$TMP/SHA256SUMS" "$BASE/SHA256SUMS"

    EXPECT=$(grep -F " $ASSET" "$TMP/SHA256SUMS" | cut -d' ' -f1)
    LOCAL=$(shasum -a 256 "$TMP/py.tar.gz" | cut -d' ' -f1)
    if [[ -z "$EXPECT" || "$EXPECT" != "$LOCAL" ]]; then
        echo "❌ SHA256 no coincide (esperado '$EXPECT', local '$LOCAL')." >&2
        exit 1
    fi
    echo "   SHA256 verificado"
    rm -rf "$PYDIR"
    tar xzf "$TMP/py.tar.gz" -C "$TMP"
    mv "$TMP/python" "$PYDIR"
fi

PYARCH=$("$PYDIR/bin/python3" -c "import platform; print(platform.machine())")
if [[ "$PYARCH" != "$TARGET" ]]; then
    echo "❌ El intérprete descargado dice ser $PYARCH, no $TARGET." >&2
    exit 1
fi

echo "→ [2/3] venv $LABEL en $VENV"
rm -rf "$VENV"
"$PYDIR/bin/python3" -m venv "$VENV"
"$VENV/bin/python" -m pip install -q --upgrade pip

echo "→ [3/3] Dependencias (wheels $TARGET) desde requirements.txt"
"$VENV/bin/python" -m pip install -q -r "$DIR/requirements.txt"

# §98 — Intel: numpy y scipy publican DOS ruedas para Mac x86_64 de la MISMA
# versión: `macosx_14_0` (usa Accelerate de Apple, exige Sonoma) y
# `macosx_10_15` (usa OpenBLAS). En cualquier Mac moderna pip elige la
# primera, y con ella el .app no abre en Ventura — justo las Macs Intel de
# Carlos (iMac 2017, que Apple no deja pasar de Ventura). Se cambian por las
# de 10.15, misma versión: el piso del .app baja a 13.0 (el de Qt 6.11).
if [[ "$LABEL" == "intel" ]]; then
    echo "→ [3b] numpy/scipy en su variante para macOS 13 (OpenBLAS)"
    read -r NPV SPV PYV < <("$VENV/bin/python" -c "import sys, numpy, scipy; \
print(numpy.__version__, scipy.__version__, \
f'{sys.version_info[0]}.{sys.version_info[1]}')")
    WH="$(mktemp -d /tmp/zirclock-wheels.XXXXXX)"
    "$VENV/bin/python" -m pip download -q --no-deps --only-binary=:all: \
        --platform macosx_13_0_x86_64 --python-version "$PYV" \
        --implementation cp "numpy==$NPV" "scipy==$SPV" -d "$WH"
    "$VENV/bin/python" -m pip install -q --force-reinstall --no-deps "$WH"/*.whl
    rm -rf "$WH"
fi

echo ""
"$VENV/bin/python" - <<'EOF'
import platform, sys
import numpy, scipy, matplotlib, PyInstaller
from PyQt6.QtCore import QT_VERSION_STR
print(f"Listo: Python {sys.version.split()[0]} {platform.machine()} | "
      f"numpy {numpy.__version__} · scipy {scipy.__version__} · "
      f"matplotlib {matplotlib.__version__} · Qt {QT_VERSION_STR} · "
      f"PyInstaller {PyInstaller.__version__}")
EOF
echo ""
echo "Ahora ya puedes construir el .app con:"
if [[ "$LABEL" == "intel" ]]; then
    echo "  ./build_mac.sh --intel"
else
    echo "  ./build_mac.sh"
fi
echo ""
echo "Piso de macOS del toolchain (lo que exigirá el .app):"
# §98: otool se llama desde ESTE shell (nativo) y no desde el Python: el de
# Intel corre bajo Rosetta y en macOS 27 `otool` es un shim de xcrun que ya no
# carga ahí (mismo problema que lipo en build_mac.sh) → salía "minos ?".
_PYBIN="$("$PYDIR/bin/python3" -c 'import os, sys; print(os.path.realpath(sys.executable))')"
_MINOS=$(otool -l "$_PYBIN" 2>/dev/null | awk '/LC_BUILD_VERSION/{f=1} f&&/minos/{print $2; exit}')
echo "   interprete: minos ${_MINOS:-?}"
