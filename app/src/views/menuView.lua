-- app/src/views/menuView.lua
local menuView = {}

-- Function to render the menu
function menuView.drawMenu(pass, options, selectedOption, backgroundColor, overlay)
    if overlay then
        pass:setColor(unpack(backgroundColor))
        pass:plane(0, 1.7, -2, 4, 4)  -- Semi-transparent background
    else
        lovr.graphics.setBackgroundColor(unpack(backgroundColor))
    end

    pass:push() -- Save the current transform state
    pass:origin() -- Reset to the default transform (no rotations or translations)

    for i, option in ipairs(options) do
        local y = 1.7 - (i - 1) * 0.3
        local isSelected = i == selectedOption
        pass:setColor(isSelected and {1, 1, 0} or {1, 1, 1})
        pass:text(option, 0, y, -2, 0.2)
    end

    pass:pop() -- Restore the previous transform state
end

-- Function to notify the controller when an option is selected
function menuView.notifyOptionSelected(controller, option)
    controller.handleOptionSelected(option)
end

return menuView