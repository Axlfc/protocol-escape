-- app/src/views/menuView.lua
local menuView = {}


-- Function to render the menu
function menuView.drawMenu(pass, options, selectedOption, backgroundColor, overlay, customShader)
    -- Clear any previous transformations
    pass:origin()
    
    -- Handle background differently for overlay vs main menu
    if overlay then
        -- Create a semi-transparent dark overlay that covers the whole view
        pass:setColor(0, 0, 0, 0.7)  -- Darker, consistent opacity
        pass:plane(0, 1.7, -3, 8, 8)  -- Larger plane to ensure full coverage
        
        -- Reset color for menu items
        pass:setColor(1, 1, 1)
    else
        -- For main menu, set the background color
        lovr.graphics.setBackgroundColor(unpack(backgroundColor))
    end

    -- Apply custom shader if provided
    if customShader then
        pass:setShader(customShader)
    end

    -- Save transform state
    pass:push()

    -- Ensure menu is rendered in front of the overlay
    local menuZ = overlay and -2 or -2  -- Adjust Z position based on whether it's an overlay

    -- Render each menu option with consistent positioning
    for i, option in ipairs(options) do
        local y = 1.7 - (i - 1) * 0.3
        local isSelected = i == selectedOption
        
        -- Set colors with proper opacity
        if isSelected then
            pass:setColor(1, 1, 0, 1)  -- Selected item: Yellow, fully opaque
        else
            pass:setColor(1, 1, 1, 1)  -- Regular items: White, fully opaque
        end
        
        -- Render text with consistent size and position
        pass:text(option, 0, y, menuZ, 0.2)
    end

    -- Restore transform state
    pass:pop()

    -- Reset rendering state
    pass:setColor(1, 1, 1, 1)
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
