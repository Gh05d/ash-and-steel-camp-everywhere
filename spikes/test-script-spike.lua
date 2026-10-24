-- Camp Everywhere: Machbarkeitstest.
-- F7 setzt einen Lagerplatz (GS_CampPlace_C) 3 m vor den Spieler, F8 entfernt die gesetzten, F6 zählt die Lagerplätze.
local UEHelpers = require("UEHelpers")

local CAMP_PACKAGE = "/Game/RPG_InventorySystem/Classes/Interactable/GS_CampPlace"
local CAMP_CLASS = CAMP_PACKAGE .. ".GS_CampPlace_C"
local spawned = {}

local function log(fmt, ...)
    print("[CampEverywhere] " .. string.format(fmt, ...) .. "\n")
end

local function getCampClass()
    local cls = StaticFindObject(CAMP_CLASS)
    if cls and cls:IsValid() then return cls end
    LoadAsset(CAMP_PACKAGE)
    cls = StaticFindObject(CAMP_CLASS)
    if cls and cls:IsValid() then return cls end
    return nil
end

local function groundBelow(pawn, x, y, z)
    local hit = {}
    local noColor = { R = 0, G = 0, B = 0, A = 0 }
    local ok = UEHelpers.GetKismetSystemLibrary():LineTraceSingle(
        pawn, { X = x, Y = y, Z = z + 200 }, { X = x, Y = y, Z = z - 1000 },
        0, false, {}, 0, hit, true, noColor, noColor, 0.0)
    if not ok then return nil end
    return { X = hit.Location.X, Y = hit.Location.Y, Z = hit.Location.Z }, hit.ImpactNormal.Z
end

local function placeCamp()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() then return log("kein PlayerController") end
    local pawn = pc.Pawn
    if not pawn or not pawn:IsValid() then return log("kein Pawn") end
    local loc = pawn:K2_GetActorLocation()
    local rot = pawn:K2_GetActorRotation()
    local fwd = pawn:GetActorForwardVector()
    local tx, ty = loc.X + fwd.X * 300, loc.Y + fwd.Y * 300
    local ground, normalZ = groundBelow(pawn, tx, ty, loc.Z)
    if not ground then
        log("kein Boden gefunden, nehme Spielerhöhe")
        ground = { X = tx, Y = ty, Z = loc.Z - 90 }
        normalZ = -1
    end
    log("Spieler %.0f/%.0f/%.0f, Ziel %.0f/%.0f/%.0f, Boden-Normale Z=%.2f", loc.X, loc.Y, loc.Z, ground.X, ground.Y, ground.Z, normalZ)
    local cls = getCampClass()
    if not cls then return log("GS_CampPlace_C nicht gefunden") end
    local camp = pawn:GetWorld():SpawnActor(cls, ground, { Pitch = 0, Yaw = rot.Yaw + 180, Roll = 0 })
    if camp and camp:IsValid() then
        table.insert(spawned, camp)
        log("Lagerplatz gesetzt: %s", camp:GetFullName())
    else
        log("SpawnActor fehlgeschlagen")
    end
end

local function removeCamps()
    local n = 0
    for _, camp in ipairs(spawned) do
        if camp:IsValid() then camp:K2_DestroyActor(); n = n + 1 end
    end
    spawned = {}
    log("%d gesetzte Lagerplätze entfernt", n)
end

