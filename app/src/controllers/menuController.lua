-- app/src/controllers/menuController.lua
local menuController = {}

-- Helper function to get text dimensions (approximate)
local function getTextDimensions(text, size)
    -- LÖVR doesn't provide direct text measurement
    -- This is an approximation - adjust multipliers based on your font
    local charWidth = size * 0.5  -- Approximate width per character
    return #text * charWidth, size
end

-- Helper function to check if mouse is over text
local function isMouseOverOption(x, y, optionText, optionY)
    -- Text properties
    local textSize = 0.2
    local textWidth, textHeight = getTextDimensions(optionText, textSize)
    
    -- Convert screen coordinates to world space
    -- Note: These conversions assume default LÖVR projection setup
    -- You might need to adjust based on your camera configuration
    local viewWidth, viewHeight = lovr.system.getWindowWidth(), lovr.system.getWindowHeight()
    local worldX = (x / viewWidth * 2 - 1) * 3  -- Scale factor of 3 for typical LÖVR view frustum
    local worldY = -(y / viewHeight * 2 - 1) * 2  -- Flip Y and scale
    
    -- Define clickable area around text
    local textLeft = -textWidth/2
    local textRight = textWidth/2
    local textTop = optionY + textHeight/2
    local textBottom = optionY - textHeight/2
    
    -- Debug print for positioning (uncomment if needed)
    -- print(string.format("Mouse: (%.2f, %.2f), Text: %.2f-%.2f, %.2f-%.2f", worldX, worldY, textLeft, textRight, textBottom, textTop))
    
    -- Check if mouse is within text bounds
    return worldX >= textLeft and worldX <= textRight and
           worldY >= textBottom and worldY <= textTop
end

function menuController.handleMouseMove(x, y, scene)
    if not scene.options then return end
    
    local foundHover = false
    for i, option in ipairs(scene.options) do
        local optionY = 1.7 - (i - 1) * 0.3
        if isMouseOverOption(x, y, option, optionY) then
            scene.selectedOption = i
            scene.mouseHovering = true
            foundHover = true
            break
        end
    end
    
    if not foundHover then
        scene.mouseHovering = false
    end
end

function menuController.handleMouseClick(x, y, button, scene, sceneManager)
    if button == 1 and scene.mouseHovering then  -- Left click and hovering over an option
        menuController.selectOption(scene, sceneManager)
    end
end

function menuController.handleInput(key, scene, sceneManager)
    if not scene.options then return end

    if key == 'down' then
        scene.selectedOption = (scene.selectedOption % #scene.options) + 1
        scene.mouseHovering = false  -- Reset mouse hover when using keyboard
    elseif key == 'up' then
        scene.selectedOption = (scene.selectedOption - 2) % #scene.options + 1
        scene.mouseHovering = false  -- Reset mouse hover when using keyboard
    elseif key == 'return' then
        menuController.selectOption(scene, sceneManager)
    elseif key == 'escape' then
        if scene.name == 'game' then
            sceneManager.switchScene('pauseMenu')
        elseif scene.name == 'pauseMenu' then
            sceneManager.returnToPreviousScene()
        end
    end
end

function menuController.selectOption(scene, sceneManager)
    local selected = scene.options[scene.selectedOption]
    
    if scene.name == 'mainMenu' then
        if selected == "Start Game" then
            sceneManager.switchScene('game')
        elseif selected == "Options" then
            print("Options menu not yet implemented")
        elseif selected == "Exit" then
            lovr.event.quit()
        end
    elseif scene.name == 'pauseMenu' then
        if selected == "Resume" then
            sceneManager.returnToPreviousScene()
        elseif selected == "Save" then
            sceneManager.saveGameState({
                timestamp = os.time(),
            })
            print("Game saved!")
        elseif selected == "Back to Main Menu" then
            sceneManager.switchScene('mainMenu')
        elseif selected == "Quit" then
            lovr.event.quit()
        end
    end
end

return menuController