-- app/src/controllers/menuController.lua
local menuController = {}

function menuController.handleInput(key, scene, sceneManager)
    if not scene.options then return end

    if key == 'down' then
        scene.selectedOption = (scene.selectedOption % #scene.options) + 1
        scene.mouseHovering = false
    elseif key == 'up' then
        scene.selectedOption = (scene.selectedOption - 2) % #scene.options + 1
        scene.mouseHovering = false
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
            sceneManager.returnToPreviousScene()
        elseif option == "Save" then
            sceneManager.saveGameState({ timestamp = os.time() })
            print("Game saved!")
        elseif option == "Back to Main Menu" then
            sceneManager.switchScene('mainMenu')
        elseif option == "Quit" then
            lovr.event.quit()
        end
    end
end

return menuController