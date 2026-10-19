"""Revisa el contenido Python de un ZirClock empaquetado (lo llama verify_dmg.sh).

    .venv/bin/python packaging/verify_pyz.py <ruta al ejecutable del .app>

Comprueba sobre el ARTEFACTO (§84) que:
  · el PYZ trae los backends vectoriales de matplotlib — se cargan por nombre y
    PyInstaller los dejaba fuera: sin ellos no hay export PDF/SVG ni compositor;
  · el `main` marshalizado lleva la versión de `main.py` (un .dmg viejo con el
    nombre nuevo es justo el error que la regla "una versión = un commit" evita).
"""
import marshal
import os
import re
import sys
import tempfile

from PyInstaller.archive.readers import CArchiveReader, ZlibArchiveReader

exe = sys.argv[1]
arch = CArchiveReader(exe)
with tempfile.NamedTemporaryFile(suffix=".pyz", delete=False) as tmp:
    tmp.write(arch.extract("PYZ.pyz"))
    pyz = tmp.name
try:
    toc = set(ZlibArchiveReader(pyz).toc)
finally:
    os.unlink(pyz)

for mod in ("matplotlib.backends.backend_pdf", "matplotlib.backends.backend_svg",
            "matplotlib.backends.backend_ps"):
    print(f"  {'✓' if mod in toc else '✗'} {mod}")

code = None
for name in arch.toc:
    if name == "main":
        code = marshal.loads(arch.extract(name))
        break


def _strings(c, acc):
    for k in c.co_consts:
        if isinstance(k, str):
            acc.add(k)
        elif hasattr(k, "co_code"):
            _strings(k, acc)
    return acc


root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = open(os.path.join(root, "main.py"), encoding="utf-8").read()
want = re.search(r'^ZIRCLOCK_VERSION\s*=\s*"([^"]+)"', src, re.M).group(1)
if code is None:
    print("  ✗ no se encontró el script principal en el archivo")
else:
    ok = want in _strings(code, set())
    print(f"  {'✓' if ok else '✗'} la versión {want} de main.py va dentro del ejecutable")
