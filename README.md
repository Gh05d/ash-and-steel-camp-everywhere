# Camp Everywhere: Smart Resting

A UE4SS mod for **Of Ash and Steel** that lets you make camp wherever it makes sense, not only at the fixed camp spots.

Download: [Nexus Mods](https://www.nexusmods.com/ofashandsteel/mods/60) or the [GitHub releases](https://github.com/Gh05d/ash-and-steel-camp-everywhere/releases).

## How it works

1. Put **Camp Supplies** on any of the four quick slots.
2. Press that quick slot. A ghost of the camp fire ring appears in front of you and follows you: **green** where you can camp, **red** where you can't.
3. Press the quick slot again. On green, the camp is set up. On red, the ghost disappears.
4. Use the camp like any other camp spot.

The ghost turns red under a roof (tree tops don't count), in towns and villages (people or buildings all around), on steep ground or big height differences, in water, and when enemies are close.

Making camp is the game's own logic: same prompt, same Survival skill requirement, one Camp Supplies per camp, same camp menu. You have one camp at a time, and camps are not saved.

## Installation

1. Install [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) (experimental build, tested with v3.0.1-1181): `dwmapi.dll` and the `ue4ss` folder go into `ofAshAndSteel/ofAshAndSteelGame/Binaries/Win64/`.
2. Extract the release zip into the game folder `ofAshAndSteel/`. The mod ends up in `ofAshAndSteelGame/Binaries/Win64/ue4ss/Mods/CampEverywhere/`.
3. Steam Deck / Linux (Proton): add `WINEDLLOVERRIDES="dwmapi=n,b" %command%` to the game's launch options.

Settings (distances, colors, town detection, debug log) are at the top of `Scripts/main.lua`.

## Development

- `scripts/deploy-deck.sh` copies the mod to the Steam Deck (with debug log on; `DEBUG=0` for the release build). Reload in game with Ctrl+R.
- `scripts/package.py` builds `dist/CampEverywhere-<version>.zip`; `./release.sh` tags, creates the GitHub release and triggers the Nexus upload.
- `scripts/make_nexus_images.py` builds the Nexus header and thumbnail from `docs/art/`.

## License

MIT
