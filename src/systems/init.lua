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

    Logger.info("[Systems] Done!")
end

return Systems
