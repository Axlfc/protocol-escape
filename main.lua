-- main.lua
local sceneManager = require 'app.src.controllers.sceneManager'
local gameInstance = require 'app.src.models.gameInstance'


function lovr.load()
    -- Initialize game instance
    gameInstance.initialize()

    -- Set up scenes and switch to the main menu
    sceneManager.initialize()
    sceneManager.switchScene('mainMenu')
end


function lovr.update(dt)
    -- Update the game instance and propagate updates
    gameInstance.update(dt)
    sceneManager.update(dt)
end


function lovr.keypressed(key)
    -- Handle input at the scene level via sceneManager
    sceneManager.handleInput(key)
end


function lovr.draw(pass)
    -- Render the current and overlay scenes
    sceneManager.draw(pass)
end
