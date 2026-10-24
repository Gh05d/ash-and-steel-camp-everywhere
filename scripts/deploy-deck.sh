#!/bin/bash
# Kopiert den Mod (nur mod/CampEverywhere) aufs Steam Deck. Danach im Spiel Strg+R (Hot-Reload).
# Voraussetzung: UE4SS ist im Spiel installiert (siehe ../CLAUDE.md).
set -e
cd "$(dirname "$0")/.."
W=/run/media/mmcblk0p1/steamapps/common/ofAshAndSteel/ofAshAndSteelGame/Binaries/Win64/ue4ss/Mods
tar czf - -C mod CampEverywhere | ssh -i "$HOME/.ssh/deck_citadel" -o IdentitiesOnly=yes -o BatchMode=yes deck-direct \
  "tar xzf - -C $W && ls -la $W/CampEverywhere/Scripts"
