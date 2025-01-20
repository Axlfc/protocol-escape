-- app/src/models/gameInstance.lua
local gameMode = require 'app.src.models.gameMode'
local gameState = require 'app.src.models.gameState'
local playerState = require 'app.src.models.playerState'

local gameInstance = {
    isServer = false,  -- Set this to `true` for server setups
    gameMode = nil,      -- Current game mode
    gameState = nil,      -- Current game state
    playerStates = {},
    pawns = {},
    controllers = {},
    players = {},        -- All connected players
    activePlayer = nil,  -- Reference to the currently active player
    network = nil,       -- Network manager instance

    debug = true         -- Debug toggle
}


function gameInstance.initialize()
    print("[GameInstance] Initializing...")
    gameInstance.gameMode = gameMode.new()
    gameState.reset()
    
    -- Create default player for single-player mode
    local defaultPlayer = playerState.new("Player1")
    gameInstance.addPlayer(defaultPlayer)
    gameInstance.setActivePlayer(defaultPlayer)
    
    if not gameInstance.isServer then
        print("[GameInstance] Client HUD and Widgets to be initialized.")
    end
end


function gameInstance.update(dt)
    -- Update game state and mode
    gameState.trackTime(dt)
    if gameInstance.isServer and gameInstance.gameMode then
        gameInstance.gameMode.update(dt)
    end
end


function gameInstance.addPlayer(player)
    table.insert(gameInstance.players, player)
    if gameInstance.debug then
        print("[GameInstance] Player added:", player.name)
    end
    
    -- If this is the first player, make them active
    if #gameInstance.players == 1 then
        gameInstance.setActivePlayer(player)
    end
end


function gameInstance.setActivePlayer(player)
    gameInstance.activePlayer = player
    if gameInstance.debug then
        print("[GameInstance] Active player set to:", player.name)
    end
end


function gameInstance.getActivePlayer()
    return gameInstance.activePlayer
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
