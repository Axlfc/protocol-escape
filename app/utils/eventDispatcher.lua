-- app/utils/eventDispatcher.lua
local eventDispatcher = {}

eventDispatcher.listeners = {}


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


return eventDispatcher
