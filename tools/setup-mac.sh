#!/bin/bash
# Installe les outils de développement sur le Mac (idempotent) : LuaJIT, MPD, LÖVE 11.5.
set -euo pipefail

for f in luajit mpd; do
  if ! brew list --formula "$f" >/dev/null 2>&1; then
    brew install "$f"
  fi
done

# LÖVE n'est pas installé sur le Mac : le cask Homebrew « love » est désactivé depuis le 01.09.2026
# (Gatekeeper). L'interface est testée sur la console, qui a son propre LÖVE 11.5.

luajit -v
mpd --version | head -1
