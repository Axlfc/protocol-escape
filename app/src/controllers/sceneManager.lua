-- app/src/controllers/sceneManager.lua
local menuModel = require 'app.src.models.menuModel'
local menuController = require 'app.src.controllers.menuController'
local gameController = require 'app.src.controllers.gameController'  
local gameInstance = require 'app.src.models.gameInstance'

local sceneManager = {
    scenes = {},
    currentScene = nil,
    previousScene = nil,
    overlayScene = nil,  -- Store the current overlay scene
    gameState = {},
    messageQueue = {},
    debug = true
}

-- Grouped logging variables
local lastMessage = nil
local lastMessageCount = 0


-- Debug print helper
local function debugPrint(...)
    if sceneManager.debug then
        print(string.format("[SceneManager] %s", ...))
    end
end


-- Finalize grouped log messages
local function finalizeLogs()
    if lastMessage then
        local suffix = lastMessageCount > 1 and string.format(" (%d)", lastMessageCount) or ""
        print(string.format("[SceneManager] Message posted: %s%s (%s)", lastMessage.type, suffix, lastMessage.details or "no details"))
        lastMessage = nil
        lastMessageCount = 0
    end
end


-- Post a message and group similar ones
function sceneManager.postMessage(message)
    if lastMessage and message.type == lastMessage.type then
        -- Increment count for repeated messages
        lastMessageCount = lastMessageCount + 1
    else
        -- Finalize and print the previous grouped message
        finalizeLogs()
        -- Update to the new message
        lastMessage = message
        lastMessageCount = 1
    end
    -- Add message to the queue
    table.insert(sceneManager.messageQueue, message)
end


