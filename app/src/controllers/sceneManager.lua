-- app/src/controllers/sceneManager.lua
local menuView = require 'app.src.views.menuView'
local menuController = require 'app.src.controllers.menuController'

local sceneManager = {
    scenes = {},
    currentScene = nil,
    previousScene = nil,  -- Track previous scene for returning from pause
    gameState = {}  -- Store persistent game state
}

function sceneManager.addScene(name, scene)
    scene.name = name  -- Add name property to scene
    sceneManager.scenes[name] = scene
end

function sceneManager.switchScene(name, preserveState)
    if sceneManager.currentScene then
        if not preserveState then
            sceneManager.previousScene = sceneManager.currentScene.name
        end
        if sceneManager.currentScene.unload then
            sceneManager.currentScene.unload()
        end
    end
    
    sceneManager.currentScene = sceneManager.scenes[name]
    if sceneManager.currentScene and sceneManager.currentScene.load then
        sceneManager.currentScene.load()
    end
end

function sceneManager.returnToPreviousScene()
    if sceneManager.previousScene then
        sceneManager.switchScene(sceneManager.previousScene, true)
    end
end

function sceneManager.saveGameState(state)
    for k, v in pairs(state) do
        sceneManager.gameState[k] = v
    end
end

function sceneManager.getGameState()
    return sceneManager.gameState
end

function sceneManager.update(dt)
    if sceneManager.currentScene and sceneManager.currentScene.update then
        sceneManager.currentScene.update(dt)
    end
end

function sceneManager.draw(pass)
    if not pass then
        error("Pass is nil. Ensure LÖVR's draw function is providing a valid pass object.")
    end

    if sceneManager.currentScene then
        if sceneManager.currentScene.options then
            menuView.drawMenu(
                pass,
                sceneManager.currentScene.options,
                sceneManager.currentScene.selectedOption,
                sceneManager.currentScene.backgroundColor or {0, 0, 0},
                sceneManager.currentScene.overlay
            )
        elseif sceneManager.currentScene.draw then
            sceneManager.currentScene:draw(pass)
        end
    end
end

return sceneManager