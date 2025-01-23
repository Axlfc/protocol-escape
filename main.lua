-- main.lua
local sceneManager = require 'app.src.controllers.sceneManager'
local gameInstance = require 'app.src.models.gameInstance'
local networkManager = require 'app.utils.networkManager'


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

    if networkManager.isServer then
        networkManager.acceptNewConnections()
    else
        local statusChannel = lovr.thread.getChannel('networkStatus')
        local status = statusChannel:pop()
        if status == "DISCONNECTED" then
            print("[NetworkManager] Disconnection detected")
            networkManager.handleServerDisconnect(sceneManager)  -- Pass sceneManager explicitly
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
    end
end