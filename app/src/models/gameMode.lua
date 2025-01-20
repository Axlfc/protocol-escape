-- app/src/models/gameMode.lua
local gameMode = {}


function gameMode.new()
    local self = {
        name = "DefaultGameMode",
        rules = {},       -- Game rules
        state = {},       -- Game state
    }

    function self.start()
        print("[GameMode] Starting game mode:", self.name)
        self.state.running = true
    end

    function self.stop()
        print("[GameMode] Stopping game mode:", self.name)
        self.state.running = false
    end

    function self.update(dt)
        if self.state.running then
            -- Update game rules
        end
    end

    return self
end


return gameMode
