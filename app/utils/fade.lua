local fade = {
    opacity = 0,
    fadingOut = false,
    fadingIn = false,
    duration = 1, -- Duration of fade in/out in seconds
    callback = nil -- Function to call after fade-out completes
}

function fade:startFadeOut(onComplete)
    self.opacity = 0
    self.fadingOut = true
    self.fadingIn = false
    self.callback = onComplete -- Save the callback to trigger later
end

function fade:startFadeIn()
    self.opacity = 1
    self.fadingOut = false
    self.fadingIn = true
    self.callback = nil -- Clear callback for fade-in
end

function fade:update(dt)
    if self.fadingOut then
        self.opacity = math.min(1, self.opacity + dt / self.duration)
        if self.opacity >= 1 then
            self.fadingOut = false
            if self.callback then
                self.callback() -- Trigger the fade-out callback
            end
        end
    elseif self.fadingIn then
        self.opacity = math.max(0, self.opacity - dt / self.duration)
        if self.opacity <= 0 then
            self.fadingIn = false
        end
    end
end

function fade:draw(pass)
    if self.opacity > 0 then
        pass:setColor(0, 0, 0, self.opacity)
        pass:plane(0, 1.7, -3, 10, 10)
    end
end

return fade
