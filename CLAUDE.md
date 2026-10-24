# Camp Everywhere — Mod für Of Ash and Steel

Pascals Mod: Wer das Material hat, soll **überall an sinnvollen Orten** ein Lager aufschlagen können, nicht nur an den festen Lagerplätzen. Nicht in Häusern und nicht in der Stadt.

## Status

**Version 1 läuft (P, 2026-10-24):** Schnellmenü → pulsierende Geistergrün/Rot-Vorschau des Feuerkreises → nochmal drücken setzt das Lager. Geprüft: grün, rot, Hang, Stadt. Ungetestet: Gegner (`QS_CheckDanger`-Rückgabe), Wasser, neue Stapel per Hook. Danach Nexus-Release.
Ablauf wie üblich: `superpowers:brainstorming` → Design → Plan → Bau. Nichts bauen, bevor Pascal das Design freigegeben hat (ausgenommen Wegwerf-Spikes, die er will).

Legende: **(P)** = Pascal hat es so gesagt · **(C)** = Claudes Vorschlag oder Befund, noch nicht bestätigt

## Freigegebenes Design (P, 2026-10-24)

1. Schnellmenü-Taste mit Lagervorräten → durchsichtige **Vorschau** des Lagers (Feuerstelle + Zelt) vor dem Spieler, wandert mit.
2. **Grün**, wenn der Ort passt, sonst **rot**. Passt = unter freiem Himmel (kein Dach), nicht in Stadt/Siedlung, ebener Boden, kein Wasser, keine Gegner in der Nähe.
3. **Dieselbe Taste nochmal:** bei Grün Lager aufschlagen, bei Rot abbrechen.
4. Danach wie an festen Plätzen: Prompt, Skill `skill_survival_01`, 1 Lagervorräte, Camp-Menü (alles Spiel-Logik).
5. Immer nur ein Lager. Ein neues ersetzt das alte, keine Speicherung.
6. Neue Lagervorräte-Stapel werden automatisch schnellmenü-fähig.
Umsetzung: ein UE4SS-Lua-Mod (`CampEverywhere`), Stadt-Erkennung = Claudes Sache.

## Machbarkeitstest (2026-10-24): bestanden

- UE4SS experimental (v3.0.1-1181) läuft unter Proton 11 auf dem Deck. Installiert: `dwmapi.dll` + `ue4ss/` in `ofAshAndSteelGame/Binaries/Win64/`. DLL-Override steht in der Wine-Registry `pfx/user.reg` (`[Software\\Wine\\DllOverrides]` → `"dwmapi"="native,builtin"`, Backup `user.reg.bak-camp-everywhere`). Steam-Startoptionen bleiben unverändert. Log: `Win64/ue4ss/UE4SS.log`. Hot-Reload der Lua-Mods im Spiel: **Strg+R**.
- Testscript `deploy/ue4ss/Mods/CampEverywhere/Scripts/main.lua` (lokal staged, aufs Deck per `cat | ssh … 'cat > …'`). F7 spawnt `GS_CampPlace_C` 3 m vor dem Spieler auf dem Boden (LineTrace), F8 entfernt, F6 zählt, F9 vergleicht die Eigenschaften mit dem nächsten festen Platz.
- **Ergebnis (P):** Der gespawnte Lagerplatz erscheint, und Prompt, Ressourcen-Abzug und Camp-Menü funktionieren wie an einem festen Platz. Im Level gibt es 21 feste `GS_CampPlace_C` (in `0-0_QuestLayer`).
- Pascals Tastatur schickt für F8 ohne Fn eine Medientaste (Moonlight reicht sie weiter) → Test-Tasten mit Medienbelegung meiden.
- Spielstand-Backup vor dem Test: Deck `~/backups/oas-saves-20261024-1306.tar.gz`, Kopie `../backups/`.
- Rückbau: `dwmapi.dll` aus `Win64/` entfernen (oder die Override-Zeile in `user.reg` löschen).

## Wunsch (Brainstorming)

