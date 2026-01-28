local Logger = require("src.logger")

local UI = {}

UI.button = require("src.ui.button")

function UI:load()
    Logger.info("[UI] Done!")
end

return UI
