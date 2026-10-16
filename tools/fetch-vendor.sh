#!/bin/bash
# Télécharge les binaires aarch64 réutilisés (MPD et LÖVE 11.5) depuis les ports PortMaster officiels,
# vérifie les md5 et les extrait dans vendor/.
set -euo pipefail
cd "$(dirname "$0")/.."

MPD_URL=https://github.com/PortsMaster/PortMaster-New/releases/download/2025-08-21_2306/mpd.zip
MPD_MD5=acdf22cde8b8e3e3eacf23750c9f516a
LOVE_URL=https://github.com/PortsMaster/PortMaster-New/releases/download/2026-01-25_1827/librespot.zip
LOVE_MD5=89bc0488cde203423a12b6c47dc4f1a5

mkdir -p vendor
fetch() { # url md5 fichier
  if [ ! -f "vendor/$3" ] || [ "$(md5 -q "vendor/$3")" != "$2" ]; then
    curl -sSfL --retry 3 -o "vendor/$3" "$1"
  fi
  if [ "$(md5 -q "vendor/$3")" != "$2" ]; then
    echo "md5 incorrect pour $3" >&2
    exit 1
  fi
  echo "md5 OK $3"
}
fetch "$MPD_URL" "$MPD_MD5" mpd.zip
fetch "$LOVE_URL" "$LOVE_MD5" librespot.zip

rm -rf vendor/mpd vendor/librespot
unzip -q vendor/mpd.zip 'mpd/mpd' 'mpd/libs/*' 'mpd/licenses/*' -d vendor
unzip -q vendor/librespot.zip 'librespot/love' 'librespot/libs/*' 'librespot/LICENSE.txt' -d vendor
echo "vendor prêt"
