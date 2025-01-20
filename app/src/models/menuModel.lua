local menuView = require 'app.src.views.menuView'
local menuModel = {}

local MENU_OPTIONS = {
    main = { "Start Game", "Options", "Exit" },
    pause = { "Resume", "Save", "Back to Main Menu", "Quit" }
}

local BACKGROUND_COLORS = {
    main = { 0, 0, 0 },
    pause = { 0, 0, 0, 0.8 }
}

local function createMenu(name, options, backgroundColor, overlay)
    assert(type(options) == "table" and #options > 0, "Options must be a non-empty table")
    return {
        selectedOption = 1,
        options = options,
        backgroundColor = backgroundColor,
        overlay = overlay,
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
            print(string.format("[%s] Menu loaded", name))
        end,
        unload = function(self)
            print(string.format("[%s] Menu unloaded", name))
        end
    }
end

function menuModel.createMainMenu()
    return createMenu("MainMenu", MENU_OPTIONS.main, BACKGROUND_COLORS.main, false)
end

function menuModel.createPauseMenu()
    return createMenu("PauseMenu", MENU_OPTIONS.pause, BACKGROUND_COLORS.pause, false)
end

function menuModel.createGameScene(params)
    params = params or {}
    return {
        blockMovement = params.blockMovement or false,
        load = function(self, messages)
            print("[GameScene] Loading game scene")
        end,
        update = function(self, dt)
            if params.update then
                params.update(dt)
            end
        end,
        draw = function(self, pass)
            if params.draw then
                params.draw(pass)
            else
                pass:setColor(1, 1, 1)
                pass:cube(0, 1.7, -3, 0.5)
            end
        end,
        unload = function(self)
            print("[GameScene] Unloading game scene")
        end
    }
end

return menuModel
