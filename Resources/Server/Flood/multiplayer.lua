--------------------------------------------------------------------------------
-- File: multiplayer.lua
--
-- Author:  Daniel W (vulcan-dev)
-- Created: 2024/03/18 22:00:49
--------------------------------------------------------------------------------

local oSendChatMessage = MP.SendChatMessage

MP.hSendChatMessage = function(id, message)
    if id == -2 then -- console
        print(message)
    else -- player
        oSendChatMessage(id, message)
    end
end