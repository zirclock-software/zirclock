#!/usr/bin/env python
"""Genera packaging/zirclock.icns desde el ícono dibujado EN CÓDIGO (§74).

El ícono de ZirClock no vive en un archivo de imagen: lo dibuja
_draw_app_icon_pixmap() en main.py (motivo de cristal de zircón, azul de la
marca). Este script lo renderiza a los 10 tamaños del iconset de macOS
(16–1024, pares @2x) y lo compila con `iconutil` (herramienta nativa).
Así el .icns del bundle NUNCA puede divergir del ícono de la ventana:
fuente única de verdad.

Uso (lo llama build_mac.sh; también corre solo):
    .venv/bin/python packaging/make_icns.py
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "packaging", "zirclock.icns")


def main():
    if sys.platform != "darwin":
        sys.exit("Este script es solo para macOS (usa iconutil).")

    # QPixmap exige QGuiApplication. El plugin offscreen basta: el ícono es
    # puro dibujo vectorial, sin texto (el gotcha de fuentes no aplica).
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    from PyQt6.QtWidgets import QApplication
    app = QApplication([])

    sys.path.insert(0, ROOT)
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "zmain", os.path.join(ROOT, "main.py"))
    zmain = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(zmain)

    # Los 10 archivos del iconset de Apple: base y @2x por cada tamaño.
    entries = [
        ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
    ]
    with tempfile.TemporaryDirectory() as td:
        iconset = os.path.join(td, "ZirClock.iconset")
        os.makedirs(iconset)
        for name, size in entries:
            pm = zmain._draw_app_icon_pixmap(size)
            if not pm.save(os.path.join(iconset, name), "PNG"):
                sys.exit(f"No pude guardar {name}")
        subprocess.run(["iconutil", "-c", "icns", iconset, "-o", OUT],
                       check=True)
    print(f"OK → {OUT}")


if __name__ == "__main__":
    main()
