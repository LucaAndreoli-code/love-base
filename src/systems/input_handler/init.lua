--[[
    Input Handler System

    Aggregator that assembles InputHandler from modular components using mixin pattern.
    Each mixin adds methods to the base InputHandler class.
]]

-- Load base components (data structures)
local InputAction = require("src.systems.input_handler.input_action")
local InputState = require("src.systems.input_handler.input_state")
local InputContext = require("src.systems.input_handler.input_context")

-- Load core InputHandler (constructor and base methods)
local InputHandler = require("src.systems.input_handler.core")

-- Apply mixins to extend InputHandler
require("src.systems.input_handler.context")(InputHandler)
require("src.systems.input_handler.events")(InputHandler)
require("src.systems.input_handler.query")(InputHandler)
require("src.systems.input_handler.rebinding")(InputHandler)

--------------------------------------------------
-- Setup Helper (part of the aggregator)
--------------------------------------------------

--- Initializes InputHandler with default configuration
---@param handler InputHandler
---@param defaults table  InputDefaults
function InputHandler.setupFromDefaults(handler, defaults)
    -- Create all actions
    local actions = {}
    for actionName, config in pairs(defaults.actions) do
        config.name = actionName
        actions[actionName] = InputAction.new(config)
    end

    -- Create contexts and assign actions
    for contextName, actionNames in pairs(defaults.contexts) do
        local context = InputContext.new(contextName)

        for _, actionName in ipairs(actionNames) do
            if actions[actionName] then
                context:addAction(actions[actionName]:clone())
            end
        end

        handler:addContext(context)
    end

    -- Save as default for reset
    handler:saveAsDefault()
end

--------------------------------------------------
-- Exports
--------------------------------------------------

return {
    InputAction = InputAction,
    InputState = InputState,
    InputContext = InputContext,
    InputHandler = InputHandler,
}
