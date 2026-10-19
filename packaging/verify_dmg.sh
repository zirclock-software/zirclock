#!/bin/zsh
# Revisa un .dmg de ZirClock YA CONSTRUIDO — el artefacto, no el código (§84).
#
#   packaging/verify_dmg.sh dist/ZirClock-2.1-arm64.dmg
#   packaging/verify_dmg.sh dist/ZirClock-2.1-intel.dmg
#
# Lo monta en solo lectura y comprueba: firma, plist (nombre, bundle id,
# versión, piso de macOS, Liquid Glass apagado, extensiones), que TODOS los
# binarios sean de la arquitectura del .dmg, el `minos` de cada uno (§89: dyld
# no carga una dylib que pida un macOS más nuevo que el del usuario), los
# guide_assets, y —vía verify_pyz.py— los backends vectoriales (§84) y la
# versión dentro del `main` marshalizado. Nació el 2026-09-27 (§117); antes
# estas revisiones se tecleaban a mano en cada build.
set -u
DMG="$1"
ROOT="${0:A:h:h}"
case "$DMG" in
  *intel*) ARCH=x86_64 ;;
  *)       ARCH=arm64 ;;
esac
MNT=$(mktemp -d /tmp/zirclock-verify.XXXX)
if ! hdiutil attach -nobrowse -readonly -mountpoint "$MNT" "$DMG" >/dev/null 2>&1; then
  echo "✗ no se pudo montar $DMG"; exit 1
fi
trap 'hdiutil detach "$MNT" >/dev/null 2>&1; rmdir "$MNT" 2>/dev/null' EXIT
APP="$MNT/ZirClock.app"
SHA=$(shasum -a 256 "$DMG" | cut -d' ' -f1)
echo "== $(basename "$DMG")  ($(du -h "$DMG" | cut -f1))  sha256 ${SHA:0:8}…${SHA: -4}"

codesign --verify --deep --strict "$APP" && echo "  ✓ firma" || echo "  ✗ FIRMA"
P="$APP/Contents/Info.plist"
for k in CFBundleName CFBundleIdentifier CFBundleShortVersionString \
         LSMinimumSystemVersion UIDesignRequiresCompatibility; do
  echo "  $k = $(/usr/libexec/PlistBuddy -c "Print :$k" "$P" 2>/dev/null)"
done
echo "  extensiones: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleDocumentTypes' "$P" \
  | awk '/CFBundleTypeExtensions/{f=1;next} f&&/\}/{f=0} f&&!/Array|\{/{printf $1" "}')"
# §125: sin tipo declarado + UTTypeIcons, Finder dibuja una hoja en blanco.
NIC=$(/usr/libexec/PlistBuddy -c 'Print :UTExportedTypeDeclarations' "$P" 2>/dev/null \
  | grep -c UTTypeIconText)
[[ $NIC -ge 3 ]] && echo "  ✓ ícono de documento (.zirclock, .chronikon y .zirchron)" \
                 || echo "  ✗ SIN ícono de documento ($NIC de 3 tipos)"

n=0; foreign=0
while IFS= read -r f; do
  n=$((n+1))
  [[ "$(lipo -archs "$f" 2>/dev/null)" != "$ARCH" ]] && foreign=$((foreign+1))
done < <(find "$APP" -type f \( -name "*.so" -o -name "*.dylib" \))
[[ $foreign -eq 0 ]] && echo "  ✓ $n binarios, todos $ARCH" \
                     || echo "  ✗ $foreign de $n binarios NO son $ARCH"

MIN=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$P")
echo "  minos (binarios por versión):"
find "$APP" -type f \( -name "*.so" -o -name "*.dylib" -o -perm +111 \) -print0 \
  | xargs -0 -n1 sh -c 'otool -l "$0" 2>/dev/null | awk "/LC_BUILD_VERSION/{f=1} f&&/minos/{print \$2; f=0}"' \
  | sort | uniq -c | sort -k2 -V | sed 's/^/     /'
TOP=$(find "$APP" -type f \( -name "*.so" -o -name "*.dylib" -o -perm +111 \) -print0 \
  | xargs -0 -n1 sh -c 'otool -l "$0" 2>/dev/null | awk "/LC_BUILD_VERSION/{f=1} f&&/minos/{print \$2; f=0}"' \
  | sort -V | tail -1)
[[ "$(printf '%s\n%s\n' "$TOP" "$MIN" | sort -V | tail -1)" == "$MIN" ]] \
  && echo "  ✓ ningún binario pide más que macOS $MIN" \
  || echo "  ✗ hay binarios que piden macOS $TOP (declarado $MIN)"

echo "  guide_assets: $(find "$APP" -path '*guide_assets*' -name '*.png' | wc -l | tr -d ' ') PNG"
"$ROOT/.venv/bin/python" "$ROOT/packaging/verify_pyz.py" "$APP/Contents/MacOS/ZirClock"
