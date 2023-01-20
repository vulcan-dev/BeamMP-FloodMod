local oSendChatMessage = MP.SendChatMessage

MP.hSendChatMessage = function(id, message)
    if id == -2 then -- console
        print(message)
    else -- player
        oSendChatMessage(id, message)
    end
end