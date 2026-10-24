-- Camp Everywhere (Smart Resting) for Of Ash and Steel - UE4SS Lua mod
--
-- Put Camp Supplies on one of the four quick slots and press its key: a ghost of the camp fire ring
-- appears in front of you, green where you can camp and red where you can't. Press the key again to make
-- camp there (green) or to cancel (red). You only ever have one camp; a new one replaces the old one and
-- camps are not saved. Making camp itself is the game's own logic: same prompt, Survival skill, one Camp
-- Supplies per camp, same camp menu.
local UEHelpers = require("UEHelpers")

local VERSION = "1.0.0"

-- Settings (distances in cm)
local CFG = {
    distance = 300,             -- how far in front of you the camp is placed
    maxSlope = 0.85,            -- minimum Z of the ground normal (about 32 degrees)
    maxStep = 250,              -- max. height difference between your feet and the camp spot
    roofHeight = 1500,          -- this much free space above the camp spot (trees don't count)
    townNpcs = 3,               -- this many people nearby make a place a settlement ...
    townNpcRadius = 2500,       -- ... within this radius
    townBuildingRadius = 1200,  -- buildings are searched in 8 directions within this radius ...
    townBuildingHits = 2,       -- ... and this many directions must hit one
    tickMs = 50,                -- ghost update interval (ms)
    slowCheckEvery = 10,        -- enemy and settlement checks only every n-th update
    alpha = 0.22,               -- average ghost opacity
    pulse = 0.08,               -- opacity pulses by +/- this much
    debug = false,              -- write the reason for red into UE4SS.log
}

local P = {
    campClass = "/Game/RPG_InventorySystem/Classes/Interactable/GS_CampPlace.GS_CampPlace_C",
    stones = "/Game/Models/Grayshaft_Camp/gs_camp_stones",
    ghostMat = "/Engine/EngineDebugMaterials/M_SimpleUnlitTranslucent",
    checks = "/Game/DialogsAndQuests/Quests/BP/QuestSystem_Checks.Default__QuestSystem_Checks_C",
    useHook = "/Game/RPG_InventorySystem/Blueprints/Components/AC_ConsumableBuffs.AC_ConsumableBuffs_C:Try to Use Consumable",
    addHook = "/Game/RPG_InventorySystem/Blueprints/Components/AC_InventoryCore.AC_InventoryCore_C:Add Item to Inventory Array",
}

local SUPPLY_ID = "bonfire_resource" -- Camp Supplies
local F_ID = "ID_71_E0AE465E423DCDD08FF98D87A5C0B84F"
local F_SLOT = "EquipmentSlot_82_D8E166834B91EEF8631726AE76BDFFE0"
local POCKET1 = 9 -- E_ItemSlot: Pocket1..4 = 9..12, the four quick slots

local GREEN = { R = 0.4, G = 1.0, B = 0.7 } -- pale ghost green
local RED = { R = 1.0, G = 0.35, B = 0.3 }  -- pale red
local NO_COLOR = { R = 0, G = 0, B = 0, A = 0 }

local TREE_WORDS = { "foliage", "tree", "pine", "spruce", "oak", "birch", "bush", "leaf", "leaves", "branch", "willow" }
local WATER_WORDS = { "water", "ocean", "river", "lake", "swim" }
local BUILDING_WORDS = { "building", "house", "hut", "tavern", "barn", "smithy", "shop", "stall", "market", "archway", "church", "chapel", "mill" }

local state = { placing = false, parts = {}, mids = {}, valid = nil, reason = "", loc = nil, yaw = 0, noDanger = true, town = nil, n = 0 }
local camp = nil

local function log(fmt, ...)
    print("[CampEverywhere] " .. string.format(fmt, ...) .. "\n")
end

local function dbg(fmt, ...)
    if CFG.debug then log(fmt, ...) end
end

-- "/Game/Path/Name" -> object "/Game/Path/Name.Name" (LoadAsset needs the full object path)
local function loadAsset(pkg)
    local full = pkg .. "." .. pkg:match("([^/]+)$")
    local obj = StaticFindObject(full)
    if obj and obj:IsValid() then return obj end
    pcall(LoadAsset, full)
    obj = StaticFindObject(full)
    if obj and obj:IsValid() then return obj end
    log("asset not found: %s", full)
    return nil
end

local function campClass()
    local cls = StaticFindObject(P.campClass)
    if cls and cls:IsValid() then return cls end
    pcall(LoadAsset, P.campClass)
    cls = StaticFindObject(P.campClass)
    if cls and cls:IsValid() then return cls end
    return nil
end

local function playerAndCamera()
    local pc = UEHelpers.GetPlayerController()
    if not pc or not pc:IsValid() then return nil end
    local pawn = pc.Pawn
    if not pawn or not pawn:IsValid() then return nil end
    return pawn, pc.PlayerCameraManager
end

local function trace(pawn, from, to, ignore)
    local hit = {}
    local ok, res = pcall(function()
        return UEHelpers.GetKismetSystemLibrary():LineTraceSingle(pawn, from, to, 0, false, ignore, 0, hit, true, NO_COLOR, NO_COLOR, 0.0)
    end)
    if ok and res then return hit end
    return nil
end

local function hitNames(hit)
    local s = ""
    pcall(function()
        local a = UEHelpers.GetActorFromHitResult(hit)
        if a and a:IsValid() then s = a:GetFullName() end
        local c = hit.Component:Get()
        if c and c:IsValid() then s = s .. " | " .. c:GetFullName() end
    end)
    return s
end

local function matchesAny(s, words)
    local l = s:lower()
    for _, w in ipairs(words) do
        if l:find(w, 1, true) then return true end
    end
    return false
end

-- Settlement: enough people nearby (Base_NPC_* classes; animals don't count) or buildings all around.
local function settlement(pawn, p)
    local npcs = 0
    for _, st in ipairs(FindAllOf("AI_Stats_C") or {}) do
        local ok, owner = pcall(function() return st:GetOwner() end)
        if ok and owner and owner:IsValid() and owner:GetClass():GetFName():ToString():sub(1, 9) == "Base_NPC_" then
            local l = owner:K2_GetActorLocation()
            if (l.X - p.X) ^ 2 + (l.Y - p.Y) ^ 2 < CFG.townNpcRadius ^ 2 then npcs = npcs + 1 end
        end
    end
    if npcs >= CFG.townNpcs then return string.format("settlement (%d people nearby)", npcs) end
    local hits = 0
    for i = 0, 7 do
        local r = math.rad(i * 45)
        local hit = trace(pawn, { X = p.X, Y = p.Y, Z = p.Z + 120 },
            { X = p.X + math.cos(r) * CFG.townBuildingRadius, Y = p.Y + math.sin(r) * CFG.townBuildingRadius, Z = p.Z + 120 }, {})
        if hit and matchesAny(hitNames(hit), BUILDING_WORDS) then hits = hits + 1 end
    end
    if hits >= CFG.townBuildingHits then return string.format("settlement (buildings in %d directions)", hits) end
    return nil
end

-- The same enemy check the game's camp spots use.
local dangerWarned = false
local function noDanger(pawn)
    local checks = StaticFindObject(P.checks)
    if not checks or not checks:IsValid() then return true end
    local out = {}
    local ok, r = pcall(function() return checks:QS_CheckDanger(pawn, out) end)
    if not ok then
        if not dangerWarned then log("QS_CheckDanger not callable: %s", tostring(r)); dangerWarned = true end
        return true
    end
    local v = out.NoDanger
    if type(v) ~= "boolean" then v = r end
    if type(v) ~= "boolean" then return true end
    return v
end

-- Spot in front of the player (camera direction), the ground below it, and whether it is a valid camp spot.
local function evaluate(pawn, cam)
    local loc = pawn:K2_GetActorLocation()
    local camYaw = cam:GetCameraRotation().Yaw
    local rad = math.rad(camYaw)
    local tx, ty = loc.X + math.cos(rad) * CFG.distance, loc.Y + math.sin(rad) * CFG.distance
    local ignore = {}
    if camp and camp:IsValid() then table.insert(ignore, camp) end
    local yaw = camYaw + 180 -- the camp faces the player
    local hit = trace(pawn, { X = tx, Y = ty, Z = loc.Z + 150 }, { X = tx, Y = ty, Z = loc.Z - 1000 }, ignore)
    if not hit then return nil, yaw, false, "no ground" end
    local g = { X = hit.Location.X, Y = hit.Location.Y, Z = hit.Location.Z }
    if hit.ImpactNormal.Z < CFG.maxSlope then
        return g, yaw, false, string.format("too steep (normal %.2f)", hit.ImpactNormal.Z)
    end
    if math.abs(g.Z - (loc.Z - 90)) > CFG.maxStep then return g, yaw, false, "height difference too big" end
    local ground = hitNames(hit)
    if matchesAny(ground, WATER_WORDS) then return g, yaw, false, "water: " .. ground end
    local swimming = false
    pcall(function() swimming = pawn.CharacterMovement:IsSwimming() end)
    if swimming then return g, yaw, false, "player is swimming" end
    local up = trace(pawn, { X = g.X, Y = g.Y, Z = g.Z + 100 }, { X = g.X, Y = g.Y, Z = g.Z + CFG.roofHeight }, ignore)
    if up then
        local name = hitNames(up)
        if not matchesAny(name, TREE_WORDS) then return g, yaw, false, "roof: " .. name end
    end
    if state.town then return g, yaw, false, state.town end
    if not state.noDanger then return g, yaw, false, "enemies nearby" end
    return g, yaw, true, "ok"
end

-- Ghost: just the fire ring (that's what a camp spot looks like in the world), translucent green/red.
local function clearGhost()
    for _, a in ipairs(state.parts) do
        if a:IsValid() then a:K2_DestroyActor() end
    end
    state.parts, state.mids, state.valid = {}, {}, nil
end

local function makeGhost(pawn)
    clearGhost()
    local world = pawn:GetWorld()
    local smaClass = StaticFindObject("/Script/Engine.StaticMeshActor")
    local mat = loadAsset(P.ghostMat)
    local mesh = loadAsset(P.stones)
    if not mesh then return end
    local a = world:SpawnActor(smaClass, { X = 0, Y = 0, Z = -100000 }, { Pitch = 0, Yaw = 0, Roll = 0 })
    if not a or not a:IsValid() then return end
    a:SetActorEnableCollision(false)
    local c = a.StaticMeshComponent
    c:SetMobility(2) -- Movable
    c:SetStaticMesh(mesh)
    c:SetCastShadow(false)
    if mat then
        local mid = c:CreateDynamicMaterialInstance(0, mat, FName("CampGhost"))
        for m = 0, c:GetNumMaterials() - 1 do c:SetMaterial(m, mid) end
        table.insert(state.mids, mid)
    end
    table.insert(state.parts, a)
end

local function moveGhost(g, yaw)
    for _, a in ipairs(state.parts) do
        if a:IsValid() then
            a:K2_SetActorLocation(g, false, {}, false)
            a:K2_SetActorRotation({ Pitch = 0, Yaw = yaw, Roll = 0 }, false)
        end
    end
end

local function setColor(valid)
    state.valid = valid
    local c = valid and GREEN or RED
    local color = { R = c.R, G = c.G, B = c.B, A = CFG.alpha + CFG.pulse * math.sin(state.n * 0.3) }
    for _, mid in ipairs(state.mids) do
        pcall(function() mid:SetVectorParameterValue(FName("Color"), color) end)
    end
end

local function cancel(why)
    clearGhost()
    state.placing = false
    dbg("placement cancelled (%s)", why or "")
end

local function tick()
    if not state.placing then return end
    local pawn, cam = playerAndCamera()
    if not pawn then return cancel("no player") end
    state.n = state.n + 1
    if state.n % CFG.slowCheckEvery == 1 then
        state.noDanger = noDanger(pawn)
        local g0 = evaluate(pawn, cam)
        state.town = g0 and settlement(pawn, g0) or nil
    end
    local g, yaw, ok, reason = evaluate(pawn, cam)
    state.loc, state.yaw = g, yaw
    if g then moveGhost(g, yaw) end
    setColor(ok and g ~= nil)
    if reason ~= state.reason then
        dbg("ghost: %s", reason)
        state.reason = reason
    end
end

local function startPlacing()
    local pawn = playerAndCamera()
    if not pawn then return end
    makeGhost(pawn)
    state.placing, state.reason, state.n, state.valid, state.loc, state.town = true, "", 0, nil, nil, nil
    dbg("placement started")
end

local function confirm()
    if not state.valid or not state.loc then return cancel(state.reason) end
    local pawn = playerAndCamera()
    local cls = campClass()
    if not pawn or not cls then return cancel("camp spot class missing") end
    if camp and camp:IsValid() then camp:K2_DestroyActor() end
    camp = pawn:GetWorld():SpawnActor(cls, state.loc, { Pitch = 0, Yaw = state.yaw, Roll = 0 })
    clearGhost()
    state.placing = false
    if camp and camp:IsValid() then dbg("camp placed: %s", camp:GetFullName()) else log("could not place camp") end
end

LoopAsync(CFG.tickMs, function()
    if state.placing then
        ExecuteInGameThread(function()
            local ok, err = pcall(tick)
            if not ok then
                log("ghost error: %s", tostring(err))
                cancel("error")
            end
        end)
    end
    return false
end)

-- Make Camp Supplies quick-slot capable: the quick slots only check the stack's EquipmentSlot field (Pocket).
local function patchSupplyStacks()
    local inv = FindFirstOf("AC_PlayerInventory_C")
    if not inv or not inv:IsValid() then return end
    for p = 1, 4 do
        local arr = inv["InventoryP" .. p]
        if arr then
            for i = 1, #arr do
                local it = arr[i]
                local ok, id = pcall(function() return it[F_ID]:ToString() end)
                if ok and id == SUPPLY_ID and it[F_SLOT] == 0 then
                    it[F_SLOT] = POCKET1
                    dbg("Camp Supplies (tab P%d) can now go on a quick slot", p)
                end
            end
        end
    end
end

local function itemInPocket(slot)
    local eq = FindFirstOf("AC_PlayerEquipment_C")
    if not eq or not eq:IsValid() then return nil end
    local found
    pcall(function()
        eq["Equipment Data"]:ForEach(function(k, v)
            if k:get() == slot then found = v:get() end
        end)
    end)
    return found
end

-- Using a quick slot: the game gives up on Camp Supplies (not a consumable), so nothing is used up here.
local okUse, errUse = pcall(function()
    RegisterHook(P.useHook, function(self, slot)
        local it = itemInPocket(slot:get())
        local id
        if it then pcall(function() id = it[F_ID]:ToString() end) end
        if id ~= SUPPLY_ID then return end
        ExecuteInGameThread(function()
            if state.placing then confirm() else startPlacing() end
        end)
    end)
end)
if not okUse then log("quick slot hook missing: %s", tostring(errUse)) end

local okAdd, errAdd = pcall(function()
    RegisterHook(P.addHook, function()
        ExecuteWithDelay(300, function() ExecuteInGameThread(patchSupplyStacks) end)
    end)
end)
if not okAdd then log("inventory hook missing: %s", tostring(errAdd)) end

pcall(function()
    RegisterLoadMapPostHook(function()
        state.placing = false
        state.parts, state.mids = {}, {}
        camp = nil
        ExecuteWithDelay(5000, function() ExecuteInGameThread(patchSupplyStacks) end)
    end)
end)

ExecuteInGameThread(patchSupplyStacks)
log("v%s loaded", VERSION)
