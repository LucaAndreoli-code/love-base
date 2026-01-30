local Logger = require("src.logger")

local Systems = {}

function Systems:load()
    Systems.entity = require("src.systems.entity")
    Logger.info("[Systems] Entity system loaded")

    Systems.entityManager = require("src.systems.entity_manager")
    Systems.entityManager.new()
    Logger.info("[Systems] Entity manager system loaded")

    Systems.stateMachine = require("src.systems.state_machine")
    Systems.stateMachine.new()
    Logger.info("[Systems] State machine system loaded")

    -- Input Handler System
    local inputModule = require("src.systems.input_handler.init")
    Systems.inputHandler = inputModule.InputHandler
    Systems.inputHandler.setupFromDefaults = inputModule.InputHandler.setupFromDefaults
    -- Expose components for advanced use
    Systems.InputAction = inputModule.InputAction
    Systems.InputState = inputModule.InputState
    Systems.InputContext = inputModule.InputContext
    Logger.info("[Systems] Input handler system loaded")

    -- Input Prompts System
    Systems.InputPrompts = require("src.systems.input_handler.input_prompts")
    Logger.info("[Systems] Input prompts system loaded")

    Logger.info("[Systems] Done!")
end

return Systems
