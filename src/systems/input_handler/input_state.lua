--[[
    InputState

    Tracks the state of an input frame by frame (pressed/held/released).
    Allows distinguishing between:
    - pressed: first frame the input is active
    - down: input currently active (includes pressed)
    - released: first frame the input is no longer active
]]

---@class InputState
---@field down boolean           Currently pressed
---@field pressed boolean        Just pressed (only this frame)
---@field released boolean       Just released (only this frame)
---@field downDuration number    Seconds held pressed
---@field _wasDown boolean       Previous frame state (internal)

local InputState = {}
InputState.__index = InputState

--- Creates a new InputState
---@return InputState
function InputState.new()
    local self = setmetatable({}, InputState)

    self.down = false
    self.pressed = false
    self.released = false
    self.downDuration = 0
    self._wasDown = false

    return self
end

--- Updates the state based on current input
---@param isCurrentlyDown boolean  Is the input pressed now?
---@param dt number                Delta time
function InputState:update(isCurrentlyDown, dt)
    -- Detect transitions
    self.pressed = isCurrentlyDown and not self._wasDown
    self.released = not isCurrentlyDown and self._wasDown

    -- Update down state
    self.down = isCurrentlyDown

    -- Track duration
    if self.down then
        self.downDuration = self.downDuration + dt
    else
        self.downDuration = 0
    end

    -- Store for next frame
    self._wasDown = isCurrentlyDown
end

--- Reset flags at end of frame (called by InputHandler:lateUpdate)
function InputState:reset()
    -- NOTE: Don't reset pressed/released here!
    -- They get naturally reset on next update()
    -- This method exists for special cases if needed
end

--- Complete reset (for context switch or other)
function InputState:clear()
    self.down = false
    self.pressed = false
    self.released = false
    self.downDuration = 0
    self._wasDown = false
end

--- Consume pressed/released without causing re-trigger
--- Use when switching contexts while key is still physically pressed
function InputState:consume()
    self.pressed = false
    self.released = false
    -- Keep _wasDown as-is to prevent re-triggering pressed on next update
end

return InputState
