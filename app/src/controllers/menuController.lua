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
            sceneManager.clearOverlayScene()
            sceneManager.switchScene('mainMenu')
        elseif option == "Quit" then
            lovr.event.quit()
        end
    end
end


function menuController.handleInput(key, scene, sceneManager)
    if not scene.options or #scene.options == 0 then return end

    -- Handle escape key for pause menu toggle
    if key == menuKeybindings.exit then
        if scene.name == 'pauseMenu' then
            sceneManager.clearOverlayScene()
            return
        end
    end

    -- Menu navigation logic
    if key == menuKeybindings.down then
        scene.selectedOption = (scene.selectedOption % #scene.options) + 1
    elseif key == menuKeybindings.up then
        scene.selectedOption = (scene.selectedOption - 2) % #scene.options + 1
    elseif key == menuKeybindings.select then
        local selectedOption = scene.options[scene.selectedOption]
        -- Now correctly reference the module's function
        menuController.handleOptionSelected(selectedOption, scene, sceneManager)
    end
end


return menuController