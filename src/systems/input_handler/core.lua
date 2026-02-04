--[[
    InputHandler Core

    Base structure and constructor.
    This is the foundation that other modules extend via mixin pattern.
]]

local InputState = require("src.systems.input_handler.input_state")
local Logger = require("src.logger")

---@class InputHandlerMouse
---@field x number
---@field y number
---@field dx number
---@field dy number
---@field scroll { x: number, y: number }
---@field drag { active: boolean, startX: number, startY: number, button: number|nil }

---@class InputHandlerSettings
---@field axisThreshold number
---@field dragThreshold number

---@class RebindState
---@field active boolean
---@field actionName string|nil
---@field inputType string|nil
---@field contextName string|nil
---@field callback function|nil
---@field originalAction InputAction|nil

---@class InputHandler
---@field contexts table<string, InputContext>
---@field activeContexts table<string, boolean>
---@field states table<string, InputState>
---@field _rawInputs table<string, boolean|number>
---@field _activeGamepad love.Joystick|nil
---@field mouse InputHandlerMouse
---@field settings InputHandlerSettings
---@field _rebind RebindState
---@field _defaultBindings table|nil
---
------ Context methods (from context.lua)
---@field addContext fun(self: InputHandler, context: InputContext)
---@field removeContext fun(self: InputHandler, name: string): boolean
---@field getContext fun(self: InputHandler, name: string): InputContext|nil
---@field setContext fun(self: InputHandler, name: string)
---@field pushContext fun(self: InputHandler, name: string)
---@field popContext fun(self: InputHandler, name: string)
---@field isContextActive fun(self: InputHandler, name: string): boolean
---@field getActiveContexts fun(self: InputHandler): string[]
---@field clearContexts fun(self: InputHandler)
---
--- Event methods (from events.lua)
---@field keypressed fun(self: InputHandler, key: string, scancode: string, isrepeat: boolean)
---@field keyreleased fun(self: InputHandler, key: string, scancode: string)
---@field mousepressed fun(self: InputHandler, x: number, y: number, button: number, istouch: boolean, presses?: number)
---@field mousereleased fun(self: InputHandler, x: number, y: number, button: number, istouch: boolean, presses?: number)
---@field mousemoved fun(self: InputHandler, x: number, y: number, dx: number, dy: number)
---@field wheelmoved fun(self: InputHandler, x: number, y: number)
---@field gamepadpressed fun(self: InputHandler, joystick: love.Joystick, button: string)
---@field gamepadreleased fun(self: InputHandler, joystick: love.Joystick, button: string)
---@field gamepadaxis fun(self: InputHandler, joystick: love.Joystick, axis: string, value: number)
---
--- Query methods (from query.lua)
---@field update fun(self: InputHandler, dt: number)
---@field lateUpdate fun(self: InputHandler)
---@field isDown fun(self: InputHandler, actionName: string): boolean
---@field isPressed fun(self: InputHandler, actionName: string): boolean
---@field isReleased fun(self: InputHandler, actionName: string): boolean
---@field getHoldDuration fun(self: InputHandler, actionName: string): number
---@field getAxis fun(self: InputHandler, actionName: string): number
---@field getMousePosition fun(self: InputHandler): number, number
---@field getMouseScroll fun(self: InputHandler): number, number
---@field isDragging fun(self: InputHandler): boolean
---@field getDragDelta fun(self: InputHandler): number, number
---@field getDragStart fun(self: InputHandler): number, number
---@field getMouseDelta fun(self: InputHandler): number, number
---
--- Rebinding methods (from rebinding.lua)
---@field setBinding fun(self: InputHandler, actionName: string, inputType: string, value: string|number, contextName?: string): boolean
---@field getBinding fun(self: InputHandler, actionName: string, inputType: string, contextName?: string): string|number|nil
---@field startRebind fun(self: InputHandler, actionName: string, inputType: string, callback?: fun(success: boolean, newValue: string|number|nil))
---@field cancelRebind fun(self: InputHandler)
---@field isRebinding fun(self: InputHandler): boolean
---@field getRebindInfo fun(self: InputHandler): { actionName: string, inputType: string }|nil
---@field exportBindings fun(self: InputHandler): table
---@field importBindings fun(self: InputHandler, data: table)
---@field saveAsDefault fun(self: InputHandler)
---@field resetBinding fun(self: InputHandler, actionName: string, contextName?: string)
---@field resetAllBindings fun(self: InputHandler)

local InputHandler = {}
InputHandler.__index = InputHandler

---Creates a new InputHandler
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

    self:_detectGamepad()

    Logger.debug("InputHandler created", "InputHandler")

    return self
end

---Detects connected gamepad
---@private
function InputHandler:_detectGamepad()
    local joysticks = love.joystick.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isGamepad() then
            self._activeGamepad = joystick
            Logger.debug("Gamepad detected: " .. joystick:getName(), "InputHandler")
            return
        end
    end
end

---Callback for gamepad connected
---@param joystick love.Joystick
function InputHandler:joystickAdded(joystick)
    if not self._activeGamepad and joystick:isGamepad() then
        self._activeGamepad = joystick
        Logger.info("Gamepad connected: " .. joystick:getName(), "InputHandler")
    end
end

---Callback for gamepad disconnected
---@param joystick love.Joystick
function InputHandler:joystickRemoved(joystick)
    if self._activeGamepad == joystick then
        Logger.info("Gamepad disconnected", "InputHandler")
        self._activeGamepad = nil
        self:_detectGamepad()
    end
end

---Creates states for all actions in a context
---@private
---@param contextName string
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
