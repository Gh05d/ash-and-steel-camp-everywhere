Camp Everywhere - Smart Resting (Of Ash and Steel)

Make camp wherever it makes sense, not only at the fixed camp spots.

REQUIREMENT
  UE4SS (experimental build, tested with v3.0.1-1181):
  https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest

INSTALL
  1. Put dwmapi.dll and the ue4ss folder from UE4SS into
     ofAshAndSteel\ofAshAndSteelGame\Binaries\Win64\
  2. Extract this mod into the game folder ofAshAndSteel\ so that it ends up in
     ofAshAndSteelGame\Binaries\Win64\ue4ss\Mods\CampEverywhere\
  3. enabled.txt in this folder turns the mod on.

  Steam Deck / Linux: add to the game's launch options in Steam
     WINEDLLOVERRIDES="dwmapi=n,b" %command%

HOW TO USE
  1. Put Camp Supplies on any of the four quick slots.
  2. Press that quick slot: a ghost of the fire ring appears in front of you.
     Green = you can camp here, red = you can't (roof, town or village, too steep,
     water, enemies nearby).
  3. Press the quick slot again: on green the camp is set up, on red the ghost disappears.
  Making camp itself works like at any camp spot (Survival skill, one Camp Supplies).
  One camp at a time; camps are not saved.

SETTINGS
  Distances, colors and the town detection can be changed at the top of
  Scripts\main.lua (CFG). Set debug = true to log why the ghost is red (ue4ss\UE4SS.log).

UNINSTALL
  Delete this folder. The mod doesn't change game files or save data.
