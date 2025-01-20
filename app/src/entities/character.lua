-- app/src/entities/character.lua
local character = require('app.src.entities.pawn').new()

function character.new(name)
    local self = character
    self.name = name
    self.health = 100

    function self.takeDamage(amount)
        self.health = self.health - amount
        if self.health <= 0 then
            print(self.name, "is defeated")
        end
    end

    return self
end

return character
