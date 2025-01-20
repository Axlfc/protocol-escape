-- app/src/models/menuModel.lua
local menuView = require 'app.src.views.menuView'
local menuModel = {}

local MENU_OPTIONS = {
    main = { "Start Game", "Options", "Exit" },
    pause = { "Resume", "Save", "Back to Main Menu", "Quit" }
}

local MENU_LAYOUTS = {
    main = {
        backgroundColor = { 0, 0, 0 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.3
    },
    pause = {
        backgroundColor = { 0, 0, 0, 0.8 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.3
    }
}

function menuModel.createMenu(name, options, layout)
    -- Create the menu table with all properties
    local menu = {
        name = name,
        selectedOption = 1,
        options = options,
        layout = layout
    }

    -- Define methods using the colon (`:`) syntax
    function menu:load(messages)
        print(string.format("[%s] Menu loaded", self.name))
        self.selectedOption = 1  -- Reset selection on load
    end

    function menu:unload()
        print(string.format("[%s] Menu unloaded", self.name))
    end

    function menu:draw(pass)
        if not pass then return end
        menuView.drawMenu(
            pass,
            self.options,
            self.selectedOption,
            self.layout.backgroundColor,
            self.name == "pauseMenu"  -- overlay flag for pause menu
        )
    end

    return menu
end

function menuModel.createMainMenu()
    return menuModel.createMenu("mainMenu", { "Start Game", "Options", "Exit" }, {
        backgroundColor = { 0.1, 0.1, 0.1 }, -- Adjust as necessary
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.3
    })
end

function menuModel.createPauseMenu()
    return menuModel.createMenu("pauseMenu", MENU_OPTIONS.pause, MENU_LAYOUTS.pause)
end


function menuModel.createGameScene(params)
    params = params or {}
    local scene = {
        name = "game"
    }

    function scene:load(messages)
        print("[GameScene] Loading game scene")
    end

    function scene:unload()
        print("[GameScene] Unloading game scene")
    end

    function scene:update(dt)
        if params.update then
            params.update(dt)
        end
    end

    function scene:draw(pass)
        if params.draw then
            params.draw(pass)
        else
            pass:setColor(1, 1, 1)
            pass:cube(0, 1.7, -3, 0.5)
        end
    end

    return scene
end


return menuModel
