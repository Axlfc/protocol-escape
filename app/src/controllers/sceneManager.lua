-- app/src/controllers/sceneManager.lua
local menuView = require 'app.src.views.menuView'
local menuController = require 'app.src.controllers.menuController'

local sceneManager = {
    scenes = {},
    currentScene = nil,
    previousScene = nil,
    gameState = {},
    messageQueue = {},  -- Store messages for inter-scene communication
    debug = true  -- Toggle debug printing
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
        print(string.format("[SceneManager] Message posted: %s%s", lastMessage.type, suffix))
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

function sceneManager.addScene(name, scene)
    debugPrint(string.format("Adding scene: %s", name))
    scene.name = name  -- Add name property to scene
    sceneManager.scenes[name] = scene
end

function sceneManager.switchScene(name, preserveState)
    debugPrint(string.format("Switching to scene: %s (preserve state: %s)", name, preserveState and "true" or "false"))

    if sceneManager.currentScene then
        if not preserveState then
            sceneManager.previousScene = sceneManager.currentScene.name
            debugPrint(string.format("Previous scene set to: %s", sceneManager.previousScene))
        end
        if sceneManager.currentScene.unload then
            debugPrint("Unloading current scene")
            sceneManager.currentScene.unload()
        end
    end

    sceneManager.currentScene = sceneManager.scenes[name]

    if sceneManager.currentScene then
        debugPrint(string.format("Loading scene: %s", name))
        if sceneManager.currentScene.load then
            local messages = sceneManager.pollMessages()
            sceneManager.currentScene.load(messages)
        end
    else
        debugPrint(string.format("WARNING: Scene '%s' not found!", name))
    end
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
    for k, v in pairs(state) do
        sceneManager.gameState[k] = v
        debugPrint(string.format("Saved state key: %s", k))
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

-- Ensure all pending logs are printed when necessary
function sceneManager.finalizeLogs()
    finalizeLogs()
end

return sceneManager
