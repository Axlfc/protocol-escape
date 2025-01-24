-- main.lua
local sceneManager = require 'app.src.controllers.sceneManager'
local gameInstance = require 'app.src.models.gameInstance'
local networkManager = require 'app.utils.networkManager'
local lastAcceptTime = 0
local acceptInterval = 0.1 -- seconds


function lovr.load()
    -- Initialize game instance
    gameInstance.initialize()

    networkManager.initConnectionLogging()

    -- Set up scenes and switch to the main menu
    sceneManager.initialize()
    sceneManager.switchScene('mainMenu')
end


function lovr.update(dt)
    gameInstance.update(dt)
    sceneManager.update(dt)

    local currentTime = os.time()

    if networkManager.isServer and currentTime - lastAcceptTime >= acceptInterval then
        networkManager.acceptNewConnections()
        lastAcceptTime = currentTime
    else
        local statusChannel = lovr.thread.getChannel('networkStatus')
        local status = statusChannel:pop()
        if status == "SERVER_FULL" then
            print("[NetworkManager] Server full, switching to joinGameMenu")
            sceneManager.switchScene('joinGameMenu') -- Switch to joinGameMenu directly
        elseif status == "DISCONNECTED" then
            print("[NetworkManager] Disconnection detected")
            networkManager.notifyServerOfDisconnect()
            networkManager.handleServerDisconnect(sceneManager)
        end
    end
end


function lovr.keypressed(key)
    -- Handle input at the scene level via sceneManager
    sceneManager.handleInput(key)
end


function lovr.draw(pass)
    -- Render the current and overlay scenes
    sceneManager.draw(pass)
end


function lovr.quit()
    if networkManager.isServer then
        networkManager.shutdownServer()
    else
        networkManager.notifyServerOfDisconnect()
        networkManager.resetClient()
    end
end