#!/bin/bash
# Copie build/lafleur-music/ sur la console par le Wi-Fi (partages Samba invités de ROCKNIX)
# et pose le lanceur dans le menu Music. Ne touche pas à l'état (engine/state, cache, réglages, journal).
set -euo pipefail
cd "$(dirname "$0")/.."

HOST="${RGSP_HOST:-192.168.1.138}"
MNT="${TMPDIR:-/tmp}/lafleur-rgsp"
mkdir -p "$MNT/roms" "$MNT/config"
mount_if_needed() { # partage dossier
  if ! mount | grep -q " $2 "; then mount_smbfs -N "//guest@$HOST/$1" "$2"; fi
}
mount_if_needed games-roms "$MNT/roms"
mount_if_needed config "$MNT/config"

export COPYFILE_DISABLE=1
DEST="$MNT/roms/lafleur-music"
mkdir -p "$DEST"
rsync -rt --exclude='._*' --exclude='.DS_Store' build/lafleur-music/ "$DEST/"
cp "build/lafleur-music/LAFLEUR Music.sh" "$MNT/config/gmu/playlists/LAFLEUR Music.sh"
find "$DEST" "$MNT/config/gmu/playlists" -name '._*' -delete

diff -rq -x state -x cache -x conf -x log.txt -x settings.txt build/lafleur-music "$DEST" && echo "installé, copie identique"
cmp "build/lafleur-music/LAFLEUR Music.sh" "$MNT/config/gmu/playlists/LAFLEUR Music.sh" && echo "lanceur en place"
