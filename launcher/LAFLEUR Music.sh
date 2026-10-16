#!/bin/bash
# LAFLEUR Music — lanceur affiché dans le menu Music de ROCKNIX (/storage/.config/gmu/playlists/).
# Démarre le moteur MPD et le gardien du clapet s'ils ne tournent pas, puis l'interface.
# À la sortie : arrière-plan OFF → arrêt du gardien (écran rallumé) et de MPD ; ON → tout continue.
# LÖVE : binaire aarch64 du port PortMaster « Spotify Connect » (ELF autonome + bin/libs),
# copié sous deux noms pour que le raccourci de fermeture de ROCKNIX (set_kill) ne vise que l'interface.

. /etc/profile

APP=/storage/roms/lafleur-music
if [ ! -d "$APP" ]; then
  echo "$(date) $APP absent (carte TF2 retirée ?)" >> /storage/.config/gmu/lafleur-missing.log
  exit 0
fi

STATE="$APP/engine/state"
LOG="$APP/log.txt"
BL=/sys/class/backlight/backlight/bl_power
mkdir -p "$STATE/playlists" "$APP/conf" "$APP/cache/covers"
: > "$LOG"
exec >> "$LOG" 2>&1
say() { echo "$(date '+%H:%M:%S') [launcher] $*"; }
alive() { [ -f "$1" ] && kill -0 "$(cat "$1")" 2>/dev/null; }

# Bibliothèques séparées : celles du port MPD (dont une vieille libdrm) ne doivent servir qu'à MPD,
# sinon le pilote graphique de LÖVE plante. /usr/lib/compat : compatibilité ROCKNIX (libtheoradec…).
MPD_LIBS="$APP/engine/libs:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$APP/bin/libs:/usr/lib/compat:$LD_LIBRARY_PATH"
# Correspondance des boutons de la console pour SDL, générée comme le fait PortMaster.
PADDB=/tmp/lafleur-gamecontrollerdb.txt
if [ -x /storage/.config/PortMaster/mapper.txt ]; then
  /storage/.config/PortMaster/mapper.txt "$PADDB" /storage/roms/ports/PortMaster && export SDL_GAMECONTROLLERCONFIG_FILE="$PADDB"
fi
export XDG_DATA_HOME="$APP/conf"
export LAFLEUR_APPDIR="$APP"

if alive "$STATE/pid"; then
  say "MPD déjà en route"
elif LD_LIBRARY_PATH="$MPD_LIBS" "$APP/engine/mpd" "$APP/engine/mpd.conf"; then
  say "MPD démarré"
else
  say "MPD n'a pas démarré"
fi

if alive "$STATE/lidwatch.pid"; then
  say "gardien déjà en route"
else
  (cd "$APP/lidwatch" && exec "$APP/bin/lafleur-lid" .) &
  echo $! > "$STATE/lidwatch.pid"
  say "gardien démarré"
fi

set_kill set "lafleur-ui"
cd "$APP/ui" && "$APP/bin/lafleur-ui" .
say "interface terminée (code $?)"

if [ "$(cat "$STATE/background" 2>/dev/null)" != "on" ]; then
  alive "$STATE/lidwatch.pid" && kill "$(cat "$STATE/lidwatch.pid")"
  rm -f "$STATE/lidwatch.pid"
  echo 0 > "$BL"
  LD_LIBRARY_PATH="$MPD_LIBS" "$APP/engine/mpd" --kill "$APP/engine/mpd.conf" && say "MPD arrêté (arrière-plan OFF)"
else
  say "arrière-plan ON : la musique continue"
fi
