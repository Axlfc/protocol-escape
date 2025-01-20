-- app/src/controllers/menuController.lua
local menuController = {}

-- Configurable keybindings specifically for menu navigation
local menuKeybindings = {
    exit = 'escape',
    down = 'down',
    up = 'up',
    select = 'return'
}


-- Keep menu action handling separate
function menuController.handleOptionSelected(option, scene, sceneManager)
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
            print("[MultiplayerMenu] Hosting a game...")
            -- Add hosting logic here
        elseif option == "Join Game" then
            print("[MultiplayerMenu] Joining a game...")
            -- Add joining logic here
        elseif option == "Back" then
            sceneManager.switchScene('mainMenu')
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

    -- Initialize selectedOption if it doesn't exist
    if not scene.selectedOption then
        scene.selectedOption = 1
    end

    if key == menuKeybindings.down then
        -- Move down, wrapping around to the top
        scene.selectedOption = scene.selectedOption + 1
        if scene.selectedOption > #scene.options then
            scene.selectedOption = 1
        end
        print(string.format("[Debug] Moved down to option: %s", scene.options[scene.selectedOption]))

    elseif key == menuKeybindings.up then
        -- Move up, wrapping around to the bottom
        scene.selectedOption = scene.selectedOption - 1
        if scene.selectedOption < 1 then
            scene.selectedOption = #scene.options
        end
        print(string.format("[Debug] Moved up to option: %s", scene.options[scene.selectedOption]))

    elseif key == menuKeybindings.select then
        local selectedOption = scene.options[scene.selectedOption]
        print(string.format("[Debug] Selected option: %s", selectedOption))
        menuController.handleOptionSelected(selectedOption, scene, sceneManager)
    end
end


return menuController