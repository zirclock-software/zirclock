#!/usr/bin/env python
"""Genera packaging/zirclock.ico desde el ícono dibujado EN CÓDIGO (Ola 10, Win).

Gemelo de make_icns.py para Windows. El ícono de ZirClock no vive en un
archivo de imagen: lo dibuja _draw_app_icon_pixmap() en main.py (motivo de
cristal de zircón, azul de la marca). Este script lo renderiza a los tamaños
que Windows consulta y los empaqueta en un solo .ico multi-resolución. Así el
ícono del .exe, del acceso directo y del Explorador NUNCA puede divergir del
ícono de la ventana: fuente única de verdad.

¿Por qué renderizar CADA tamaño en vez de reescalar uno grande? El dibujo es
vectorial con geometría fraccional, así que a 16 px sale nítido dibujado a
16 px; reducir un PNG de 256 lo dejaría lavado justo en el tamaño que más se
ve (la lista del Explorador y la barra de tareas).

macOS usa `iconutil` (herramienta del sistema); en Windows no hay equivalente,
así que el contenedor .ico lo arma Pillow — ya está en requirements.txt porque
matplotlib lo arrastra.

Uso (lo llama build_win.ps1; también corre solo):
    .venv\\Scripts\\python.exe packaging\\make_ico.py
"""
import os
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "packaging", "zirclock.ico")

# Los tamaños que Windows consulta: 16 (lista del Explorador, barra de título),
# 24/32 (barra de tareas, iconos medianos), 48 (iconos grandes del Escritorio),
# 64/128 (escalado en pantallas HiDPI), 256 (vista "Iconos muy grandes" y la
# ficha del instalador). Windows elige el más cercano y reduce si hace falta.
SIZES = [16, 24, 32, 48, 64, 128, 256]


def main():
    # QPixmap exige QGuiApplication. El plugin offscreen basta: el ícono es
    # puro dibujo vectorial, sin texto (el gotcha de fuentes no aplica).
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    from PyQt6.QtWidgets import QApplication
    # La referencia se GUARDA a propósito: sin ella el GC de Python destruye
    # la QApplication y el primer QPixmap tumba el proceso sin traceback.
    app = QApplication([])  # noqa: F841

    sys.path.insert(0, ROOT)
    import importlib.util
    spec = importlib.util.spec_from_file_location(
        "zmain", os.path.join(ROOT, "main.py"))
    zmain = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(zmain)

    from PIL import Image

    with tempfile.TemporaryDirectory() as td:
        pngs = []
        for size in SIZES:
            path = os.path.join(td, f"icon_{size}.png")
            pm = zmain._draw_app_icon_pixmap(size)
            if not pm.save(path, "PNG"):
                sys.exit(f"No pude guardar el render de {size} px")
            pngs.append(Image.open(path).convert("RGBA"))

        # La imagen BASE tiene que ser la MÁS GRANDE: Pillow descarta de
        # `sizes` todo lo que exceda las dimensiones de la base (con la de
        # 16 px como base, el .ico salía con una sola resolución). El resto
        # van como frames y Pillow los empareja POR TAMAÑO, así que cada
        # resolución conserva su render nativo en vez de un reescalado.
        pngs.sort(key=lambda im: im.size[0], reverse=True)
        pngs[0].save(OUT, format="ICO",
                     sizes=[(s, s) for s in SIZES],
                     append_images=pngs[1:])

    # Verificación: releer el .ico y confirmar que trae las 7 resoluciones.
    from PIL import Image as _Image
    with _Image.open(OUT) as ico:
        got = sorted(w for w, _h in ico.info["sizes"])
    if got != sorted(SIZES):
        sys.exit(f"El .ico salió con {got}, se esperaban {sorted(SIZES)}")

    print(f"OK → {OUT}  ({len(got)} resoluciones: {got})")


if __name__ == "__main__":
    main()
