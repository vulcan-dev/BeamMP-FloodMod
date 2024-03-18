--------------------------------------------------------------------------------
-- File: floodBeamMP.lua
--
-- Author:  Daniel W (vulcan-dev)
-- Created: 2024/03/18 21:59:10
--------------------------------------------------------------------------------

local M = {}

local ocean = nil
local calledOnInit = false

-- TODO: Move into a table
local enabled = false
local serverWaterLevel = nil
local floodSpeed = nil
local decreasing = false

local limit = nil
local resetAt = nil

----------------------------------------------
-- Utility Functions
local function findObject(objectName, className)
    local obj = scenetree.findObject(objectName)
    if obj then return obj end
    if not className then return nil end

    local objects = scenetree.findClassObjects(className)
    for _, name in pairs(objects) do
        local object = scenetree.findObject(name)
        if string.find(name, objectName) then return object end
    end

    return
end

local function tableToMatrix(tbl)
    local mat = MatrixF(true)
    mat:setColumn(0, tbl.c0)
    mat:setColumn(1, tbl.c1)
    mat:setColumn(2, tbl.c2)
    mat:setColumn(3, tbl.c3)
    return mat
end

local function getWaterLevel()
    if not ocean then return nil end
    return ocean.position:getColumn(3).z
end

local function setWaterLevel(level)
    if not ocean then log("W", "setWaterLevel", "M.ocean is nil") return end
    local c3 = ocean.position:getColumn(3)
    ocean.position = tableToMatrix({
        c0 = ocean.position:getColumn(0),
        c1 = ocean.position:getColumn(1),
        c2 = ocean.position:getColumn(2),
        c3 = vec3(c3.x, c3.y, level)
    })

    -- log('D', "setWaterLevel", string.format("level: %.6f, serverWaterLevel: %.6f", level, serverWaterLevel))
end

AddEventHandler("E_OnPlayerLoaded", function()
    ocean = findObject("Ocean", "WaterPlane")

    if calledOnInit then return end -- Since you can disable the Lua reloading in BeamMP, I don't want it to trigger this server event multiple times if you reconnect.
                                    -- Then again, I could set the extension mode to auto (or just manually unload it when you exit the server). I'll leave it as is for now since it worked when I last checked.
    TriggerServerEvent("E_OnInitialize", tostring(getWaterLevel()))
    calledOnInit = true
end)

AddEventHandler("E_SetWaterLevel", function(level)
    setWaterLevel(tonumber(level))
end)

AddEventHandler("E_SendServerState", function(level) serverWaterLevel = tonumber(level) end)
AddEventHandler("E_SetEnabled", function(strEnabled) enabled = strEnabled == "1" end)
AddEventHandler("E_SetFloodSpeed", function(speed) floodSpeed = tonumber(speed) end)
AddEventHandler("E_SetDecreasing", function(value) decreasing = value == "1" end)
AddEventHandler("E_SetLimit", function(value) limit = tonumber(value) end)
AddEventHandler("E_SetResetAt", function(value) resetAt = tonumber(value) or 0 end)

local function onUpdate(dt)
    if not enabled or not serverWaterLevel then return end

    local currentLevel = getWaterLevel()

    -- Update the water level and use exponential decay for smoothing
    local newLevel = currentLevel + (serverWaterLevel - currentLevel) * (1 - math.exp(-dt / 0.01)) -- TODO: Remove magic number

    if math.abs(newLevel - serverWaterLevel) > 0.075 then -- Some threshold that seems to work, need to play around with it more.
        newLevel = serverWaterLevel
        -- log('D', "onUpdate", "snapping from " .. tostring(newLevel) .. " to " .. tostring(serverWaterLevel))
    end

    -- Check resetAt & limit. We do the check on the server as well, but if the server updates every 1s, it will overshoot the target.
    -- Since we now check it on the client, it will just wait for the server to catch up and reset it for everyone. I could improve this and make it reset instantly after 2 or more people
    -- reach the target, but I don't see the point.

    -- Reset at (0 = disabled)
    if resetAt ~= 0 and ((decreasing and newLevel <= resetAt) or (not decreasing and newLevel >= resetAt)) then
        return
    end

    if limit ~= nil and ((decreasing and newLevel <= limit) or (not decreasing and newLevel >= limit)) then
        return
    end

    setWaterLevel(newLevel)
    serverWaterLevel = serverWaterLevel + ((decreasing and -1 or 1) * floodSpeed * 1000) * dt
end

local function onClientEndMission()
    ocean = nil
    calledOnInit = false
    
    enabled = false
    serverWaterLevel = nil
end

M.onUpdate = onUpdate
M.onClientEndMission = onClientEndMission

return M