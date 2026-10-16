"""Génère ui/assets/ depuis les logos LAFLEURSTUDIO et les polices du thème Elementerial.

Usage : <venv>/bin/python -I tools/make-assets.py   (cairosvg, Pillow ; DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib)
"""
import io
import shutil
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGOS = Path("/Users/jkern/Claude/Logos LAFLEURSTUDIO")
FONTS = Path.home() / "Downloads/es-theme/extrait/es-theme-elementerial-main/assets/fonts/Inter"
OUT = ROOT / "ui/assets"


def svg(name, width):
    data = cairosvg.svg2png(url=str(LOGOS / name), output_width=width)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def main():
    (OUT / "fonts").mkdir(parents=True, exist_ok=True)
    svg("Logo-texte-LAFLEURSTUDIO-blanc.svg", 250).save(OUT / "logo-texte.png")
    flower = svg("Logo-fleur-LAFLEURSTUDIO-rose.svg", 480)
    flower.save(OUT / "fleur.png")
    tile = Image.new("RGBA", (300, 300), (0x1A, 0x1A, 0x1A, 255))
    small = flower.resize((165, int(165 * flower.height / flower.width)), Image.LANCZOS)
    tile.alpha_composite(small, ((300 - small.width) // 2, (300 - small.height) // 2))
    tile.convert("RGB").save(OUT / "fleur-tile.png")
    for f in ("Inter-Regular.otf", "Inter-Bold.otf", "LICENSE.txt"):
        shutil.copy(FONTS / f, OUT / "fonts" / f)
    print("assets ok")


if __name__ == "__main__":
    main()
