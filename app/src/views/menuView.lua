-- app/src/views/menuView.lua
local menuView = {}


-- Function to render the menu
function menuView.drawMenu(pass, options, selectedOption, backgroundColor, overlay, customShader)
    -- Set the background
    if overlay then
        pass:setColor(unpack(backgroundColor))
        pass:plane(0, 1.7, -2, 4, 4)  -- Semi-transparent background
    else
        lovr.graphics.setBackgroundColor(unpack(backgroundColor))
    end

    -- Apply a custom shader if provided
    if customShader then
        pass:setShader(customShader)
    end

    pass:push() -- Save the current transform state
    pass:origin() -- Reset to the default transform (no rotations or translations)

    -- Render menu options
    for i, option in ipairs(options) do
        local y = 1.7 - (i - 1) * 0.3
        local isSelected = i == selectedOption
        pass:setColor(isSelected and {1, 1, 0} or {1, 1, 1})
        pass:text(option, 0, y, -2, 0.2)
    end

    pass:pop() -- Restore the previous transform state

    -- Reset the shader to default after drawing
    if customShader then
        pass:setShader(nil)
    end
end


-- Function to notify the controller when an option is selected
function menuView.notifyOptionSelected(controller, option)
    controller.handleOptionSelected(option)
end


-- Example custom shaders for testing
menuView.shaders = {
    -- Shader with a simple color effect
    simpleColorShader = lovr.graphics.newShader(
        [[
        vec4 lovrmain() {
            return DefaultPosition;
        }
        ]],
        [[
        vec4 lovrmain() {
            vec3 color = vec3(1.0, sin(Time) * 0.5 + 0.5, cos(Time) * 0.5 + 0.5);
            return vec4(color, 1.0);
        }
        ]]
    ),

    -- Shader with a gradient effect
    gradientShader = lovr.graphics.newShader(
        [[
        vec4 lovrmain() {
            return DefaultPosition;
        }
        ]],
        [[
        vec4 lovrmain() {
            float gradient = UV.y;
            return vec4(gradient, gradient * 0.5, 1.0 - gradient, 1.0);
        }
        ]]
    ),

    -- Shader with a wavy distortion effect
    wavyShader = lovr.graphics.newShader(
        [[
        vec4 lovrmain() {
            return DefaultPosition;
        }
        ]],
        [[
        vec4 lovrmain() {
            float wave = sin(UV.x * 10.0 + Time) * 0.05;
            return vec4(UV.x + wave, UV.y, 0.5, 1.0);
        }
        ]]
    )
}

return menuView
