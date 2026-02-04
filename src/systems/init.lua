local Logger = require("src.logger")

local Systems = {}

function Systems:load()
    Systems.entity = require("src.systems.entity")
    Logger.info("Entity system loaded", "Systems")

    Systems.entityManager = require("src.systems.entity_manager")
    Systems.entityManager.new()
    Logger.info("Entity manager system loaded", "Systems")

    Systems.stateMachine = require("src.systems.state_machine")
    Systems.stateMachine.new()
    Logger.info("State machine system loaded", "Systems")

    -- Input Handler System
    local inputModule = require("src.systems.input_handler.init")
    Systems.inputHandler = inputModule.InputHandler
    Systems.inputHandler.setupFromDefaults = inputModule.InputHandler.setupFromDefaults
    -- Expose components for advanced use
    Systems.InputAction = inputModule.InputAction
    Systems.InputState = inputModule.InputState
    Systems.InputContext = inputModule.InputContext
    Logger.info("Input handler system loaded", "Systems")

    -- Input Prompts System
    Systems.InputPrompts = require("src.systems.input_handler.input_prompts")
    Logger.info("Input prompts system loaded", "Systems")

    -- Asset Manager System
    Systems.assetManager = require("src.systems.asset_manager")
    Logger.info("Asset manager system loaded", "Systems")

    -- Audio Manager System
    Systems.audioManager = require("src.systems.audio_manager")
    Logger.info("Audio manager system loaded", "Systems")

    Logger.info("Done!", "Systems")
end

return Systems
