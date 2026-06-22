local Settings = require 'shared.settings'

local Pings = {}
local PlayerGroups = {}
local lastRequestTimers = {}

local function GetPlayerGang(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end

    local citizenid = player.PlayerData.citizenid

    if IsResourceActive('origen_ilegal') then
        return exports.origen_ilegal:GetGangID(src)
    elseif IsResourceActive('origen_ilegalv2') then
        local gang = exports.origen_ilegalv2:GetPlayerGangByCid(citizenid)
        return gang and gang.id
    elseif IsResourceActive('op-crime') then
        local org = exports['op-crime']:getPlayerOrganisation(citizenid)
        return org and org.orgData and org.orgData.label
    elseif IsResourceActive('rcore_gangs') then
        local gang = exports.rcore_gangs:GetPlayerGang(src)
        return gang and gang.name
    end

    return player.PlayerData.gang and player.PlayerData.gang.name
end

local function CachePlayer(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    PlayerGroups[src] = {
        job = player.PlayerData.job and player.PlayerData.job.name,
        gang = GetPlayerGang(src)
    }
end

local function RemovePlayer(src)
    PlayerGroups[src] = nil
    Pings[src] = nil
end

local function SharesGroup(a, b)
    local groupA = PlayerGroups[a]
    local groupB = PlayerGroups[b]

    if not groupA or not groupB then
        return false
    end

    if groupA.job and groupA.job == groupB.job then
        return true
    end

    if groupA.gang and groupA.gang == groupB.gang then
        return true
    end

    return false
end

local function SendPing(owner, coords)
    local ownerPed = GetPlayerPed(owner)

    if ownerPed == 0 then
        return
    end

    local ownerCoords = GetEntityCoords(ownerPed)

    local players = GetPlayers()

    for i = 1, #players do
        local target = tonumber(players[i])

        if target ~= owner and SharesGroup(owner, target) then
            local targetPed = GetPlayerPed(target)

            if targetPed ~= 0 then
                local targetCoords = GetEntityCoords(targetPed)

                if #(ownerCoords - targetCoords) <= Settings.RenderDistance then
                    Client('addPing', target, owner, coords)
                end
            end
        end
    end
end

local function RemovePing(owner)
    local players = GetPlayers()

    for i = 1, #players do
        local target = tonumber(players[i])

        if target ~= owner and SharesGroup(owner, target) then
            Client('removePing', target, owner)
        end
    end
end

Register('createPing', function(coords)
    local src = source
    local lastTimer = lastRequestTimers[src]

    if lastTimer and (GetGameName - lastRequestTimers[src]) < Settings.Cooldown then return end

    Pings[src] = coords

    SendPing(src, coords)
end)

Register('removePing', function()
    local src = source

    if not Pings[src] then
        return
    end

    Pings[src] = nil

    RemovePing(src)
end)

AddEventHandler('playerDropped', function()
    local src = source

    if Pings[src] then
        RemovePing(src)
    end

    RemovePlayer(src)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(source)
    CachePlayer(source)
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    local data = PlayerGroups[source]

    if not data then
        CachePlayer(source)
        return
    end

    data.job = job.name
end)

AddEventHandler('QBCore:Server:OnGangUpdate', function(source, gang)
    local data = PlayerGroups[source]

    if not data then
        CachePlayer(source)
        return
    end

    data.gang = gang.name
end)

CreateThread(function()
    local players = GetPlayers()

    for i = 1, #players do
        local target = tonumber(players[i])

        CachePlayer(target)
    end
end)
