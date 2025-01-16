-- app/src/controllers/menuController.lua
local menuController = {}

function menuController.handleInput(key, scene, sceneManager)
    if key == 'escape' then
        if scene.name == 'game' then
            if not sceneManager.isOverlayActive() then
                sceneManager.switchOverlayScene('pauseMenu')
            end
        elseif scene.name == 'pauseMenu' then
            sceneManager.clearOverlayScene()
        end
        return  -- Stop further input processing
    end

    if not scene.options then return end

    -- Normal input handling for menu navigation
    if key == 'down' then
        scene.selectedOption = (scene.selectedOption % #scene.options) + 1
    elseif key == 'up' then
        scene.selectedOption = (scene.selectedOption - 2) % #scene.options + 1
    elseif key == 'return' then
        local selectedOption = scene.options[scene.selectedOption]
        menuController.handleOptionSelected(selectedOption, scene, sceneManager)
    end
end

function menuController.handleOptionSelected(option, scene, sceneManager)
    if scene.name == 'mainMenu' then
        if option == "Start Game" then
            sceneManager.switchScene('game')
        elseif option == "Options" then
            print("Options menu not yet implemented")
        elseif option == "Exit" then
            lovr.event.quit()
        end
    elseif scene.name == 'pauseMenu' then
        if option == "Resume" then
            sceneManager.clearOverlayScene()
        elseif option == "Save" then
            sceneManager.saveGameState({ timestamp = os.time() })
            print("Game saved!")
        elseif option == "Back to Main Menu" then
            sceneManager.clearOverlayScene()  -- Clear pause menu first
            sceneManager.switchScene('mainMenu')
        elseif option == "Quit" then
            lovr.event.quit()
        end
    end
end

return menuController