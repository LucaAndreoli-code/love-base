---@class AtlasData
---@field image love.Image
---@field quads love.Quad[]
---@field frameWidth number
---@field frameHeight number
---@field columns number
---@field rows number
---@field frameCount number

---@class Atlas
local Atlas = {}

---Generate quads for a uniform grid spritesheet
---@param image love.Image
---@param frameWidth number
---@param frameHeight number
---@return AtlasData|nil
function Atlas.create(image, frameWidth, frameHeight)
    if not image then
        return nil
    end

    local imgWidth = image:getWidth()
    local imgHeight = image:getHeight()

    local columns = math.floor(imgWidth / frameWidth)
    local rows = math.floor(imgHeight / frameHeight)

    if columns == 0 or rows == 0 then
        return nil
    end

    local quads = {}
    local frameIndex = 1

    for row = 0, rows - 1 do
        for col = 0, columns - 1 do
            local x = col * frameWidth
            local y = row * frameHeight
            quads[frameIndex] = love.graphics.newQuad(
                x, y,
                frameWidth, frameHeight,
                imgWidth, imgHeight
            )
            frameIndex = frameIndex + 1
        end
    end

    ---@type AtlasData
    return {
        image = image,
        quads = quads,
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        columns = columns,
        rows = rows,
        frameCount = #quads,
    }
end

---Get a specific quad from atlas data
---@param atlasData AtlasData
---@param frameIndex number 1-based index
---@return love.Quad|nil
function Atlas.getQuad(atlasData, frameIndex)
    if not atlasData or not atlasData.quads then
        return nil
    end
    return atlasData.quads[frameIndex]
end

return Atlas
