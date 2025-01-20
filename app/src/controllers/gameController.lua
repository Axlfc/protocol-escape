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

function gameController.handleInput(key)
    -- Handle only gameplay-related input
    local activePlayer = gameInstance.getActivePlayer()
    if not activePlayer then return end

    if gameKeybindings[key] then
        gameController.handlePlayerInput(key, activePlayer)
    end
end

function gameController.handlePlayerInput(key, player)
    -- Handle player-specific input logic
    if key == gameKeybindings.moveForward then
        player:move(0, 0, -1)
    elseif key == gameKeybindings.moveBack then
        player:move(0, 0, 1)
    -- Add other movement handlers...
    end
end

return gameController