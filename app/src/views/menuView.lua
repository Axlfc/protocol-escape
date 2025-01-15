-- app/src/views/menuView.lua
local menuView = {}

function menuView.drawMenu(pass, options, selectedOption, backgroundColor, overlay)
    if overlay then
        pass:setColor(unpack(backgroundColor))
        pass:plane(0, 1.7, -2, 4, 4)  -- Semi-transparent background
    else
        lovr.graphics.setBackgroundColor(unpack(backgroundColor))
    end

    for i, option in ipairs(options) do
        local y = 1.7 - (i - 1) * 0.3
        local isSelected = i == selectedOption
        -- Highlight selected options in yellow, others in white
        pass:setColor(isSelected and {1, 1, 0} or {1, 1, 1})
        pass:text(option, 0, y, -2, 0.2)
    end
end

return menuView