require("multiplayer")

local flood = require("flood")
local commands = flood.commands
local prefix = "/flood_"

function chatMessageHandler(pid, name, message)
    if not message then -- console input
        message = pid
        pid = -2
    end

    if message:sub(1, #prefix) == "/flood_" then
        local command = message:sub(#prefix + 1)
        local args = {}
        for arg in command:gmatch("%S+") do
            table.insert(args, arg)
        end
        command = args[1]
        table.remove(args, 1)
        if commands[command] then
            commands[command](pid, table.unpack(args))
            return 1
        else
            MP.hSendChatMessage(pid, "Unknown command: " .. command)
            return 1
        end
    end

    return 0
end

MP.RegisterEvent("onInit", "onInit")
MP.RegisterEvent("onChatMessage", "chatMessageHandler")
MP.RegisterEvent("onConsoleInput", "chatMessageHandler")