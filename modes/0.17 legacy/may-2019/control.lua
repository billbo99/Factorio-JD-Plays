local BiterHuntGroup = require("modes/may-2019/biter-hunt-group")
local GUIUtil = require("utility/gui-util")
local Commands = require("utility/commands")
local testing = false

if settings.startup["jdplays_mode"].value ~= "may-2019" then
    return
end

local function ClearPlayerInventories(player)
    player.get_main_inventory().clear()
    player.get_inventory(defines.inventory.character_ammo).clear()
    player.get_inventory(defines.inventory.character_guns).clear()
end

local function OnPlayerCreated(event)
    local player = game.get_player(event.player_index)

    ClearPlayerInventories(player)
    player.insert {name = global.SpawnItems["gun"], count = 1}
    player.insert {name = global.SpawnItems["ammo"], count = 10}
    player.insert {name = "iron-plate", count = 8}
    player.insert {name = "wood", count = 1}
    player.insert {name = "burner-mining-drill", count = 1}
    player.insert {name = "stone-furnace", count = 1}

    if testing then
        player.insert {name = "grenade", count = 10}
        player.insert {name = "modular-armor", count = 1}
    end

    player.print({"messages.jd_plays-may-2019-welcome1"})
end

local function OnPlayerRespawned(event)
    local player = game.get_player(event.player_index)
    ClearPlayerInventories(player)
    player.insert {name = global.SpawnItems["gun"], count = 1}
    player.insert {name = global.SpawnItems["ammo"], count = 10}

    if testing then
        player.insert {name = "grenade", count = 10}
        player.insert {name = "modular-armor", count = 1}
    end
end

local function UpgradeOldGlobal()
    if global.biterHuntGroupTargetPlayer ~= nil then
        global.biterHuntGroupTargetPlayerID = global.biterHuntGroupTargetPlayer.index
        global.biterHuntGroupTargetPlayer = nil
    end
end

local function OnLoad()
    Commands.Register("biters_attack_now", {"api-description.jd_plays-may-2019_biters_attack_now"}, BiterHuntGroup.MakeBitersAttackNow, true)
end

local function OnStartup()
    UpgradeOldGlobal()
    global.SpawnItems = global.SpawnItems or {}
    global.SpawnItems["gun"] = global.SpawnItems["gun"] or "pistol"
    global.SpawnItems["ammo"] = global.SpawnItems["ammo"] or "firearm-magazine"
    global.BiterHuntGroupUnits = global.BiterHuntGroupUnits or {}
    global.BiterHuntGroupResults = global.BiterHuntGroupResults or {}
    global.biterHuntGroupId = global.biterHuntGroupId or 0
    if global.nextBiterHuntGroupTick == nil then
        global.nextBiterHuntGroupTick = game.tick
        BiterHuntGroup.ScheduleNextBiterHuntGroup()
    end
    BiterHuntGroup.GenerateOtherNextBiterHuntGroupData()
    OnLoad()
    GUIUtil.CreateAllPlayersElementReferenceStorage()
    BiterHuntGroup.GuiRecreateAll()
end

local function OnResearchFinished(event)
    local technology = event.research
    if technology.name == "military" then
        global.SpawnItems["gun"] = "submachine-gun"
    elseif technology.name == "military-2" then
        global.SpawnItems["ammo"] = "piercing-rounds-magazine"
    elseif technology.name == "uranium-ammo" then
        global.SpawnItems["ammo"] = "uranium-rounds-magazine"
    end
end

local function OnPlayerJoinedGame(event)
    local player = game.get_player(event.player_index)
    BiterHuntGroup.GuiRecreate(player)
end

local function On10Ticks(event)
    local tick = event.tick
    BiterHuntGroup.On10Ticks(tick)
end

local function OnPlayerDied(event)
    BiterHuntGroup.PlayerDied(event.player_index)
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_load(OnLoad)
script.on_event(defines.events.on_player_created, OnPlayerCreated)
script.on_event(defines.events.on_player_respawned, OnPlayerRespawned)
script.on_event(defines.events.on_research_finished, OnResearchFinished)
script.on_event(defines.events.on_player_joined_game, OnPlayerJoinedGame)
script.on_event(defines.events.on_player_died, OnPlayerDied)
script.on_nth_tick(10, On10Ticks)
