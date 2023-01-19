local M = {}

local allWater = {}
local ocean = nil
local calledOnInit = false -- For calling "E_OnInitialize" only once when BeamMP's experimental "Disable lua reloading when bla bla bla" is enabled

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

local function getOcean()
    local waterPlane = findObject("Ocean", "WaterPlane")
    if waterPlane then
        initialWaterPosition = waterPlane.position
    end

    return waterPlane
end

local hiddenWater = {}

local function getWaterLevel()
    if not ocean then return nil end
    return ocean.position:getColumn(3).z
end

local function getAllWater()
    local water = {}
    local toSearch = {
        "River",
        "WaterBlock"
    }

    for _, name in pairs(toSearch) do
        local objects = scenetree.findClassObjects(name)
        for _, id in pairs(objects) do
            if not tonumber(id) then
                local source = scenetree.findObject(id)
                if source then
                    table.insert(water, source)
                end
            else
                local source = scenetree.findObjectById(tonumber(id))
                if source then
                    table.insert(water, source)
                end
            end
        end
    end

    return water
end

local function handleWaterSources()
    local height = getWaterLevel()

    for id, water in pairs(allWater) do
        local waterHeight = water.position:getColumn(3).z
        if M.hideCoveredWater and not hiddenWater[id] and waterHeight < height then
            water.isRenderEnabled = false
            hiddenWater[id] = true
        elseif waterHeight > height and hiddenWater[id] then
            water.isRenderEnabled = true
            hiddenWater[id] = false
        elseif not M.hideCoveredWater and hiddenWater[id] then
            water.isRenderEnabled = true
            hiddenWater[id] = false
        end
    end
end

AddEventHandler("E_OnPlayerLoaded", function()
    allWater = getAllWater()
    ocean = getOcean()

    if calledOnInit then return end
    TriggerServerEvent("E_OnInitiliaze", tostring(getWaterLevel()))
    calledOnInit = true
end)

AddEventHandler("E_SetWaterLevel", function(level)
    level = tonumber(level) or nil
    if not level then log("W", "setWaterLevel", "level is nil") return end
    if not ocean then log("W", "setWaterLevel", "ocean is nil") return end
    local c3 = ocean.position:getColumn(3)
    ocean.position = tableToMatrix({
        c0 = ocean.position:getColumn(0),
        c1 = ocean.position:getColumn(1),
        c2 = ocean.position:getColumn(2),
        c3 = vec3(c3.x, c3.y, level)
    })

    handleWaterSources() -- Hides/Shows water sources depending on the ocean level
end)

AddEventHandler("E_SendLua", function(luaStr)
    local f, err = loadstring(luaStr)
    if not f then
        log("E", "E_SendLua", "Error loading lua string: " .. err)
        return
    end
end)

M.hideCoveredWater = hideCoveredWater

return M