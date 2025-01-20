-- app/src/models/playerState.lua
local playerState = {}

function playerState.new(name)
    return {
        name = name,
        score = 0,
        health = 100
    }
end

return playerState
