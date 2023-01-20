require("multiplayer")

local M = {}

M.options = {
    oceanLevel = 0.0,
    floodSpeed = 0.001,
    limit = 0.0,
    limitEnabled = false,
    enabled = false,
    decrease = false
}

M.isOceanValid = false
M.initialLevel = 0.0
M.commands = {}

local invalidCount = 0

function onPlayerJoin(pid)
    local success = MP.TriggerClientEvent(pid, "E_OnPlayerLoaded", "")
    if not success then
        print("Failed to send \"E_OnPlayerLoaded\" to " .. pid)
    end
end

function onInit()
    MP.CancelEventTimer("ET_Update")

    for pid, player in pairs(MP.GetPlayers()) do
        onPlayerJoin(pid)
    end
end

local function setWaterLevel(level)
    if not M.isOceanValid then
        print("setWaterLevel: ocean is nil")
        return
    end

    MP.TriggerClientEvent(-1, "E_SetWaterLevel", tostring(level))
end

function T_Update()
    if not M.isOceanValid or not M.options.enabled then return end

    local level = M.options.oceanLevel
    local speed = M.options.floodSpeed
    local limit = M.options.limit
    local limitEnabled = M.options.limitEnabled
    local decrease = M.options.decrease

    -- Check if we can change the level
    local canChange = true
    if limitEnabled then
        if decrease then
            if level - speed < limit then
                canChange = false
            end
        else
            if level + speed > limit then
                canChange = false
            end
        end
    end

    if canChange then
        if decrease then
            level = level - speed
        else
            level = level + speed
        end
    end

    M.options.oceanLevel = level
    setWaterLevel(level)
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
    
    M.options.enabled = true
    if M.options.oceanLevel == 0.0 then
        M.options.oceanLevel = M.initialLevel
    end
    
    MP.CreateEventTimer("ET_Update", 100)

    MP.hSendChatMessage(-1, "A flood has started!")
end

M.commands["stop"] = function(pid)
    if not M.options.enabled then
        MP.hSendChatMessage(pid, "Flood is already stopped")
        return
    end

    MP.CancelEventTimer("ET_Update")
    M.options.enabled = false
    MP.hSendChatMessage(-1, "The flood has stopped!")
end

M.commands["reset"] = function(pid)
    if not M.isOceanValid then
        MP.hSendChatMessage(pid, "This map doesn't have an ocean, unable to flood")
        return
    end

    MP.CancelEventTimer("ET_Update")
    M.options.enabled = false
    M.options.oceanLevel = M.initialLevel
    setWaterLevel(M.initialLevel)
end

M.commands["setLevel"] = function(pid, level)
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
    setWaterLevel(level)
    MP.hSendChatMessage(pid, "Set water level to " .. level)
end

M.commands["setSpeed"] = function(pid, speed)
    speed = tonumber(speed) or nil
    if not speed then
        MP.hSendChatMessage(pid, "Invalid speed")
        return
    end

    M.options.floodSpeed = speed
    MP.hSendChatMessage(pid, "Set flood speed to " .. speed)
end

M.commands["setLimit"] = function(pid, limit)
    limit = tonumber(limit) or nil
    if not limit then
        MP.hSendChatMessage(pid, "Invalid limit")
        return
    end

    M.options.limit = limit
    MP.hSendChatMessage(pid, "Set flood limit to " .. limit)
end

M.commands["setLimitEnabled"] = function(pid, enabled)
    print("flood_setLimitEnabled: " .. enabled)
    if string.lower(enabled) == "true" or enabled == "1" then
        enabled = true
    elseif string.lower(enabled) == "false" or enabled == "0" then
        enabled = false
    else
        MP.hSendChatMessage(pid, "Please use true/false or 1/0")
        return
    end

    M.options.limitEnabled = enabled
    MP.hSendChatMessage(pid, tostring(enabled and "Enabled" or "Disabled") .. " flood limit")
end

M.commands["printSettings"] = function(pid)
    MP.hSendChatMessage(pid, "Level: " .. M.options.oceanLevel)
    MP.hSendChatMessage(pid, "Speed: " .. M.options.floodSpeed)
    MP.hSendChatMessage(pid, "Limit: " .. M.options.limit)
    MP.hSendChatMessage(pid, "Limit enabled: " .. tostring(M.options.limitEnabled))
    MP.hSendChatMessage(pid, "Decrease: " .. tostring(M.options.decrease))
    MP.hSendChatMessage(pid, "Flooding: " .. tostring(M.options.enabled))
end

M.commands["setDecrease"] = function(pid, enabled)
    if string.lower(enabled) == "true" or enabled == "1" then
        enabled = true
    elseif string.lower(enabled) == "false" or enabled == "0" then
        enabled = false
    else
        MP.hSendChatMessage(pid, "Please use true/false or 1/0")
        return
    end

    M.options.decrease = enabled
    MP.hSendChatMessage(pid, "Set flood decrease to " .. tostring(enabled))
end

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("E_OnInitiliaze", "E_OnInitialize")
MP.RegisterEvent("ET_Update", "T_Update")
MP.CreateEventTimer("ET_Update", 100)

return M