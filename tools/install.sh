#!/bin/bash
# Copie build/lafleur-music/ sur la console par le Wi-Fi (partages Samba invités de ROCKNIX)
# et pose le lanceur dans le menu Music. Ne touche pas à l'état (engine/state, cache, réglages, journal).
set -euo pipefail
cd "$(dirname "$0")/.."

HOST="${RGSP_HOST:-192.168.1.138}"
MNT="${TMPDIR:-/tmp}/lafleur-rgsp"
# Renvoie le point de montage du partage, en le montant si besoin (macOS refuse de le monter deux fois).
share() { # nom
  local existing
  existing=$(mount | sed -n "s#^//[^@]*@$HOST/$1 on \(.*\) (smbfs.*#\1#p" | head -1)
  if [ -n "$existing" ]; then echo "$existing"; return; fi
  mkdir -p "$MNT/$1"
  mount_smbfs -N "//guest@$HOST/$1" "$MNT/$1"
  echo "$MNT/$1"
}
ROMS=$(share games-roms)
CONFIG=$(share config)

export COPYFILE_DISABLE=1
DEST="$ROMS/lafleur-music"
mkdir -p "$DEST"
# Copie fichier par fichier, seulement ce qui a changé : rsync bute sur ce partage
# (renommage refusé, fichiers en cours d'utilisation).
changed=0
while IFS= read -r -d '' f; do
  rel="${f#build/lafleur-music/}"
  if ! cmp -s "$f" "$DEST/$rel"; then
    mkdir -p "$(dirname "$DEST/$rel")"
    cp -X "$f" "$DEST/$rel"
    changed=$((changed + 1))
  fi
done < <(find build/lafleur-music -type f ! -name '._*' ! -name '.DS_Store' -print0)
echo "$changed fichier(s) copié(s)"
cp -X "build/lafleur-music/LAFLEURMUSIC.sh" "$CONFIG/gmu/playlists/LAFLEURMUSIC.sh"
find "$DEST" "$CONFIG/gmu/playlists" -name '._*' -delete

find "$DEST" "$CONFIG/gmu/playlists" -name '._*' -delete
diff -rq -x '._*' -x state -x cache -x conf -x log.txt -x settings.txt build/lafleur-music "$DEST" && echo "installé, copie identique"
cmp "build/lafleur-music/LAFLEURMUSIC.sh" "$CONFIG/gmu/playlists/LAFLEURMUSIC.sh" && echo "lanceur en place"
