-- app/src/models/menuModel.lua
local menuView = require 'app.src.views.menuView'
local menuModel = {}

local MENU_OPTIONS = {
    main = { "Start Game", "Multiplayer", "Options", "Exit" },
    pause = { "Resume", "Save", "Back to Main Menu", "Quit" },
    multiplayer = { "Host Game", "Join Game", "Back" },
    hostGame = { "Start Hosting", "Server Options", "Back" },
    joinGame = { "Connect to IP", "Recent Servers", "Back" },
    serverOptions = { "Max Players: 8", "Port: 12345", "Allow Spectators: Yes", "Back" }
}

local MENU_LAYOUTS = {
    main = {
        backgroundColor = { 0.1, 0.1, 0.1 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.3
    },
    pause = {
        backgroundColor = { 0, 0, 0, 0.8 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.3
    },
    multiplayer = {
        backgroundColor = { 0.1, 0.1, 0.3 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.3
    },
    hostGame = {
        backgroundColor = { 0.2, 0.2, 0.2 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.4
    },
    joinGame = {
        backgroundColor = { 0.2, 0.2, 0.5 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.4
    },
    serverOptions = {
        backgroundColor = { 0.15, 0.15, 0.15 },
        position = { x = 0, y = 1.7, z = -2 },
        spacing = 0.4
    }
}

function menuModel.createMenu(name, options, layout)
    -- Create the menu table with all properties
    local menu = {
        name = name,
        selectedOption = 1,  -- Always initialize selectedOption to 1
        options = options,
        layout = layout
    }

    function menu:load(messages)
        print(string.format("[%s] Menu loaded with options: %s", self.name, table.concat(self.options, ", ")))
        -- Ensure selectedOption is set to 1 on load
        self.selectedOption = 1
    end

    function menu:unload()
        print(string.format("[%s] Menu unloaded", self.name))
    end

    function menu:update(dt)
        -- Add update logic if needed
    end

    function menu:draw(pass)
        if not pass then return end
        menuView.drawMenu(
            pass,
            self.options,
            self.selectedOption,
            self.layout.backgroundColor,
            self.name == "pauseMenu"
        )
    end

    return menu
end


function menuModel.createMainMenu()
    return menuModel.createMenu("mainMenu", MENU_OPTIONS.main, MENU_LAYOUTS.main)
end

function menuModel.createPauseMenu()
    return menuModel.createMenu("pauseMenu", MENU_OPTIONS.pause, MENU_LAYOUTS.pause)
end

function menuModel.createMultiplayerMenu()
    return menuModel.createMenu("multiplayerMenu", MENU_OPTIONS.multiplayer, MENU_LAYOUTS.multiplayer)
end

function menuModel.createHostGameMenu()
    return menuModel.createMenu("hostGameMenu", MENU_OPTIONS.hostGame, MENU_LAYOUTS.hostGame)
end

function menuModel.createJoinGameMenu()
    return menuModel.createMenu("joinGameMenu", MENU_OPTIONS.joinGame, MENU_LAYOUTS.joinGame)
end

function menuModel.createServerOptionsMenu()
    return menuModel.createMenu("serverOptionsMenu", MENU_OPTIONS.serverOptions, MENU_LAYOUTS.serverOptions)
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
            pass:cube(0, 1.7, -1, .5, lovr.headset.getTime(), 0, 1, 0, 'line')
        end
    end

    return scene
end


return menuModel
