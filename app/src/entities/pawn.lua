-- app/src/entities/pawn.lua
local pawn = {}

function pawn.new(position)
    local self = {
        position = position or { x = 0, y = 0, z = 0 }
    }

    function self.move(delta)
        self.position.x = self.position.x + delta.x
        self.position.y = self.position.y + delta.y
        self.position.z = self.position.z + delta.z
    end

    return self
end

return pawn
