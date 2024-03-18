--------------------------------------------------------------------------------
-- File: flood.lua
--
-- Author:  Daniel W (vulcan-dev)
-- Created: 2024/03/18 21:59:23
--------------------------------------------------------------------------------

require("multiplayer")

--[[
    TODO: Have an option to stop when every car is under the water, from singleplayer version:
    ```
    if M.presetData.stopWhenSubmerged then
        local veh = be:getPlayerVehicle(0)
        if not veh then return end

        local boundingBox = veh:getSpawnWorldOOBB()
        local halfExtentsZ = boundingBox:getHalfExtents().z
        local height = halfExtentsZ * 2
        local pos = veh:getPosition()

        if oceanHeight >= pos.z + height then
            M.presetData.enabled = false
        end
    end
    ```

    So when a vehicle is spawned, it will tell the server the height of the vehicle (obviously we trust the client, why wouldn't we)
]]

local M = {}

local UPDATE_TIME = 1000
--[[
    I recommend keeping it at 1000 for smoothness. With a low value like the old 25ms, it will appear jittery on the client because it's not predicting
    the server's next water level 100% accurately, and so if you have a low value, it will sort of snap to keep in sync. High values like 1000 (1s) are good because it keeps
    it all synced, but it keeps it nice and smooth on the clients, even at low framerates
]]

M.options = {
    oceanLevel = 0.0,
    floodSpeed = 0.001,
    limit = 0.0,
    limitEnabled = false,
    enabled = false,
    decrease = false,
    resetAt = 0.0 -- Doesn't reset everything, just the ocean level. Will be used for automatic flooding
}

M.isOceanValid = false
M.initialLevel = 0.0
M.commands = {}

local invalidCount = 0

local function setWaterLevel(level)
    if not M.isOceanValid then
        print("setWaterLevel: ocean is nil")
        return
    end

    MP.TriggerClientEvent(-1, "E_SetWaterLevel", tostring(level))
end

local function setFloodSpeed(client, speed)
    M.options.floodSpeed = speed
    MP.TriggerClientEvent(client, "E_SetFloodSpeed", tostring(speed))
end

local function sendServerState(client, level)
    MP.TriggerClientEvent(client, "E_SendServerState", tostring(level))
end

local function setEnabled(client, enabled)
    M.options.enabled = enabled
    MP.TriggerClientEvent(client, "E_SetEnabled", enabled and "1" or "0")
end

local function strToBool(str)
    str = string.lower(str)
    local boolVal

    if str == "1" or str == "true" or str == "on" then
        boolVal = true
    elseif str == "0" or str == "false" or str == "off" then
        boolVal = false
    else
        return nil
    end

    return boolVal
end

function onPlayerJoin(pid)
    local success = MP.TriggerClientEvent(pid, "E_OnPlayerLoaded", "")
    if not success then
        print("Failed to send \"E_OnPlayerLoaded\" to " .. pid)
    end

    sendServerState(pid, M.options.oceanLevel)
    setFloodSpeed(pid, M.options.floodSpeed)
    setEnabled(pid, M.options.enabled)

    MP.TriggerClientEvent(pid, "E_SetDecreasing", M.options.decrease and "1" or "0")
    MP.TriggerClientEvent(pid, "E_SetLimit", M.options.limitEnabled and tostring(M.options.limit) or "_") -- We send "_" because `tonumber` will return nil, meaning there's no limit on the client.
                                                                                                          -- I might send `limitEnabled`, I'm not sure yet since it's not really necessary.
    MP.TriggerClientEvent(pid, "E_SetResetAt", tostring(M.options.resetAt))
end

function onInit()
    MP.CancelEventTimer("ET_Update")

    for pid, player in pairs(MP.GetPlayers()) do
        onPlayerJoin(pid)
    end
end

function T_Update()
    if not M.isOceanValid or not M.options.enabled then return end

    local level = M.options.oceanLevel
    local changeAmount = UPDATE_TIME * M.options.floodSpeed
    local limit = M.options.limit
    local decrease = M.options.decrease
    local resetAt = M.options.resetAt

    -- Increase or decrease the level
    level = level + (decrease and -changeAmount or changeAmount)

    -- Reset at (0 = disabled)
    if resetAt ~= 0 and ((decrease and level <= resetAt) or (not decrease and level >= resetAt)) then
        level = M.initialLevel
    end

    local limitReached = false

    -- Limit the level
    if M.options.limitEnabled and ((decrease and level <= limit) or (not decrease and level >= limit)) then
        level = limit
        limitReached = true
    end
    
    M.options.oceanLevel = level

    sendServerState(-1, level)
    if limitReached then
        setEnabled(-1, false)
        MP.CancelEventTimer("ET_Update")
    end

    -- print("Server Level: " .. tonumber(level))
    -- setWaterLevel(level)
end

function E_OnInitialize(pid, waterLevel)
    waterLevel = tonumber(waterLevel) or nil

    -- Make sure the level has an ocean, we use "invalidCount" to make sure it's not just 1 player that doesn't have an ocean
    if not waterLevel and invalidCount < 2 then
        print("E_OnInitialize: waterLevel for player " .. GetPlayerName(pid) .. " is nil")
        invalidCount = invalidCount + 1
        return
    elseif not waterLevel and invalidCount >= 2 then
        print("This map doesn't have an ocean, disabling flood")
        M.isOceanValid = false
        return
    end

    M.isOceanValid = true
    if M.initialLevel == 0.0 then
        print("Setting initial water level to " .. waterLevel)
        M.initialLevel = waterLevel -- We sadly have to rely on the client 😅🔫

        sendServerState(-1, waterLevel) -- If we don't do this, the first client will see the water jump from 0 to the initialLevel.
    end
end

M.commands["start"] = function(pid)
    if not M.isOceanValid then
        MP.hSendChatMessage(pid, "This map doesn't have an ocean, unable to flood")
        return
    end

    if M.options.enabled then
        MP.hSendChatMessage(pid, "Flood has already started")
        return
    end

    setEnabled(-1, true)
    if M.options.oceanLevel == 0.0 then
        M.options.oceanLevel = M.initialLevel
    end
    
    MP.CreateEventTimer("ET_Update", UPDATE_TIME)
    MP.hSendChatMessage(-1, "A flood has started!")
end

M.commands["stop"] = function(pid)
    if not M.options.enabled then
        MP.hSendChatMessage(pid, "Flood is already stopped")
        return
    end

    MP.CancelEventTimer("ET_Update")
    setEnabled(-1, false)

    MP.hSendChatMessage(-1, "The flood has stopped!")
end

M.commands["reset"] = function(pid)
    if not M.isOceanValid then
        MP.hSendChatMessage(pid, "This map doesn't have an ocean, unable to flood")
        return
    end

    MP.CancelEventTimer("ET_Update")
    setEnabled(-1, false)
    sendServerState(-1, M.initialLevel)
    M.options.oceanLevel = M.initialLevel
    setWaterLevel(M.initialLevel)
end

M.commands["level"] = function(pid, level)
    level = tonumber(level) or nil
    if not level then
        MP.hSendChatMessage(pid, "Invalid level")
        return
    end

    if not M.isOceanValid then
        MP.hSendChatMessage(pid, "This map doesn't have an ocean, unable to flood")
        return
    end

    M.options.oceanLevel = level
    sendServerState(-1, level)
    setWaterLevel(level)
    MP.hSendChatMessage(pid, "Set water level to " .. level)
end

M.commands["speed"] = function(pid, speed)
    speed = tonumber(speed) or nil
    if not speed then
        MP.hSendChatMessage(pid, "Invalid speed")
        return
    end

    if speed < 0.0 then
        MP.hSendChatMessage(pid, "Speed can't be negative, setting to 0")
        speed = 0
    end

    setFloodSpeed(-1, speed)
    MP.hSendChatMessage(pid, "Set flood speed to " .. speed)
end

M.commands["limit"] = function(pid, limit)
    limit = tonumber(limit) or nil
    if limit then
        M.options.limit = limit
        MP.hSendChatMessage(pid, "Set flood limit to " .. limit)
    end

    M.options.limitEnabled = limit ~= nil
    if not M.options.limitEnabled then
        MP.hSendChatMessage(pid, "Disabled flood limit")
    end

    MP.TriggerClientEvent(-1, "E_SetLimit", tostring(limit))
end

M.commands["resetAt"] = function(pid, level)
    level = tonumber(level) or 0
    M.options.resetAt = level
    if level ~= 0 then
        MP.hSendChatMessage(pid, "Set reset level to " .. level)
    else
        MP.hSendChatMessage(pid, "Disabled reset at")
        level = 0
    end

    MP.TriggerClientEvent(-1, "E_SetResetAt", tostring(level))
end

M.commands["decrease"] = function(pid, enabled)
    if not enabled then
        MP.hSendChatMessage(pid, "Invalid value")
        return
    end

    local boolVal = strToBool(enabled)
    if boolVal == nil then
        MP.hSendChatMessage(pid, "Please use one of the following: (on, true, 1) or (off, false, 0)")
        return
    end

    enabled = boolVal

    M.options.decrease = enabled
    MP.TriggerClientEvent(-1, "E_SetDecreasing", enabled and "1" or "0")
    MP.hSendChatMessage(pid, "Set flood decrease to " .. tostring(enabled))
end

M.commands["printSettings"] = function(pid)
    for k, v in pairs(M.options) do
        MP.hSendChatMessage(pid, k .. ": " .. tostring(v))
    end
end

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("E_OnInitialize", "E_OnInitialize")
MP.RegisterEvent("ET_Update", "T_Update")

return M