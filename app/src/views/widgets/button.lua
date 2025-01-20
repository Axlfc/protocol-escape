-- app/src/views/widgets/button.lua
local button = {}

function button.new(label, onClick)
    local self = {
        label = label,
        onClick = onClick
    }

    function self.draw(pass, x, y, z)
        pass:setColor(0.2, 0.2, 0.2)
        pass:plane(x, y, z, 1, 0.3)
        pass:setColor(1, 1, 1)
        pass:text(self.label, x, y, z + 0.1, 0.2)
    end

    return self
end

return button
