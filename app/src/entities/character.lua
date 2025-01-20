-- app/src/entities/character.lua
local pawn = require 'app.src.entities.pawn'

function pawn.new(name, position)
    local self = pawn.new(position)
    self.name = name
    self.health = 100

    function self.takeDamage(amount)
        self.health = self.health - amount
        print(self.name .. " took damage! Health:", self.health)
    end

    return self
end

return pawn
