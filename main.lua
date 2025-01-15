-- main.lua
local sceneManager = require 'app.src.controllers.sceneManager'
local menuController = require 'app.src.controllers.menuController'
local menuModel = require 'app.src.models.menuModel'

function lovr.load()
    print("[Main] Game starting...")
    
    sceneManager.addScene('mainMenu', menuModel.createMainMenu())
    sceneManager.addScene('pauseMenu', menuModel.createPauseMenu())
    sceneManager.addScene('game', menuModel.createGameScene())
    
    sceneManager.switchScene('mainMenu')
end

function lovr.update(dt)
    sceneManager.update(dt)
end

function lovr.keypressed(key)
    if sceneManager.currentScene then
        menuController.handleInput(key, sceneManager.currentScene, sceneManager)
    end
end

function lovr.draw(pass)
    sceneManager.draw(pass)
end
