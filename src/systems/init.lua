local Logger = require("src.logger")

local Systems = {}

function Systems:load()
    Systems.entity = require("src.systems.entity")
    Logger.info("[Systems] Entity system loaded")

    Systems.entity_manager = require("src.systems.entity_manager")
    Systems.entity_manager.new()
    Logger.info("[Systems] Entity manager system loaded")

    Systems.state_machine = require("src.systems.state_machine")
    Systems.state_machine.new()
    Logger.info("[Systems] State machine system loaded")

    Logger.info("[Systems] Done!")
end

return Systems