- (P) Heute: An festen Lagerplätzen gibt es einen Prompt. Campen kostet eine Ressource, dann öffnet sich das Camp-Menü. Dass das nur an festen Punkten geht, nervt.
- (P) Bedienung: Die Lager-Ressource liegt im Schnellmenü. Wählt man sie aus, erscheint eine **Geister-Vorschau** des Lagers, **grün** wo es erlaubt ist, **rot** wo nicht. Bestätigen setzt das Lager.
- (P) Der Lager-Gegenstand muss auf **allen vier Schnellmenü-Plätzen** funktionieren (Tastatur Z/X/C/V bzw. Gamepad).
- (P) Falls die Ressource nicht ins Schnellmenü darf: ein neuer, **unendlicher Lager-Gegenstand** fürs Schnellmenü, der beim grünen Bestätigen die bisherige Ressource abzieht.
- (P) Pascal spielt per Moonlight auf dem PC. (C) Annahme: Das Spiel läuft auf dem Deck und wird gestreamt (Pascal hat nicht widersprochen).
- (C) Erlaubt heißt: draußen, halbwegs ebener Boden, nicht in Haus oder Stadt, kein Wasser, keine Gegner in der Nähe.
- (C) In Stufen bauen: 1. Taste setzt das Lager oder meldet „hier nicht“. 2. Ortsprüfung. 3. Schnellmenü und rot/grüne Vorschau.
- (P) Es gibt **immer nur ein eigenes Lager**: Ein neues ersetzt das alte, und gespeichert wird es nicht (nach dem Laden ist es weg). Pascal: „Ich würde mein Zelt ja auch nicht stehen lassen und ein neues kaufen.“

## Spiel & Umgebung

- Unreal Engine 4.27 (Pak V11), Steam-AppID 2893820, installiert auf der Deck-SD: `/run/media/mmcblk0p1/steamapps/common/ofAshAndSteel/`. Prefix `/run/media/mmcblk0p1/steamapps-new/compatdata/2893820/`, Spielstände unter `…/pfx/drive_c/users/steamuser/AppData/Local/ofAshAndSteelGame/Saved/SaveGames/`.
- Startoptionen heute: `-dx11 -nothreadtimeout`, Proton 11.0. UE4SS braucht zusätzlich `WINEDLLOVERRIDES="dwmapi=n,b" … %command%`.
- Installierte Mods: nur **RoadSigns** (`Content/Paks/ofAshAndSteelGame-WindowsNoEditor_94_P.pak`). Er ersetzt per `_P`-Pak drei Assets (`Components/WoodSign/GS_WoodSign`, `GS_WoodSignWidget`, `Font/I_SecondFont`). Kein UE4SS installiert.
- Spieldetails fürs Deck stehen in `~/Code/steamdeck/games/ash-and-steel.md`.

## Repo & Ablauf

- Git-Repo: `~/Code/ash-and-steel-mods` (lokal). **Quelle des Mods:** `camp-everywhere/mod/CampEverywhere/` (`Scripts/main.lua`, `enabled.txt`). Testscript der Machbarkeitsphase: `spikes/test-script-spike.lua`.
- Aufs Deck: `camp-everywhere/scripts/deploy-deck.sh`, dann im Spiel Strg+R.
- **Nie ins Repo oder irgendwohin hochladen:** `research/` (extrahierte Spiel-Assets), `tools/`, `backups/` (Spielstände), `deploy/` (UE4SS-Binaries). Steht in `.gitignore`.
- Ziel: Veröffentlichung auf Nexus Mods (Pascal lädt mit seinem Account hoch, Claude bereitet Paket und Beschreibung vor).

## Nexus-Release

- **Nur Englisch** (P): Beschreibung, Readme, Kommentare für die Veröffentlichung.
- Vorlage ist Pascals Pathfinder-Flow: `~/Code/pathfinder-mods/docs/nexus.md` (API, IDs, Re-Upload) und `…/wrath/wrath-tactics/docs/nexus-release-flow-guide.md` (GitHub-Release → `Nexus-Mods/upload-action`, gepinnt auf `@v1.0.0-beta.8`). Die erste Mod-Seite legt Pascal im Browser an und lädt die erste ZIP manuell hoch.
- Seitenbilder: Header **1920×720**, Thumbnail **900×506**, in `docs/` (dort gitignored, `git add -f`). Stil der bisherigen Mods: Szenenbild + großer Serifen-Titel in Cremegold mit dunkelbrauner Kontur, darunter kursiver Untertitel (PIL, Font `DejaVuSerifCondensed-Bold.ttf`). Beschreibung als BBCode in `docs/nexus-description.bbcode` (Aufbau wie `fix-subsonic-bullshit`: Titel, Problem, Lösung/How it works, Installation, Compatibility, Source Code).
- Getestet (P): Stadt = rot ✔.

## Regeln

- **Deck:** Vor jedem Spielstart, jeder Änderung im Spielordner und jedem Steam-Eingriff fragen, ob Pascal gerade spielt. Nur lesen geht auch nebenbei (`nice -n 19 ionice -c3`).
- Deck-SSH aus der citadel-Tunnel-Shell: `ssh -n -i ~/.ssh/deck_citadel -o IdentitiesOnly=yes deck-direct …`. `-n` ist Pflicht, sonst verschluckt ssh das restliche Script von stdin. Für Pipes (`cat x | ssh …`) ohne `-n`.
- Vor jedem Mod-Test die Spielstände sichern.
- Keine Dauer-Volllast auf dem Laptop (er ist schon einmal überhitzt und gecrasht). Keinen UE-Editor aus dem Quellcode bauen.

