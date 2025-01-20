-- app/src/views/hud.lua
local hud = {}

function hud.draw(pass, gameState)
    pass:setColor(1, 1, 1)
    pass:text("Score: " .. gameState.score, 0, 3, -3, 0.5)
    pass:text("Time: " .. math.floor(gameState.timeElapsed), 0, 2.5, -3, 0.5)
end

return hud
