-- app/src/models/menuModel.lua
local menuView = require 'app.src.views.menuView'
local menuModel = {}

function menuModel.createMainMenu()
    return {
        selectedOption = 1,
        mouseHovering = false,
        options = { "Start Game", "Options", "Exit" },
        blockMovement = true,
        backgroundColor = { 0, 0, 0 },
        overlay = false,
        draw = function(self, pass)
            menuView.drawMenu(
                pass,
                self.options,
                self.selectedOption,
                self.backgroundColor,
                self.overlay
            )
        end,
        load = function(self)
            print("[MainMenu] Loading main menu")
        end,
        unload = function(self)
            print("[MainMenu] Unloading main menu")
        end
    }
end

function menuModel.createPauseMenu()
    return {
        selectedOption = 1,
        options = { "Resume", "Save", "Back to Main Menu", "Quit" },
        backgroundColor = { 0, 0, 0, 0.7 },  -- Increased opacity for better visibility
        overlay = true,
        draw = function(self, pass)
            menuView.drawMenu(
                pass,
                self.options,
                self.selectedOption,
                self.backgroundColor,
                self.overlay
            )
        end,
        load = function(self)
            print("[PauseMenu] Pause menu loaded")
        end,
        unload = function(self)
            print("[PauseMenu] Pause menu unloaded")
        end
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