-- Poll messages and flush grouped logs
function sceneManager.pollMessages()
    finalizeLogs()  -- Ensure remaining messages are logged
    local messages = sceneManager.messageQueue
    sceneManager.messageQueue = {}  -- Clear the message queue

    if #messages > 0 then
        debugPrint(string.format("Polled %d messages", #messages))
        for _, msg in ipairs(messages) do
            debugPrint(string.format("Processing message: %s", msg.type or "unknown"))
        end
    end

    return messages
end


-- Initialize scenes
function sceneManager.initialize()
    print("[SceneManager] Initializing scenes...")

    -- Access gameMode and set up specific scenes based on the mode
    local gameMode = gameInstance.getGameMode()

    sceneManager.addScene('mainMenu', menuModel.createMainMenu())
    sceneManager.addScene('pauseMenu', menuModel.createPauseMenu())
    sceneManager.addScene('multiplayerMenu', menuModel.createMultiplayerMenu())  -- Correctly add multiplayer menu
    sceneManager.addScene('game', menuModel.createGameScene({
        rules = gameMode.rules,
        objectives = gameMode.objectives
    }))

    if gameInstance.debug then
        print("[GameInstance] GameMode and GameState initialized.")
    end
end


function sceneManager.addScene(name, scene)
    if not (scene.load and scene.unload and scene.draw) then
        error(string.format("Scene '%s' must have 'load', 'unload', and 'draw' functions.", name))
    end
    scene.name = name  -- Add name property to scene
    sceneManager.scenes[name] = scene
end


function sceneManager.switchScene(name, preserveState)
    if not sceneManager.scenes[name] then
        print("[SceneManager] Scene not found:", name)
        return
    end

    -- Notify the game instance of the scene change
    gameInstance.onSceneSwitch(sceneManager.currentScene and sceneManager.currentScene.name, name)

    -- Unload the current scene
    if sceneManager.currentScene then
        if not preserveState then
            sceneManager.previousScene = sceneManager.currentScene.name
        end
        sceneManager.currentScene:unload()
    end

    -- Load the new scene
    sceneManager.currentScene = sceneManager.scenes[name]
    if sceneManager.currentScene then
        -- Ensure menu properties are properly initialized
        if sceneManager.currentScene.options then
            sceneManager.currentScene.selectedOption = 1
        end
        local messages = sceneManager.pollMessages()
        sceneManager.currentScene:load(messages)
    end

    debugPrint(string.format("Switched to scene: %s", name))
end


function sceneManager.returnToPreviousScene()
    if sceneManager.previousScene then
        debugPrint(string.format("Returning to previous scene: %s", sceneManager.previousScene))
        sceneManager.switchScene(sceneManager.previousScene, true)
    else
        debugPrint("No previous scene to return to")
    end
end


function sceneManager.saveGameState(state)
    debugPrint("Saving game state")
    local function deepMerge(t1, t2)
        for k, v in pairs(t2) do
            if type(v) == 'table' and type(t1[k]) == 'table' then
                deepMerge(t1[k], v)
            else
                t1[k] = v
            end
        end
    end
    deepMerge(sceneManager.gameState, state)
    for k, _ in pairs(state) do
        debugPrint(string.format("Saved state key: %s", k))
    end
end


function sceneManager.getGameState()
    return sceneManager.gameState
end


function sceneManager.update(dt)
    if sceneManager.overlayScene then
        -- Only update the overlay scene
        if sceneManager.overlayScene.update then
            sceneManager.overlayScene.update(dt)
        end
    elseif sceneManager.currentScene and sceneManager.currentScene.update then
        -- Update the current game scene if no overlay is active
        sceneManager.currentScene.update(dt)
    end
end


function sceneManager.switchOverlayScene(name)
    if not sceneManager.scenes[name] then
        print("[SceneManager] Overlay scene not found:", name)
        return
    end

    if sceneManager.overlayScene then
        sceneManager.overlayScene:unload()  -- Correct colon syntax
    end

    sceneManager.overlayScene = sceneManager.scenes[name]
    if sceneManager.overlayScene then
        sceneManager.overlayScene:load()  -- Correct colon syntax
    end
end


function sceneManager.clearOverlayScene()
    debugPrint("Clearing overlay scene")
    if sceneManager.overlayScene then
        sceneManager.overlayScene:unload()  -- Use colon syntax
    end
    sceneManager.overlayScene = nil
end


function sceneManager.getCurrentActiveScene()
    -- Return overlay scene if it exists, otherwise return current scene
    return sceneManager.overlayScene or sceneManager.currentScene
end


function sceneManager.isOverlayActive()
    return sceneManager.overlayScene ~= nil
end


function sceneManager.handleInput(key)
    local activeScene = sceneManager.getCurrentActiveScene()
    if not activeScene then return end

    -- Handle escape key for pause menu toggle
    if key == 'escape' then
        if activeScene.name == 'game' then
            sceneManager.switchOverlayScene('pauseMenu')
            return
        elseif activeScene.name == 'pauseMenu' then
            sceneManager.clearOverlayScene()
            return
        elseif activeScene.name == 'multiplayerMenu' then
            sceneManager.switchScene('mainMenu')
            return
        end
    end

    -- If we have an overlay active, handle its input first
    if sceneManager.isOverlayActive() then
        menuController.handleInput(key, sceneManager.overlayScene, sceneManager)
        return
    end

    -- Handle scene-specific input
    if activeScene.name == 'mainMenu' or activeScene.name == 'multiplayerMenu' or activeScene.name == 'pauseMenu' then
        menuController.handleInput(key, activeScene, sceneManager)
    else
        -- Handle gameplay input
        gameController.handleInput(key)
    end
end


function sceneManager.draw(pass)
    if not pass then
        error("Pass is nil. Ensure LÖVR's draw function is providing a valid pass object.")
    end

    if sceneManager.currentScene then
        sceneManager.currentScene:draw(pass)  -- Use colon syntax here
    end

    -- Render the overlay scene, if active
    if sceneManager.overlayScene then
        sceneManager.overlayScene:draw(pass)  -- Use colon syntax here
    end
end


function sceneManager.finalizeLogs()
    finalizeLogs()
end


return sceneManager
