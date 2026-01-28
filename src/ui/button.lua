local Game = require("src.init")

---@class ButtonConfig
---@field x number X position (center)
---@field y number Y position (center)
---@field width number Button width
---@field height number Button height
---@field text string Button label
---@field onClick? fun() Callback when clicked

---@class Button
---@field x number X position (center)
---@field y number Y position (center)
---@field width number Button width
---@field height number Button height
---@field text string Button label
---@field onClick? fun() Callback when clicked
---@field private _hovered boolean
---@field private _pressed boolean
---@field private _wasPressed boolean
local Button = {}
Button.__index = Button

---Creates a new Button
---@param config ButtonConfig
---@return Button
function Button.new(config)
    local self = setmetatable({}, Button)
    self.x = config.x or 0
    self.y = config.y or 0
    self.width = config.width or 100
    self.height = config.height or 40
    self.text = config.text or ""
    self.onClick = config.onClick

    self._hovered = false
    self._pressed = false
    self._wasPressed = false

    return self
end

---Checks if a point is inside the button (center-based)
---@param px number Point X
---@param py number Point Y
---@return boolean
function Button:containsPoint(px, py)
    local halfW = self.width / 2
    local halfH = self.height / 2
    return px >= self.x - halfW and px <= self.x + halfW
        and py >= self.y - halfH and py <= self.y + halfH
end

---Returns true if the button is currently hovered
---@return boolean
function Button:isHovered()
    return self._hovered
end

---Returns true if the button is currently pressed
---@return boolean
function Button:isPressed()
    return self._pressed
end

---Updates button state
---@param dt number Delta time (unused, for interface consistency)
function Button:update(dt)
    local mx, my = love.mouse.getPosition()
    local mouseDown = love.mouse.isDown(1)

    self._hovered = self:containsPoint(mx, my)
    self._pressed = self._hovered and mouseDown

    -- Detect click (release while hovered)
    if self._wasPressed and not mouseDown and self._hovered then
        if self.onClick then
            self.onClick()
        end
    end

    self._wasPressed = mouseDown and self._hovered
end

---Draws the button
function Button:draw()
    local Colors = Game.constants.colors

    local color
    if self._pressed then
        color = Colors.button.pressed
    elseif self._hovered then
        color = Colors.button.hovered
    else
        color = Colors.button.normal
    end

    local halfW = self.width / 2
    local halfH = self.height / 2
    local left = self.x - halfW
    local top = self.y - halfH

    -- Draw background
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", left, top, self.width, self.height)

    -- Draw border
    love.graphics.setColor(Colors.button.border)
    love.graphics.rectangle("line", left, top, self.width, self.height)

    -- Draw text (centered)
    love.graphics.setColor(Colors.text.primary)
    local font = love.graphics.getFont()
    local textW = font:getWidth(self.text)
    local textH = font:getHeight()
    love.graphics.print(self.text, self.x - textW / 2, self.y - textH / 2)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return Button
