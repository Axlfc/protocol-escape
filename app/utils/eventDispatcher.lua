-- app/utils/eventDispatcher.lua
local logger = require 'app.utils.logger'
local eventDispatcher = {}

eventDispatcher.listeners = {}

local events = {
    PLAYER_ADDED = "playerAdded",
    SCENE_SWITCHED = "sceneSwitched",
    GAME_SAVED = "gameSaved",
}


function eventDispatcher.addEventListener(event, listener)
    if not eventDispatcher.listeners[event] then
        eventDispatcher.listeners[event] = {}
    end
    table.insert(eventDispatcher.listeners[event], listener)
end


function eventDispatcher.dispatch(event, data)
    if eventDispatcher.listeners[event] then
        for _, listener in ipairs(eventDispatcher.listeners[event]) do
            listener(data)
        end
    end
end


-- Register events after function definitions
eventDispatcher.addEventListener(events.PLAYER_ADDED, function(data)
    logger.info("Player added: " .. data.name .. "(" .. data.id .. ")")
end)


return eventDispatcher