local function countCamps()
    local all = FindAllOf("GS_CampPlace_C") or {}
    log("%d Lagerplätze in der Welt geladen", #all)
    for i, camp in ipairs(all) do
        if i > 5 then break end
        local l = camp:K2_GetActorLocation()
        log("  %s @ %.0f/%.0f/%.0f", camp:GetFullName(), l.X, l.Y, l.Z)
    end
end


-- Diagnose: Eigenschaften eines festen und des zuletzt gesetzten Lagerplatzes vergleichen (F9).
local SIMPLE = { BoolProperty = true, IntProperty = true, FloatProperty = true, ByteProperty = true, EnumProperty = true }
local NAMED = { NameProperty = true, StrProperty = true, TextProperty = true }

local function snapshot(obj)
    local out = {}
    local cls = obj:GetClass()
    while cls and cls:IsValid() do
        local cname = cls:GetFName():ToString()
        if cname == "Actor" or cname == "ActorComponent" or cname == "Object" then break end
        cls:ForEachProperty(function(prop)
            local name = prop:GetFName():ToString()
            local ptype = prop:GetClass():GetFName():ToString()
            local ok, v = pcall(function() return obj[name] end)
            if not ok then return end
            local val
            if SIMPLE[ptype] then
                val = tostring(v)
            elseif NAMED[ptype] then
                local ok2, str = pcall(function() return v:ToString() end)
                val = ok2 and str or "?"
            elseif ptype == "ObjectProperty" or ptype == "ClassProperty" then
                local ok2, str = pcall(function() return v:IsValid() and v:GetFName():ToString() or "nil" end)
                val = ok2 and str or "?"
            end
            if val then out[name] = val end
        end)
        cls = cls:GetSuperStruct()
    end
    return out
end

local function diff(label, a, b)
    local n = 0
    for k, va in pairs(a) do
        local vb = b[k]
        if vb ~= va then
            log("%s %s: fest=%s gesetzt=%s", label, k, va, tostring(vb))
            n = n + 1
        end
    end
    log("%s: %d Unterschiede", label, n)
end

local function compareCamps()
    local mine = spawned[#spawned]
    if not mine or not mine:IsValid() then return log("erst mit F7 einen Lagerplatz setzen") end
    local myloc = mine:K2_GetActorLocation()
    local best, bestD
    for _, camp in ipairs(FindAllOf("GS_CampPlace_C") or {}) do
        local isMine = false
        for _, s in ipairs(spawned) do if s:IsValid() and s:GetFullName() == camp:GetFullName() then isMine = true end end
        if not isMine then
            local l = camp:K2_GetActorLocation()
            local d = (l.X - myloc.X) ^ 2 + (l.Y - myloc.Y) ^ 2
            if not bestD or d < bestD then best, bestD = camp, d end
        end
    end
    if not best then return log("kein fester Lagerplatz geladen") end
    log("Vergleich fest=%s (%.0f m entfernt) mit gesetzt=%s", best:GetFullName(), math.sqrt(bestD) / 100, mine:GetFullName())
    diff("Lager", snapshot(best), snapshot(mine))
    if best.AC_Interactable:IsValid() and mine.AC_Interactable:IsValid() then
        diff("Interactable", snapshot(best.AC_Interactable), snapshot(mine.AC_Interactable))
    end
end

RegisterKeyBind(Key.F9, function() ExecuteInGameThread(compareCamps) end)

-- Versuch: Lager-Ressource wie die Adlerpfeife zum benutzbaren Gegenstand machen (Klassen-Vorlage zur Laufzeit ändern).
local RES_PACKAGE = "/Game/RPG_InventorySystem/Classes/MainItemClasses/SortedOtherItems/bonfire_resource"
local RES_CDO = RES_PACKAGE .. ".Default__bonfire_resource_C"

local function makeResourceUsable()
    local cdo = StaticFindObject(RES_CDO)
    if not cdo or not cdo:IsValid() then
        LoadAsset(RES_PACKAGE)
        cdo = StaticFindObject(RES_CDO)
    end
    if not cdo or not cdo:IsValid() then return log("bonfire_resource-Vorlage nicht gefunden") end
    log("bonfire_resource vorher: Type=%s Panel=%s", tostring(cdo.Type), tostring(cdo["Inventory Panel"]))
    -- Rückbau eines früheren Versuchs: Typ/Reiter-Änderung brachte das Inventar durcheinander (Händler buchte in die falsche Liste).
    -- Originalwerte: Type 0 (Sonstiges), Inventory Panel 3 (Reiter P3). Fürs Schnellmenü reicht das Stapel-Feld EquipmentSlot.
    cdo.Type = 0
    cdo["Inventory Panel"] = 3
    log("bonfire_resource nachher: Type=%s Panel=%s", tostring(cdo.Type), tostring(cdo["Inventory Panel"]))
end

local ok, err = pcall(function()
    RegisterHook("/Game/RPG_InventorySystem/UI/HUD/WB_ConsumableBarSlot.WB_ConsumableBarSlot_C:On Item Used", function(self)
        log("Schnellmenü-Platz benutzt: %s", self:get():GetFullName())
    end)
end)
if not ok then log("Hook On Item Used nicht gesetzt: %s", tostring(err)) end

ExecuteInGameThread(makeResourceUsable)

-- Schnellmenü: Pocket1..4 sind E_ItemSlot 9..12. Das Ablegen prüft nur das Stapel-Feld EquipmentSlot.
local F_ID = "ID_71_E0AE465E423DCDD08FF98D87A5C0B84F"
local F_SLOT = "EquipmentSlot_82_D8E166834B91EEF8631726AE76BDFFE0"
local F_QTY = "Quantity_76_AD4B883E4427C3E60B4B22B072F4E7C9"
local POCKET1 = 9

local function patchSupplyStacks()
    local inv = FindFirstOf("AC_PlayerInventory_C")
    if not inv or not inv:IsValid() then return log("AC_PlayerInventory nicht gefunden") end
    local n = 0
    for p = 1, 4 do
        local arr = inv["InventoryP" .. p]
        if arr then
            for i = 1, #arr do
                local it = arr[i]
                local ok, id = pcall(function() return it[F_ID]:ToString() end)
                if ok and id == "bonfire_resource" then
                    log("Lagervorräte in Reiter P%d Platz %d: Menge=%s EquipmentSlot=%s", p, i, tostring(it[F_QTY]), tostring(it[F_SLOT]))
                    it[F_SLOT] = POCKET1
                    log("  -> EquipmentSlot jetzt %s", tostring(it[F_SLOT]))
                    n = n + 1
                end
            end
        end
    end
    log("%d Lagervorräte-Stapel angepasst", n)
end
ExecuteInGameThread(patchSupplyStacks)
RegisterKeyBind(Key.F7, function() ExecuteInGameThread(placeCamp) end)
RegisterKeyBind(Key.F8, function() ExecuteInGameThread(removeCamps) end)
RegisterKeyBind(Key.F6, function() ExecuteInGameThread(countCamps) end)
log("geladen: F7 Lager setzen, F8 entfernen, F6 zählen, F9 vergleichen")

-- Schnellmenü-Benutzung erkennen: liegt im benutzten Pocket die Lagervorräte, Lager setzen (vorerst ohne Vorschau).
local function itemInPocket(slot)
    local eq = FindFirstOf("AC_PlayerEquipment_C")
    if not eq or not eq:IsValid() then return nil end
    local found
    local ok, err = pcall(function()
        eq["Equipment Data"]:ForEach(function(k, v)
            if k:get() == slot then found = v:get() end
        end)
    end)
    if not ok then log("Equipment Data nicht lesbar: %s", tostring(err)) end
    return found
end

local okHook, errHook = pcall(function()
    RegisterHook("/Game/RPG_InventorySystem/Blueprints/Components/AC_ConsumableBuffs.AC_ConsumableBuffs_C:Try to Use Consumable",
        function(self, slot, fromInventory)
            local s = slot:get()
            local it = itemInPocket(s)
            local id = "?"
            if it then pcall(function() id = it[F_ID]:ToString() end) end
            log("Try to Use Consumable: Slot=%s ausInventar=%s Item=%s", tostring(s), tostring(fromInventory:get()), id)
            if id == "bonfire_resource" then
                ExecuteInGameThread(function()
                    removeCamps()
                    placeCamp()
                end)
            end
        end)
end)
if not okHook then log("Hook Try to Use Consumable nicht gesetzt: %s", tostring(errHook)) end
