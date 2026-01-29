---InputHandler class - manages input abstraction and action mapping
---@module input_handler.handler

local Logger = require("src.logger")
local Defaults = require("src.systems.input_handler.defaults")
local Utils = require("src.systems.input_handler.utils")
local Callbacks = require("src.systems.input_handler.callbacks")
local Queries = require("src.systems.input_handler.queries")
local Axis = require("src.systems.input_handler.axis")

---@class ActionState
---@field pressed boolean True only on the frame the action was pressed
---@field released boolean True only on the frame the action was released
---@field lastPressedAt number Timestamp of last press (love.timer.getTime())

---@class ActionBinding
---@field keyboard? string|string[] Keyboard key(s) for this action
---@field gamepad? string Gamepad button or axis binding

---@class InputEvent
---@field type "pressed"|"released"
---@field device "keyboard"|"gamepad"
---@field key string The key or button that triggered the event

---@class AxisDefinition
---@field negative string Action name for negative direction
---@field positive string Action name for positive direction

---@class InputHandler
---@field bindings table<string, ActionBinding> Action to key/button mappings
---@field axes table<string, AxisDefinition> Axis definitions
---@field activeDevice "keyboard"|"gamepad" Currently active input device
---@field deadzone number Stick deadzone threshold (0-1)
---@field state table<string, ActionState> Current state of each action
---@field eventQueue InputEvent[] Buffered input events for current frame
---@field gamepad love.Joystick|nil First connected gamepad
---@field gamepadAxisValues table<string, number> Raw gamepad axis values
local InputHandler = {}
InputHandler.__index = InputHandler

---Creates a new InputHandler
---@param config? {bindings?: table<string, ActionBinding>, deadzone?: number}
---@return InputHandler
function InputHandler.new(config)
    config = config or {}

    local self = setmetatable({}, InputHandler)

    -- Merge custom bindings with defaults
    if config.bindings then
        self.bindings = Utils.mergeBindings(Defaults.bindings, config.bindings)
    else
        self.bindings = Utils.deepCopy(Defaults.bindings)
    end

    self.axes = Utils.deepCopy(Defaults.axes)
    self.activeDevice = "keyboard"
    self.deadzone = config.deadzone or 0.2
    self.state = {}
    self.eventQueue = {}
    self.gamepad = nil
    self.gamepadAxisValues = {}

    -- Initialize state for all actions
    for action in pairs(self.bindings) do
        self.state[action] = {
            pressed = false,
            released = false,
            lastPressedAt = 0
        }
    end

    Logger.debug("InputHandler created", "InputHandler")

    return self
end

---Processes input events and updates action states. Must be called every frame.
function InputHandler:update()
    -- Update gamepad reference
    local joysticks = love.joystick.getJoysticks()
    local newGamepad = nil
    for _, js in ipairs(joysticks) do
        if js:isGamepad() then
            newGamepad = js
            break
        end
    end

    if newGamepad ~= self.gamepad then
        if newGamepad then
            Logger.debug("Gamepad connected: " .. newGamepad:getName(), "InputHandler")
        elseif self.gamepad then
            Logger.debug("Gamepad disconnected", "InputHandler")
        end
        self.gamepad = newGamepad
    end

    -- Read gamepad axis values
    if self.gamepad then
        self.gamepadAxisValues.leftx = self.gamepad:getGamepadAxis("leftx") or 0
        self.gamepadAxisValues.lefty = self.gamepad:getGamepadAxis("lefty") or 0
        self.gamepadAxisValues.rightx = self.gamepad:getGamepadAxis("rightx") or 0
        self.gamepadAxisValues.righty = self.gamepad:getGamepadAxis("righty") or 0
        self.gamepadAxisValues.triggerleft = self.gamepad:getGamepadAxis("triggerleft") or 0
        self.gamepadAxisValues.triggerright = self.gamepad:getGamepadAxis("triggerright") or 0
    end

    -- Clear previous frame's pressed/released states
    for action, actionState in pairs(self.state) do
        actionState.pressed = false
        actionState.released = false
    end

    -- Process queued events
    for _, event in ipairs(self.eventQueue) do
        local action = self:getActionForInput(event.key, event.device)
        if action and self.state[action] then
            if event.type == "pressed" then
                self.state[action].pressed = true
                self.state[action].lastPressedAt = love.timer.getTime()
            else
                self.state[action].released = true
            end
        end
    end

    -- Clear queue for next frame
    self.eventQueue = {}
end

---Changes the binding for an action
---@param action string Action to rebind
---@param deviceType "keyboard"|"gamepad"
---@param newKey string|string[] New key/button binding
function InputHandler:rebind(action, deviceType, newKey)
    if not self.bindings[action] then
        -- Create new action binding
        self.bindings[action] = {}
        self.state[action] = {
            pressed = false,
            released = false,
            lastPressedAt = 0
        }
    end

    self.bindings[action][deviceType] = newKey

    local keyStr = type(newKey) == "table" and table.concat(newKey, ", ") or newKey
    Logger.debug(string.format("Rebound action: %s, %s = %s", action, deviceType, keyStr), "InputHandler")
end

---Returns the current bindings table
---@return table<string, ActionBinding>
function InputHandler:getBindings()
    return self.bindings
end

---Returns the currently active input device
---@return "keyboard"|"gamepad"
function InputHandler:getActiveDevice()
    return self.activeDevice
end

---Sets the analog stick deadzone
---@param value number Deadzone threshold (0-1)
function InputHandler:setDeadzone(value)
    self.deadzone = math.max(0, math.min(1, value))
end

-- Delegate to Queries module

function InputHandler:getActionForInput(key, device)
    return Queries.getActionForInput(self, key, device)
end

function InputHandler:isKeyboardHeld(action)
    return Queries.isKeyboardHeld(self, action)
end

function InputHandler:isGamepadHeld(action)
    return Queries.isGamepadHeld(self, action)
end

function InputHandler:isHeld(action)
    return Queries.isHeld(self, action)
end

function InputHandler:isPressed(action)
    return Queries.isPressed(self, action)
end

function InputHandler:isReleased(action)
    return Queries.isReleased(self, action)
end

function InputHandler:wasPressedWithin(action, seconds)
    return Queries.wasPressedWithin(self, action, seconds)
end

-- Delegate to Axis module

function InputHandler:applyDeadzone(value)
    return Axis.applyDeadzone(self, value)
end

function InputHandler:getAxis(axisName)
    return Axis.getAxis(self, Queries, axisName)
end

-- Delegate to Callbacks module

function InputHandler:_onKeyPressed(key)
    Callbacks.onKeyPressed(self, key)
end

function InputHandler:_onKeyReleased(key)
    Callbacks.onKeyReleased(self, key)
end

function InputHandler:_onGamepadPressed(joystick, button)
    Callbacks.onGamepadPressed(self, joystick, button)
end

function InputHandler:_onGamepadReleased(joystick, button)
    Callbacks.onGamepadReleased(self, joystick, button)
end

function InputHandler:_onGamepadAxis(joystick, axis, value)
    Callbacks.onGamepadAxis(self, joystick, axis, value)
end

return InputHandler
