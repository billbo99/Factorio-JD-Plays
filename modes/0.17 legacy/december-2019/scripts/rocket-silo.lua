local RocketSilo = {}
local Events = require("utility/events")
local Utils = require("utility/utils")
local Constants = require("constants")
--local Logging = require("utility/logging")

local yChunkOffsetWeighting = 0.95
local yChunkStarting = math.floor(-5000 / 32)

RocketSilo.CreateGlobals = function()
    global.RocketSilo = global.RocketSilo or {}
end

RocketSilo.OnStartup = function()
    global.RocketSilo.targetChunkPosition = global.RocketSilo.targetChunkPosition or RocketSilo.CalculateRocketSiloTargetChunk()
end

RocketSilo.OnLoad = function()
    Events.RegisterHandler(defines.events.on_chunk_generated, "RocketSilo", RocketSilo.OnChunkGenerated)
end

RocketSilo.OnChunkGenerated = function(event)
    local generatedAreaTopLeftTile = event.area.left_top
    local generatedChunk = Utils.GetChunkPositionForTilePosition(generatedAreaTopLeftTile)
    if generatedChunk.x ~= global.RocketSilo.targetChunkPosition.x or generatedChunk.y ~= global.RocketSilo.targetChunkPosition.y then
        return
    end

    local surface = event.surface
    local middleTileInChunk = {x = generatedAreaTopLeftTile.x + 16, y = generatedAreaTopLeftTile.y + 16}
    local placementTestRocketSiloPrototypeName = Constants.ModName .. "-rocket_silo_place_test"
    local foundPosition = surface.find_non_colliding_position(placementTestRocketSiloPrototypeName, middleTileInChunk, 0, 1)

    local placementTestRocketSiloPrototype = game.entity_prototypes[placementTestRocketSiloPrototypeName]
    local entityFootprint = Utils.ApplyBoundingBoxToPosition(foundPosition, placementTestRocketSiloPrototype.collision_box)
    Utils.DestroyAllObjectsInArea(surface, entityFootprint)
    local rocketSiloEntity = surface.create_entity {name = "rocket-silo", position = foundPosition, force = "player"}
    rocketSiloEntity.minable = false
    rocketSiloEntity.destructible = false
end

RocketSilo.CalculateRocketSiloTargetChunk = function()
    local mapChunksWideFrom0 = math.floor((game.default_map_gen_settings.width / 32) / 2)
    local xChunk = math.random(-mapChunksWideFrom0, mapChunksWideFrom0)
    local yOffsetWeightings = {}
    local currentOffsetWeight = 1
    local currentOffsetChunk = 0
    while currentOffsetWeight > 0.1 do
        local positiveYChunkWeighting = {yChunk = yChunkStarting + currentOffsetChunk, chance = currentOffsetWeight}
        table.insert(yOffsetWeightings, positiveYChunkWeighting)
        if currentOffsetChunk > 0 then
            local negativeYChunkWeighting = {yChunk = yChunkStarting - currentOffsetChunk, chance = currentOffsetWeight}
            table.insert(yOffsetWeightings, negativeYChunkWeighting)
        end
        currentOffsetWeight = currentOffsetWeight * yChunkOffsetWeighting
        currentOffsetChunk = currentOffsetChunk + 1
    end
    yOffsetWeightings = Utils.NormaliseChanceList(yOffsetWeightings, "chance")
    local yChunk = Utils.GetRandomEntryFromNormalisedDataSet(yOffsetWeightings, "chance").yChunk
    local rocketSiloTargetChunk = {x = xChunk, y = yChunk}
    return rocketSiloTargetChunk
end

return RocketSilo
