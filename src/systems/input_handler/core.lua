--[[
    InputHandler Core

    Base structure and constructor.
    This is the foundation that other modules extend via mixin pattern.
]]

local InputState = require("src.systems.input_handler.input_state")

---@class InputHandler
---@field contexts table<string, InputContext>      All registered contexts
---@field activeContexts table<string, boolean>     Currently active contexts
---@field states table<string, InputState>          State for each action
---@field _rawInputs table<string, boolean|number>  Raw inputs captured from callbacks
---@field _activeGamepad love.Joystick|nil          Active gamepad
---@field mouse InputHandlerMouse                   Mouse state
---@field settings InputHandlerSettings             Configuration
---@field _rebind RebindState                       Rebind mode state
---@field _defaultBindings table|nil                Default bindings backup
--- Rebinding methods (added by rebinding.lua mixin)
---@field setBinding fun(self: InputHandler, actionName: string, inputType: string, value: string|number, contextName?: string): boolean
---@field getBinding fun(self: InputHandler, actionName: string, inputType: string, contextName?: string): string|number|nil
---@field startRebind fun(self: InputHandler, actionName: string, inputType: string, callback?: function)
---@field cancelRebind fun(self: InputHandler)
---@field isRebinding fun(self: InputHandler): boolean
---@field getRebindInfo fun(self: InputHandler): table|nil
---@field exportBindings fun(self: InputHandler): table
---@field importBindings fun(self: InputHandler, data: table)
---@field saveAsDefault fun(self: InputHandler)
---@field resetBinding fun(self: InputHandler, actionName: string, contextName?: string)
---@field resetAllBindings fun(self: InputHandler)

---@class InputHandlerMouse
---@field x number
---@field y number
---@field dx number                    Delta from last frame
---@field dy number
---@field scroll { x: number, y: number }
---@field drag { active: boolean, startX: number, startY: number, button: number|nil }

---@class InputHandlerSettings
---@field axisThreshold number         Default threshold for axis (0.5)
---@field dragThreshold number         Minimum pixels to start drag (5)

---@class RebindState
---@field active boolean
---@field actionName string|nil
---@field inputType string|nil
---@field contextName string|nil
---@field callback function|nil
---@field originalAction InputAction|nil

local InputHandler = {}
InputHandler.__index = InputHandler

--- Creates a new InputHandler
---@param settings? InputHandlerSettings
---@return InputHandler
function InputHandler.new(settings)
    local self = setmetatable({}, InputHandler)

    self.contexts = {}
    self.activeContexts = {}
    self.states = {}
    self._rawInputs = {}
    self._activeGamepad = nil

    self.mouse = {
        x = 0,
        y = 0,
        dx = 0,
        dy = 0,
        scroll = { x = 0, y = 0 },
        drag = { active = false, startX = 0, startY = 0, button = nil },
    }

    self.settings = {
        axisThreshold = (settings and settings.axisThreshold) or 0.5,
        dragThreshold = (settings and settings.dragThreshold) or 5,
    }

    self._rebind = {
        active = false,
        actionName = nil,
        inputType = nil,
        contextName = nil,
        callback = nil,
        originalAction = nil,
    }

    self._defaultBindings = nil

    -- Detect gamepad on creation
    self:_detectGamepad()

    return self
end

--- Detects connected gamepad
---@private
function InputHandler:_detectGamepad()
    local joysticks = love.joystick.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isGamepad() then
            self._activeGamepad = joystick
            return
        end
    end
end

--- Callback for gamepad connected (call from love.joystickadded)
---@param joystick love.Joystick
function InputHandler:joystickAdded(joystick)
    if not self._activeGamepad and joystick:isGamepad() then
        self._activeGamepad = joystick
    end
end

--- Callback for gamepad disconnected (call from love.joystickremoved)
---@param joystick love.Joystick
function InputHandler:joystickRemoved(joystick)
    if self._activeGamepad == joystick then
        self._activeGamepad = nil
        self:_detectGamepad() -- look for another
    end
end

--- Creates states for all actions in a context
---@private
function InputHandler:_createStatesForContext(contextName)
    local context = self.contexts[contextName]
    if not context then return end

    for actionName, _ in pairs(context:getActions()) do
        if not self.states[actionName] then
            self.states[actionName] = InputState.new()
        end
    end
end

return InputHandler