## Werkzeuge (`../tools/`, Recherche in `../research/`)

- `repak` 0.2.3 (Deck-Kopie `~/bin/repak`): `repak list <pak>` · Entpacken: `repak unpack -q -f -o /tmp/oas -i <pfad> <pak>`, **ein `-i` pro Aufruf** (mehrere in einem Aufruf entpackten nichts). Pfade ohne `../../../`, z. B. `ofAshAndSteelGame/Content/RPG_InventorySystem/...`.
- Komplette Dateiliste: `../research/paklist.txt` (344.301 Einträge). Entpackte Assets: `../research/extract/` (RPG_InventorySystem: ItemsData, Components, HUD, PlayerInventory, Interactable, SortedOtherItems, Consumable).
- `kismet-analyzer` (`../tools/kismet-analyzer/kismet-analyzer-*/kismet-analyzer`, `--ue-version VER_UE4_27`): `gen-cfg <asset> <outdir>` liefert lesbaren Bytecode als `.txt` (Beispiel `../research/cfg/GS_CampPlace/`), `to-json` liefert JSON.
- Schnelle Übersicht über einen Blueprint: `strings -n 3 <asset>.uasset` zeigt die Namenstabelle (Funktionen, Variablen, Referenzen).
- UE4SS experimental (`../tools/UE4SS_v3.0.1-1181-*.zip`, Dev-Variante `zDEV-…`), noch nicht getestet.

## Befunde: Lager

- `RPG_InventorySystem/Classes/Interactable/GS_CampPlace` (Klasse `GS_CampPlace_C`, Parent `Actor`) ist in sich geschlossen: Interaction → `CampChecks` → `MakeCamp` → Camp-Menü `CampplaceWidget/GS_CampPlace_W`.
- `CampChecks`:
  - braucht den Skill `skill_survival_01`, sonst Spieler-Reaktion `tris_check_04`;
  - braucht die Item-ID `bonfire_resource` im `AC_PlayerInventory` (`Get Item by ID`), sonst Reaktion `tris_check_10`;
  - zieht dann 1× ab (`Remove Item Quantity`), zeigt eine Notification und gibt Result true zurück.
- **Im Lager selbst gibt es keine Ortsprüfung**, die festen Plätze sind nur in der Welt platziert. (C) Ansatz: per UE4SS-Lua einen `GS_CampPlace_C` vor den Spieler spawnen, den Rest macht das Spiel (gleiche Kosten, gleiches Menü).
- Weitere Funktionen: `MakeCamp`, `RemoveCamp`, `SetCampLevel` (Ausbaustufen `Level_A_1..24`, `Level_B_1..12`, vermutlich skill-abhängig), `QS_CheckDanger` (Gegner in der Nähe?), `BanditsEvent`, `CraftInteraction` (Kochen/Alchemie am Lager), `SetCamper`, `Game Load`, `Initialize`. Meshes: `gs_camp_stones`, `SM_SmallTent_01`, `SM_LongTent_01/02`, `SM_RolledBed`.
- Ungeklärt: Braucht ein gespawnter Lagerplatz Referenzen aus dem Level (`Setup Interactable References`, `Game Load`)? Wie verhält er sich im Spielstand (`S_SaveInteractables`)?

## Befunde: Items & Schnellmenü

