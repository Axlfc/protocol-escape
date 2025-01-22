-- app/src/controllers/menuController.lua
local networkManager = require 'app.utils.networkManager'

local menuController = {}

-- Configurable keybindings specifically for menu navigation
local menuKeybindings = {
    exit = 'escape',
    down = 'down',
    up = 'up',
    select = 'return'
}


local function handleHostGameMenu(option, scene, sceneManager)
    if option == "Start Hosting" then
        print("[HostGameMenu] Starting to host a game...")
        local success, err = networkManager.startServer()
        if success then
            print("[HostGameMenu] Server started successfully!")
            sceneManager.switchScene("game")
        else
            print("[HostGameMenu] Failed to start server:", err)
        end
    elseif option == "Server Options" then
        sceneManager.switchScene("serverOptionsMenu")
    elseif option == "Back" then
        sceneManager.switchScene("multiplayerMenu")
    end
end

local function handleJoinGameMenu(option, scene, sceneManager)
    if option == "Connect to IP" then
        print("[JoinGameMenu] Attempting to connect...")
        local success, err = networkManager.connectToServer("127.0.0.1") -- Replace with user input
        if success then
            print("[JoinGameMenu] Connected to server.")
            sceneManager.switchScene("game")
        else
            print("[JoinGameMenu] Failed to connect:", err)
        end
    elseif option == "Recent Servers" then
        print("[JoinGameMenu] Recent servers functionality not implemented.")
    elseif option == "Back" then
        sceneManager.switchScene("multiplayerMenu")
    end
end

local function handleServerOptionsMenu(option, scene, sceneManager)
    if option == "Back" then
        sceneManager.switchScene("hostGameMenu")
    else
        print(string.format("[ServerOptionsMenu] Selected option: %s", option))
    end
end


-- Keep menu action handling separate
function menuController.handleOptionSelected(option, scene, sceneManager)
    if scene.name == "hostGameMenu" then
        handleHostGameMenu(option, scene, sceneManager)
    elseif scene.name == "joinGameMenu" then
        handleJoinGameMenu(option, scene, sceneManager)
    elseif scene.name == "serverOptionsMenu" then
        handleServerOptionsMenu(option, scene, sceneManager)
    else
        print(string.format("[MenuController] Unhandled option '%s' in scene '%s'", option, scene.name))
    end

    if scene.name == 'mainMenu' then
        if option == "Start Game" then
            sceneManager.switchScene('game')
        elseif option == "Multiplayer" then
            sceneManager.switchScene('multiplayerMenu')
        elseif option == "Options" then
            print("Options menu not yet implemented")
        elseif option == "Exit" then
            lovr.event.quit()
        end
    elseif scene.name == 'multiplayerMenu' then
        if option == "Host Game" then
            sceneManager.switchScene('hostGameMenu')
        elseif option == "Join Game" then
            sceneManager.switchScene('joinGameMenu')

        elseif option == "Back" then
            sceneManager.switchScene('mainMenu')
        end
    elseif scene.name == 'multiplayerMenu' then
        if option == "Host Game" then
            sceneManager.switchScene('hostGameMenu')
        elseif option == "Join Game" then
            sceneManager.switchScene('joinGameMenu')

        elseif option == "Back" then
            sceneManager.switchScene('mainMenu')
        end

    elseif scene.name == 'hostGameMenu' then
        if option == "Start Hosting" then
            print("START HOSTING GAME SERVER")
        elseif option == "Server Options" then
            print("NAVIGATE TO SERVER OPTIONS MENU")
        elseif option == "Back" then
            sceneManager.switchScene('multiplayerMenu')
        end
    elseif scene.name == 'joinGameMenu' then
        if option == "Connect to IP" then
            print("NAVIGATE TO IP INPUT MENU")
        elseif option == "Recent Servers" then
            print("NAVIGATE TO RECENT SERVERS MENU")
        elseif option == "Back" then
            sceneManager.switchScene('multiplayerMenu')
        end
    elseif scene.name == 'pauseMenu' then
        if option == "Resume" then
            sceneManager.clearOverlayScene()
        elseif option == "Save" then
            sceneManager.saveGameState({ timestamp = os.time() })
            print("Game saved!")
        elseif option == "Back to Main Menu" then
            sceneManager.clearOverlayScene()
            sceneManager.switchScene('mainMenu')
        elseif option == "Quit" then
            lovr.event.quit()
        end
    end
end


function menuController.handleInput(key, scene, sceneManager)
    if not scene or not scene.options or #scene.options == 0 then
        return
    end

    -- Initialize selectedOption if missing
    if not scene.selectedOption then
        scene.selectedOption = 1
    end

    if key == menuKeybindings.down then
        scene.selectedOption = (scene.selectedOption % #scene.options) + 1
    elseif key == menuKeybindings.up then
        scene.selectedOption = (scene.selectedOption - 2) % #scene.options + 1
    elseif key == menuKeybindings.select then
        local selectedOption = scene.options[scene.selectedOption]
        menuController.handleOptionSelected(selectedOption, scene, sceneManager)
    elseif key == menuKeybindings.exit then
        if scene.name == "hostGameMenu" or scene.name == "joinGameMenu" or scene.name == "serverOptionsMenu" then
            sceneManager.switchScene("multiplayerMenu")
        end
    end
end


return menuController