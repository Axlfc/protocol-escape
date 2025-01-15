-- app/src/models/menuModel.lua
local menuModel = {}

function menuModel.createMainMenu()
    return {
        selectedOption = 1,
        mouseHovering = false,
        options = { "Start Game", "Options", "Exit" },
        blockMovement = true,
        backgroundColor = { 0, 0, 0 },
        overlay = false
    }
end

function menuModel.createPauseMenu()
    return {
        selectedOption = 1,
        mouseHovering = false,
        options = { "Resume", "Save", "Back to Main Menu", "Quit" },
        blockMovement = true,
        backgroundColor = { 0, 0, 0, 0.5 },
        overlay = true
    }
end

function menuModel.createGameScene()
    return {
        blockMovement = false,
        load = function(self, messages)
            print("[GameScene] Loading game scene")
        end,
        update = function(self, dt)
            -- Update game state
        end,
        draw = function(self, pass)
            pass:setColor(1, 1, 1)
            pass:cube(0, 1.7, -3, 0.5)
        end,
        unload = function(self)
            print("[GameScene] Unloading game scene")
        end
    }
end

return menuModel
