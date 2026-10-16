#!/bin/bash
# Assemble build/lafleur-music/ (le dossier copié sur la console). Prérequis : tools/fetch-vendor.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=build/lafleur-music
rm -rf "$OUT"
mkdir -p "$OUT"/{bin/libs,engine/libs,licenses}

for part in ui lidwatch; do
  cp -R "$part" "$OUT/$part"
  mkdir -p "$OUT/$part/common"
  cp common/*.lua "$OUT/$part/common/"
done

cp vendor/mpd/mpd "$OUT/engine/mpd"
cp vendor/mpd/libs/* "$OUT/engine/libs/"
cp engine/mpd.conf "$OUT/engine/mpd.conf"
cp vendor/librespot/love "$OUT/bin/lafleur-ui"
cp vendor/librespot/love "$OUT/bin/lafleur-lid"
cp vendor/librespot/libs/* "$OUT/bin/libs/"
chmod +x "$OUT/engine/mpd" "$OUT/bin/lafleur-ui" "$OUT/bin/lafleur-lid"

cp "vendor/mpd/licenses/MPD License.txt" "$OUT/licenses/MPD-GPL-2.0.txt"
cp vendor/librespot/LICENSE.txt "$OUT/licenses/port-librespot-LICENSE.txt"
cp ui/assets/fonts/LICENSE.txt "$OUT/licenses/Inter-OFL.txt"
cp "launcher/LAFLEUR Music.sh" "$OUT/LAFLEUR Music.sh"
chmod +x "$OUT/LAFLEUR Music.sh"

xattr -cr "$OUT" # sinon macOS crée des fichiers ._* sur le partage
find "$OUT" -name '._*' -delete
echo "build prêt : $OUT ($(du -sh "$OUT" | cut -f1))"
