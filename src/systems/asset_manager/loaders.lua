---@class Loaders
local Loaders = {}

---Load an image/sprite
---@param path string
---@return love.Image|nil
function Loaders.sprite(path)
    local success, result = pcall(love.graphics.newImage, path)
    if success then
        return result
    end
    return nil
end

---Load an audio source
---@param path string
---@param sourceType? "static"|"stream" defaults to "static"
---@return love.Source|nil
function Loaders.audio(path, sourceType)
    sourceType = sourceType or "static"
    local success, result = pcall(love.audio.newSource, path, sourceType)
    if success then
        return result
    end
    return nil
end

---Load a font
---@param path string
---@param size number
---@return love.Font|nil
function Loaders.font(path, size)
    local success, result = pcall(love.graphics.newFont, path, size)
    if success then
        return result
    end
    return nil
end

---Load a shader
---@param path string
---@return love.Shader|nil
function Loaders.shader(path)
    -- Read shader file content first
    local file = love.filesystem.read(path)
    if not file then
        return nil
    end

    local success, result = pcall(love.graphics.newShader, file)
    if success then
        return result
    end
    return nil
end

return Loaders
