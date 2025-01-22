-- app/src/controllers/gameController.lua
local gameInstance = require 'app.src.models.gameInstance'  -- Add this import
local gameController = {}

-- Configurable keybindings for gameplay
local gameKeybindings = {
    moveForward = 'w',
    moveBack = 's',
    moveLeft = 'a',
    moveRight = 'd',
    jump = 'space'
}


function gameController.update(dt)
    if gameInstance.isServer then
        for _, player in ipairs(gameInstance.getPlayers()) do
            local message = json.encode({
                type = "playerState",
                id = player.id,
                position = player.position,  -- Example position data
            })
            networkManager.broadcast(message)
        end
    end
end


function gameController.handleInput(key)
    -- Handle only gameplay-related input
    local activePlayer = gameInstance.getActivePlayer()
    if not activePlayer then return end

    if gameKeybindings[key] then
        gameController.handlePlayerInput(key, activePlayer)
    end
end

function gameController.handlePlayerInput(key, player)
    if key == gameKeybindings.moveForward then
        player:move(0, 0, -1)
        networkManager.sendMessage(json.encode({ type = "move", direction = "forward", playerId = player.id }))
    elseif key == gameKeybindings.moveBack then
        player:move(0, 0, 1)
        networkManager.sendMessage(json.encode({ type = "move", direction = "backward", playerId = player.id }))
    end
end

return gameController