local Logger = require("src.logger")

local Constants = {}

Constants.colors = require("src.constants.colors")
Constants.gameplay = require("src.constants.gameplay")

function Constants:load()
    Logger.info("[Constants] Done!")
end

return Constants
