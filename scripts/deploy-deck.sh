#!/bin/bash
# Kopiert den Mod (mod/CampEverywhere) aufs Steam Deck. Danach im Spiel Strg+R (Hot-Reload).
# Standardmäßig mit Debug-Log (Gründe für Rot in ue4ss/UE4SS.log); DEBUG=0 deployt genau die Release-Fassung.
# Voraussetzung: UE4SS ist im Spiel installiert (siehe ../CLAUDE.md).
set -e
cd "$(dirname "$0")/.."
W=/run/media/mmcblk0p1/steamapps/common/ofAshAndSteel/ofAshAndSteelGame/Binaries/Win64/ue4ss/Mods
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
cp -r mod/CampEverywhere "$T/"
[ "${DEBUG:-1}" = 1 ] && sed -i 's/^\(    debug = \)false/\1true/' "$T/CampEverywhere/Scripts/main.lua"
grep -m1 '^    debug = ' "$T/CampEverywhere/Scripts/main.lua"
tar czf - -C "$T" CampEverywhere | ssh -i "$HOME/.ssh/deck_citadel" -o IdentitiesOnly=yes -o BatchMode=yes deck-direct \
  "tar xzf - -C $W && ls -la $W/CampEverywhere/Scripts"
