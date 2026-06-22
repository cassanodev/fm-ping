local Settings = require('shared.settings')

local lib = lib
local cache = cache

local DrawMarker = DrawMarker
local GetEntityCoords = GetEntityCoords

local currentPing
local otherPings = {}

local loopCreated = false

local marker = Settings.Marker

local minMultiplier = 0.5
local maxMultiplier = 2.0

local function DrawPing(coords, playerCoords)
    local distance = #(coords - playerCoords)

    local multiplier = minMultiplier +
        ((distance / Settings.RenderDistance) * (maxMultiplier - minMultiplier))

    DrawMarker(
        marker.type,
        coords.x,
        coords.y,
        coords.z,

        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,

        marker.scale.x * multiplier,
        marker.scale.y * multiplier,
        marker.scale.z * multiplier,

        marker.color.r,
        marker.color.g,
        marker.color.b,
        marker.color.a,

        false,
        true,
        2,
        false,

        nil,
        nil,
        false
    )
end

local function createLoop()
    if loopCreated then
        return
    end

    loopCreated = true

    CreateThread(function()
        while currentPing or next(otherPings) do
            local playerCoords = cache.coords

            if not playerCoords then
                playerCoords = GetEntityCoords(cache.ped)
            end

            if currentPing then
                if #(currentPing - playerCoords) <= Settings.RenderDistance then
                    DrawPing(currentPing, playerCoords)
                end
            end

            for _, coords in pairs(otherPings) do
                if #(coords - playerCoords) <= Settings.RenderDistance then
                    DrawPing(coords, playerCoords)
                end
            end

            Wait(0)
        end

        loopCreated = false
    end)
end

local function RemovePing()
    currentPing = nil
    Server('removePing')
end

local function CreatePing(coords)
    currentPing = coords

    createLoop()
    Server('createPing', coords)
end

local function IsSameLocation(a, b)
    return a and b and #(a - b) < 4.0
end

local lastPingTime

lib.addKeybind({
    name = 'ping',
    description = 'Ping',
    defaultKey = 'G',
    allowInPauseMenu = false,

    onPressed = function()
        if (
                GetResourceState('wasabi_ambulance') ~= 'missing'
                and exports.wasabi_ambulance:isPlayerDead()
            ) or IsPedDeadOrDying(cache.ped, false) then
            return
        end

        if lastPingTime and (GetGameTimer() - lastPingTime) < (Settings.Cooldown * 1000) then
            return
        end

        local hit, _, coords = lib.raycast.fromCamera(
            511,
            4,
            Settings.MaxDistance
        )

        if not hit then
            return
        end

        local pingCoords = vec3(coords.x, coords.y, coords.z + 0.5)

        if currentPing and IsSameLocation(currentPing, pingCoords) then
            RemovePing()
            return
        end

        lastPingTime = GetGameTimer()

        CreatePing(pingCoords)
    end
})

Register('addPing', function(owner, coords)
    otherPings[owner] = vec3(
        coords.x,
        coords.y,
        coords.z 
    )

    createLoop()
end)

Register('removePing', function(owner)
    otherPings[owner] = nil
end)
