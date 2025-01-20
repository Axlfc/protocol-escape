-- app/src/models/gameState.lua
local gameState = {
    score = 0,
    timeElapsed = 0,
    objectives = {}
}

function gameState.reset()
    gameState.score = 0
    gameState.timeElapsed = 0
    gameState.objectives = {}
    print("[GameState] State reset")
end

function gameState.updateScore(amount)
    gameState.score = gameState.score + amount
    print("[GameState] Score updated:", gameState.score)
end

function gameState.trackTime(dt)
    gameState.timeElapsed = gameState.timeElapsed + dt
end

return gameState
