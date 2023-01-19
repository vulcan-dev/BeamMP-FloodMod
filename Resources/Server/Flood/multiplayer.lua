local oSendChatMessage = MP.SendChatMessage

MP.SendLua = function(id, luaStr)
    local success = MP.TriggerClientEvent(id, "E_SendLua", luaStr:gsub("%s+", " "))
    if not success then
        print("Failed to send \"" .. luaStr .. "\" to " .. id)
    end
end

MP.hSendChatMessage = function(id, message)
    if id == -2 then -- console
        print(message)
    else -- player
        oSendChatMessage(id, message)
    end
end