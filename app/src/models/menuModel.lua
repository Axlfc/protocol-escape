-- app/src/models/menuModel.lua
local menuModel = {}

function menuModel.createMainMenu()
    return {
        selectedOption = 1,
        mouseHovering = false,  -- Track mouse hover state
        options = { "Start Game", "Options", "Exit" },
        blockMovement = true,
        backgroundColor = {0, 0, 0},
        overlay = false
    }
end

function menuModel.createPauseMenu()
    return {
        selectedOption = 1,
        mouseHovering = false,  -- Track mouse hover state
        options = { "Resume", "Save", "Back to Main Menu", "Quit" },
        blockMovement = true,
        backgroundColor = {0, 0, 0, 0.5},
        overlay = true
    }
end

function menuModel.createGameScene()
    return {
        blockMovement = false,
        mouseHovering = false,  -- Track mouse hover state
        update = function(self, dt)
            -- Game update logic here
        end,
        draw = function(self, pass)
            if not pass then
                error("Pass is nil. Ensure the draw method is called with a valid pass object.")
            end
            -- Game rendering logic
            pass:setColor(1, 1, 1)
            pass:cube(0, 1.7, -3, 0.5)  -- Example game object
        end
    }
end

return menuModel