- Ressource: `Classes/MainItemClasses/SortedOtherItems/bonfire_resource` (Basisklasse `MainItemClasses/BP_MainItem`), Rezept `rec_bonfire_resource`, Pickup `Interactable/SingleItems/Stuff/gs_pickup_bonfire_resource`.
- Schnellmenü vermutlich `UI/HUD/WB_ConsumableBar` + `WB_ConsumableBarSlot`. Dazu `UI/PlayerInventory/WB_QuckSlots_Melee/_Range/ButtonGamepad/ButtonKeyboard` (sic, „Quck“).
- Nutzungsart: Enum `ItemsData/Enums/E_ItemUseType` (Werte `NewEnumerator0..12`, Anzeigenamen noch nicht ausgelesen). Itemdaten: `ItemsData/Structs/S_ItemData`, `ItemsData/DataTable/`.
- Im Spiel heißt die Ressource **Lagervorräte** / „Camp Supplies“ (Stringtable `RPG_Items`, Key `bonfire_resource`; Icon `instrumenti_dlya_rozhiga` = Anzündwerkzeug). Texte: `../research/Grayshaft_UI.<de|en>.locres`, lesbar mit `../tools/locres.py`.
- Enums (Zahlenwert → Name): `E_InventoryPanels` 0=NewEnumerator4 (none), 1..4 = Reiter P1..P4 (NewEnumerator0..3). Essen und Pfeife liegen in P2 (Wert 2), Lagervorräte in P3 (Wert 3). `E_ItemType`: 0 Sonstiges, 4 Essen, 5 Medizin (Pfeife), 9 = Sonderfall in `AC_InventoryCore` (Gold?).
- Klassen-Vorlagen (CDO) lassen sich zur Laufzeit per UE4SS ändern (`Default__bonfire_resource_C`: `Type`, `["Inventory Panel"]`). Die Anzeige im Inventar folgt sofort (P2 zeigt die Lagervorräte). **Aber:** Das Inventar hält pro Reiter eine eigene Liste (`InventoryP1..P4` im `AC_PlayerInventory`), und jeder Stapel hat eigene Daten (`S_ItemData`, u. a. `EquipmentSlot`). Ein vorhandener Stapel ließ sich danach nicht aufs Schnellmenü legen (P). Hypothese: Die Einordnung passiert beim Aufnehmen, ungetestet.
- **Schnellmenü-Regel (gelöst 2026-10-24):** Die vier Schnellmenü-Plätze sind die Ausrüstungs-Slots `E_ItemSlot` **Pocket1..4 = Werte 9..12** (Enum-Namen NewEnumerator8..11). `WB_EquipmentSlot:OnDrop` prüft nur das **Stapel-Feld** `EquipmentSlot_82_D8E166834B91EEF8631726AE76BDFFE0` (muss 9..12 sein), nicht Typ, Reiter oder Klasse. Setzt man es per Lua bei den Lagervorräte-Stapeln auf 9, lassen sie sich auf alle Plätze legen (P: „ja geht“). Typ/Reiter-Änderung an der CDO war dafür nicht nötig.
- Stapel-Daten `S_ItemData` (Felder mit GUID-Suffix): `ID_71_E0AE465E423DCDD08FF98D87A5C0B84F` (String, z. B. `bonfire_resource`), `EquipmentSlot_82_D8E166834B91EEF8631726AE76BDFFE0`, `Quantity_76_AD4B883E4427C3E60B4B22B072F4E7C9`, `Class_81_28B5086542C7943CC83294BF5B57815A`, `Index_25_…`, `Tier_92_…`. Listen: `FindFirstOf("AC_PlayerInventory_C").InventoryP1..P4` (TArray, 1-basiert in Lua, Felder direkt beschreibbar).
- **Typ/Reiter der CDO NICHT ändern:** Der Versuch (Type 5, Panel 2) ließ die Anzeige umziehen, aber die Stapel blieben in `InventoryP3`. Beim Verkaufen/Zurückkaufen buchte der Händler dann in die falsche Liste, und es entstand ein Phantom-Stapel (50 statt 25). Pascal hat einen alten Spielstand geladen. Das Script setzt jetzt die Originalwerte (Type 0, Panel 3).
- **Schnellmenü-Benutzung (gelöst):** Taste → `AC_ConsumableBuffs:Try to Use Consumable(Slot, FromInventory?, …)`, Slot = Pocket 9..12. Das Item im Pocket steht in `FindFirstOf("AC_PlayerEquipment_C")["Equipment Data"]` (TMap E_ItemSlot → S_ItemData, `ForEach(k,v)` mit `:get()`). Für Lagervorräte bricht das Spiel selbst ab (kein Verbrauchsgut) → nichts geht verloren, der Hook kann übernehmen. Getestet: Taste setzt das Lager, ein neues ersetzt das alte (P).
- Neue Stapel (Kauf, Aufheben) bekommen wieder `EquipmentSlot` 0 → der Mod muss sie beim Hinzufügen nachziehen (Hook auf das Hinzufügen oder beim Öffnen des Inventars).
- Benutzen von Verbrauchsgütern: `WB_PlayerInventorySlot` → `Try to Use an Item` → `AC_ConsumableBuffs` „Try to Use Consumable“. Schnellmenü-Slot-Widget: `WB_ConsumableBarSlot` (Hook „On Item Used“ ist gesetzt, hat noch nicht ausgelöst).
- Für die Geister-Vorschau gibt es im Spiel `/Engine/EngineDebugMaterials/M_SimpleUnlitTranslucent` (ob es einen Farbparameter hat, ist noch zu prüfen).
