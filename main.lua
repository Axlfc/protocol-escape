-- main.lua
local sceneManager = require 'app.src.controllers.sceneManager'


function lovr.load()
    print("[Main] Game starting...")
    sceneManager.initialize() -- Handle scene setup within sceneManager
    sceneManager.switchScene('mainMenu')
end


function lovr.update(dt)
    sceneManager.update(dt)
end


function lovr.keypressed(key)
    sceneManager.handleInput(key) -- Delegate input handling entirely to sceneManager
end


function lovr.draw(pass)
    sceneManager.draw(pass)
end
