---@class Gameplay
---@field player PlayerConstants
---@field ball BallConstants
---@field screen ScreenConstants

---@class PlayerConstants
---@field speed number
---@field size number

---@class BallConstants
---@field minSpeed number
---@field maxSpeed number
---@field radius number

---@class ScreenConstants
---@field width number
---@field height number

local Gameplay = {
    screen = {
        width = 1280,
        height = 720
    }
}

return Gameplay
