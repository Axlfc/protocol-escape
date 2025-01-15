-- main.lua
local sceneManager = require 'app.src.controllers.sceneManager'
local menuController = require 'app.src.controllers.menuController'
local menuModel = require 'app.src.models.menuModel'

function lovr.load()
    -- Register scenes
    sceneManager.addScene('mainMenu', menuModel.createMainMenu())
    sceneManager.addScene('pauseMenu', menuModel.createPauseMenu())
    sceneManager.addScene('game', menuModel.createGameScene())
    
    -- Start with main menu
    sceneManager.switchScene('mainMenu')
end

function lovr.update(dt)
    if sceneManager.currentScene then
        sceneManager.update(dt)
    end
end

function lovr.keypressed(key)
    if sceneManager.currentScene then
        menuController.handleInput(key, sceneManager.currentScene, sceneManager)
    end
end

-- Add mouse movement handling
function lovr.mousemoved(x, y, dx, dy)
    if sceneManager.currentScene and sceneManager.currentScene.options then
        menuController.handleMouseMove(x, y, sceneManager.currentScene)
    end
end

-- Add mouse click handling
function lovr.mousepressed(x, y, button)
    if sceneManager.currentScene and sceneManager.currentScene.options then
        menuController.handleMouseClick(x, y, button, sceneManager.currentScene, sceneManager)
    end
end

function lovr.draw(pass)
    sceneManager.draw(pass)
end