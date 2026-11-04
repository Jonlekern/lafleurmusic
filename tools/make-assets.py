"""Génère ui/assets/ depuis les logos LAFLEURSTUDIO (fleur), le logo texte LAFLEURMUSIC (v2, Calebard Black) et les polices du thème Elementerial.

Usage : LAFLEUR_LOGOS=<dossier des logos SVG> \
        LAFLEUR_INTER=<dossier des polices Inter> python -I tools/make-assets.py
(cairosvg, Pillow ; sur macOS : DYLD_FALLBACK_LIBRARY_PATH=/opt/homebrew/lib). Les images générées sont déjà dans ui/assets.
"""
import io
import os
import shutil
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGOS = Path(os.environ["LAFLEUR_LOGOS"])
FONTS = Path(os.environ["LAFLEUR_INTER"])
OUT = ROOT / "ui/assets"
# Logo texte LAFLEURMUSIC v2 (Calebard Black), blanc, dans le dossier des logos.
WORDMARK = "v2/Logo-texte-LAFLEURMUSIC-blanc-v2.svg"


def svg(name, width):
    data = cairosvg.svg2png(url=str(LOGOS / name), output_width=width)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def main():
    (OUT / "fonts").mkdir(parents=True, exist_ok=True)
    svg(WORDMARK, 250).save(OUT / "logo-texte.png")
    svg(WORDMARK, 900).save(OUT / "logo-texte-grand.png")
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
