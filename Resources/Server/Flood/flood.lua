require("multiplayer")

local M = {}

M.options = {
    oceanLevel = 0.0,
    floodSpeed = 0.001,
    limit = 0.0,
    limitEnabled = false,
    enabled = false,
    decrease = false,
    resetAt = 0.0, -- Doesn't reset everything, just the ocean level. Will be used for automatic flooding
    rainAmount = 0.0,
    rainVolume = -1.0, -- -1.0 = automatic, 0.0 = off, 1.0 = max
    floodWithRain = true
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

    -- Sync rain & volume
    if M.options.rainAmount > 0.0 then
        MP.TriggerClientEvent(pid, "E_SetRainAmount", tostring(M.options.rainAmount))
    end

    if M.options.rainVolume == -1.0 or M.options.rainVolume > 0.0 then
        MP.TriggerClientEvent(pid, "E_SetRainVolume", tostring(M.options.rainVolume))
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
    local changeAmount = M.options.floodSpeed
    local limit = M.options.limit
    local limitEnabled = M.options.limitEnabled
    local decrease = M.options.decrease

    -- If we have rain, add the rain amount to the change amount. The flood speed will now act as a multiplier.
    if M.floodWithRain then
        local rainAmount = M.options.rainAmount
        if rainAmount > 0.0 then
            changeAmount = changeAmount + rainAmount * 0.0001
        end
    end

    -- Increase or decrease the level
    if decrease then
        level = level - changeAmount
    else
        level = level + changeAmount
    end

    -- Reset at (0 = disabled)
    if M.options.resetAt > 0.0 and level >= M.options.resetAt then
        level = M.initialLevel
    elseif M.options.resetAt < 0.0 and level <= M.options.resetAt then
        level = M.initialLevel
    end

    -- Limit the level
    if limitEnabled then
        if decrease then
            if level < limit then
                level = limit
            end
        else
            if level > limit then
                level = limit
            end
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
    
    MP.CreateEventTimer("ET_Update", 25)

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
        MP.hSendChatMessage(pid, "Speed can't be negative, setting to 0.0")
        speed = 0.0
    end

    -- Do I limit the max? Hmmm, not sure 🤔

    M.options.floodSpeed = speed
    MP.hSendChatMessage(pid, "Set flood speed to " .. speed)
end

M.commands["limit"] = function(pid, limit)
    limit = tonumber(limit) or nil
    if not limit then
        MP.hSendChatMessage(pid, "Invalid limit")
        return
    end

    M.options.limit = limit
    MP.hSendChatMessage(pid, "Set flood limit to " .. limit)
end

M.commands["limitEnabled"] = function(pid, enabled)
    if not enabled then
        MP.hSendChatMessage(pid, "Invalid value")
        return
    end

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

M.commands["resetAt"] = function(pid, level)
    level = tonumber(level) or nil
    if not level then
        MP.hSendChatMessage(pid, "Invalid level")
        return
    end

    M.options.resetAt = level
    MP.hSendChatMessage(pid, "Set reset level to " .. level)
end

M.commands["rainAmount"] = function(pid, amount)
    amount = tonumber(amount) or nil
    if not amount then
        MP.hSendChatMessage(pid, "Invalid amount")
        return
    end

    M.options.rainAmount = amount
    MP.hSendChatMessage(pid, "Set rain amount to " .. amount)
    MP.TriggerClientEvent(-1, "E_SetRainAmount", tostring(amount))
    if M.options.rainVolume == -1 then -- Update the volume if it's set to auto
        MP.TriggerClientEvent(-1, "E_SetRainVolume", tostring(M.options.rainVolume))
    end
end

M.commands["rainVolume"] = function(pid, volume)
    volume = tonumber(volume) or nil
    if not volume then
        MP.hSendChatMessage(pid, "Invalid volume")
        return
    end

    M.options.rainVolume = volume
    MP.hSendChatMessage(pid, "Set rain volume to " .. volume)
    MP.TriggerClientEvent(-1, "E_SetRainVolume", tostring(volume))
end

M.commands["floodWithRain"] = function(pid, enabled)
    if not enabled then
        MP.hSendChatMessage(pid, "Invalid value")
        return
    end

    if string.lower(enabled) == "true" or enabled == "1" then
        enabled = true
    elseif string.lower(enabled) == "false" or enabled == "0" then
        enabled = false
    else
        MP.hSendChatMessage(pid, "Please use true/false or 1/0")
        return
    end

    M.options.floodWithRain = enabled
    MP.hSendChatMessage(pid, tostring(enabled and "Enabled" or "Disabled") .. " flooding with rain")
end

M.commands["decrease"] = function(pid, enabled)
    if not enabled then
        MP.hSendChatMessage(pid, "Invalid value")
        return
    end

    if string.lower(enabled) == "true" or enabled == "1" then
        enabled = true
    elseif string.lower(enabled) == "false" or enabled == "0" then
        enabled = false
    else
        MP.hSendChatMessage(pid, "Please use true/false or 1/0")
        return
    end

    if M.options.floodWithRain and M.options.rainAmount > 0.0 and enabled then
        MP.hSendChatMessage(pid, "What? You can't flood with rain and decrease at the same time!. Well, you can but I won't let you")
        return
    end

    M.options.decrease = enabled
    MP.hSendChatMessage(pid, "Set flood decrease to " .. tostring(enabled))
end

M.commands["printSettings"] = function(pid)
    for k, v in pairs(M.options) do
        MP.hSendChatMessage(pid, k .. ": " .. tostring(v))
    end
end

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onPlayerJoin", "onPlayerJoin")
MP.RegisterEvent("E_OnInitiliaze", "E_OnInitialize")
MP.RegisterEvent("ET_Update", "T_Update")
MP.CreateEventTimer("ET_Update", 25)

return M