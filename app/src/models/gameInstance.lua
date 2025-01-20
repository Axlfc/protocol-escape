-- app/src/models/gameInstance.lua
local gameMode = require 'app.src.models.gameMode'
local gameState = require 'app.src.models.gameState'

local gameInstance = {
    players = {},        -- All connected players
    network = nil,       -- Network manager instance
    gameMode = nil,      -- Current game mode
    debug = true         -- Debug toggle
}


function gameInstance.initialize()
    print("[GameInstance] Initializing game instance...")
    gameInstance.gameMode = gameMode.new()
    gameState.reset()
end


function gameInstance.update(dt)
    gameState.trackTime(dt)
    if gameInstance.gameMode then
        gameInstance.gameMode.update(dt)
    end
end


function gameInstance.addPlayer(player)
    table.insert(gameInstance.players, player)
    if gameInstance.debug then
        print("[GameInstance] Player added:", player.name)
    end
end


function gameInstance.getPlayers()
    return gameInstance.players
end


function gameInstance.onSceneSwitch(fromScene, toScene)
    print(string.format("[GameInstance] Switching from '%s' to '%s'", fromScene and fromScene.name or "none", toScene))
end


function gameInstance.setGameMode(mode)
    gameInstance.gameMode = mode
end


function gameInstance.getGameMode()
    return gameInstance.gameMode
end


return gameInstance
