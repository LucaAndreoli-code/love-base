---@class AssetManager
---@field cache table<string, table<string, any>>
---@field placeholders table<string, any>
local AssetManager = {}

local Loaders = require("src.systems.asset_manager.loaders")
local Atlas = require("src.systems.asset_manager.atlas")
local Logger = require("src.logger")

-- Internal cache storage
AssetManager.cache = {
    sprites = {},
    audio = {},
    fonts = {},
    shaders = {},
    atlas = {},
}

-- Placeholders storage
AssetManager.placeholders = {}

---Initialize placeholder assets
---Called automatically on first require
local function initPlaceholders()
    -- Magenta 16x16 placeholder sprite
    local imgData = love.image.newImageData(16, 16)
    for y = 0, 15 do
        for x = 0, 15 do
            -- Checkerboard pattern: magenta and dark magenta
            if (x + y) % 2 == 0 then
                imgData:setPixel(x, y, 1, 0, 1, 1)     -- bright magenta
            else
                imgData:setPixel(x, y, 0.5, 0, 0.5, 1) -- dark magenta
            end
        end
    end
    AssetManager.placeholders.sprite = love.graphics.newImage(imgData)

    -- Silent audio placeholder (minimal valid source)
    local sampleRate = 44100
    local soundData = love.sound.newSoundData(1, sampleRate, 16, 1)
    soundData:setSample(0, 0)
    AssetManager.placeholders.audio = love.audio.newSource(soundData)

    -- Default font placeholder (LÖVE's built-in font)
    AssetManager.placeholders.font = love.graphics.getFont() or love.graphics.newFont(12)

    -- Shader placeholder is nil (shaders gracefully degrade when nil)
    AssetManager.placeholders.shader = nil

    -- Atlas placeholder (single-frame atlas with magenta sprite)
    AssetManager.placeholders.atlas = {
        image = AssetManager.placeholders.sprite,
        quads = {
            love.graphics.newQuad(0, 0, 16, 16, 16, 16)
        },
        frameWidth = 16,
        frameHeight = 16,
        columns = 1,
        rows = 1,
        frameCount = 1,
    }
end

-- Initialize placeholders immediately
initPlaceholders()

-------------------------------------------------
-- LOAD FUNCTIONS
-------------------------------------------------

---Load a single sprite
---@param name string
---@param path string
---@return boolean success
function AssetManager.loadSprite(name, path)
    local asset = Loaders.sprite(path)
    if asset then
        AssetManager.cache.sprites[name] = asset
        Logger.debug(string.format("Loaded sprite: %s", name), "AssetManager")
        return true
    end
    Logger.warning(string.format("Failed to load sprite: %s from %s", name, path), "AssetManager")
    return false
end

---Load a single audio source
---@param name string
---@param path string
---@param sourceType? "static"|"stream"
---@return boolean success
function AssetManager.loadAudio(name, path, sourceType)
    local asset = Loaders.audio(path, sourceType)
    if asset then
        AssetManager.cache.audio[name] = asset
        Logger.debug(string.format("Loaded audio: %s", name), "AssetManager")
        return true
    end
    Logger.warning(string.format("Failed to load audio: %s from %s", name, path), "AssetManager")
    return false
end

---Load a single font
---@param name string
---@param path string
---@param size number
---@return boolean success
function AssetManager.loadFont(name, path, size)
    local asset = Loaders.font(path, size)
    if asset then
        AssetManager.cache.fonts[name] = asset
        Logger.debug(string.format("Loaded font: %s", name), "AssetManager")
        return true
    end
    Logger.warning(string.format("Failed to load font: %s from %s", name, path), "AssetManager")
    return false
end

---Load a single shader
---@param name string
---@param path string
---@return boolean success
function AssetManager.loadShader(name, path)
    local asset = Loaders.shader(path)
    if asset then
        AssetManager.cache.shaders[name] = asset
        Logger.debug(string.format("Loaded shader: %s", name), "AssetManager")
        return true
    end
    Logger.warning(string.format("Failed to load shader: %s from %s", name, path), "AssetManager")
    return false
end

---Load a spritesheet atlas
---@param name string
---@param path string
---@param frameWidth number
---@param frameHeight number
---@return boolean success
function AssetManager.loadAtlas(name, path, frameWidth, frameHeight)
    local image = Loaders.sprite(path)
    if not image then
        Logger.warning(string.format("Failed to load atlas image: %s from %s", name, path), "AssetManager")
        return false
    end

    local atlasData = Atlas.create(image, frameWidth, frameHeight)
    if atlasData then
        AssetManager.cache.atlas[name] = atlasData
        Logger.debug(string.format("Loaded atlas: %s (%d frames)", name, atlasData.frameCount), "AssetManager")
        return true
    end
    Logger.warning(string.format("Failed to create atlas: %s", name), "AssetManager")
    return false
end

---Load assets from a manifest file
---@param path string path to manifest.lua
---@return number loaded count of successfully loaded assets
---@return number failed count of failed assets
function AssetManager.loadManifest(path)
    local chunk, err = love.filesystem.load(path)
    if not chunk then
        Logger.error(string.format("Failed to load manifest: %s - %s", path, err or "unknown error"), "AssetManager")
        return 0, 0
    end

    local success, result = pcall(chunk)
    if not success then
        Logger.error(string.format("Failed to execute manifest: %s - %s", path, result), "AssetManager")
        return 0, 0
    end
    local manifest = result

    local loaded, failed = 0, 0

    -- Load sprites
    if manifest.sprites then
        for name, spritePath in pairs(manifest.sprites) do
            if AssetManager.loadSprite(name, spritePath) then
                loaded = loaded + 1
            else
                failed = failed + 1
            end
        end
    end

    -- Load audio
    if manifest.audio then
        for name, data in pairs(manifest.audio) do
            if AssetManager.loadAudio(name, data.path, data.type) then
                loaded = loaded + 1
            else
                failed = failed + 1
            end
        end
    end

    -- Load fonts
    if manifest.fonts then
        for name, data in pairs(manifest.fonts) do
            if AssetManager.loadFont(name, data.path, data.size) then
                loaded = loaded + 1
            else
                failed = failed + 1
            end
        end
    end

    -- Load shaders
    if manifest.shaders then
        for name, shaderPath in pairs(manifest.shaders) do
            if AssetManager.loadShader(name, shaderPath) then
                loaded = loaded + 1
            else
                failed = failed + 1
            end
        end
    end

    -- Load atlas
    if manifest.atlas then
        for name, data in pairs(manifest.atlas) do
            if AssetManager.loadAtlas(name, data.path, data.frameWidth, data.frameHeight) then
                loaded = loaded + 1
            else
                failed = failed + 1
            end
        end
    end

    Logger.info(string.format("Manifest loaded: %d assets, %d failed", loaded, failed), "AssetManager")
    return loaded, failed
end

-------------------------------------------------
-- GET FUNCTIONS
-------------------------------------------------

---Get a sprite by name
---@param name string
---@return love.Image
function AssetManager.getSprite(name)
    local asset = AssetManager.cache.sprites[name]
    if asset then
        return asset
    end
    Logger.warning(string.format("Sprite not loaded: %s, returning placeholder", name), "AssetManager")
    return AssetManager.placeholders.sprite
end

---Get an audio source by name
---@param name string
---@return love.Source
function AssetManager.getAudio(name)
    local asset = AssetManager.cache.audio[name]
    if asset then
        return asset
    end
    Logger.warning(string.format("Audio not loaded: %s, returning placeholder", name), "AssetManager")
    return AssetManager.placeholders.audio
end

---Get a font by name
---@param name string
---@return love.Font
function AssetManager.getFont(name)
    local asset = AssetManager.cache.fonts[name]
    if asset then
        return asset
    end
    Logger.warning(string.format("Font not loaded: %s, returning placeholder", name), "AssetManager")
    return AssetManager.placeholders.font
end

---Get a shader by name
---@param name string
---@return love.Shader|nil
function AssetManager.getShader(name)
    local asset = AssetManager.cache.shaders[name]
    if asset then
        return asset
    end
    Logger.warning(string.format("Shader not loaded: %s, returning nil", name), "AssetManager")
    return AssetManager.placeholders.shader -- nil
end

---Get an atlas by name
---@param name string
---@return AtlasData
function AssetManager.getAtlas(name)
    local asset = AssetManager.cache.atlas[name]
    if asset then
        return asset
    end
    Logger.warning(string.format("Atlas not loaded: %s, returning placeholder", name), "AssetManager")
    return AssetManager.placeholders.atlas
end

---Get a specific quad from an atlas
---@param atlasName string
---@param frameIndex number 1-based
---@return love.Quad
function AssetManager.getQuad(atlasName, frameIndex)
    local atlasData = AssetManager.cache.atlas[atlasName]
    if not atlasData then
        Logger.warning(string.format("Atlas not loaded: %s, returning placeholder quad", atlasName), "AssetManager")
        return AssetManager.placeholders.atlas.quads[1]
    end

    local quad = atlasData.quads[frameIndex]
    if not quad then
        Logger.warning(string.format("Frame %d not found in atlas %s, returning frame 1", frameIndex, atlasName),
            "AssetManager")
        return atlasData.quads[1] or AssetManager.placeholders.atlas.quads[1]
    end
    return quad
end

-------------------------------------------------
-- UTILITY FUNCTIONS
-------------------------------------------------

---Check if an asset is loaded
---@param assetType string "sprites"|"audio"|"fonts"|"shaders"|"atlas"
---@param name string
---@return boolean
function AssetManager.isLoaded(assetType, name)
    return AssetManager.cache[assetType] ~= nil and AssetManager.cache[assetType][name] ~= nil
end

---Unload a specific asset
---@param assetType string "sprites"|"audio"|"fonts"|"shaders"|"atlas"
---@param name string
function AssetManager.unload(assetType, name)
    if AssetManager.cache[assetType] then
        AssetManager.cache[assetType][name] = nil
        Logger.debug(string.format("Unloaded %s: %s", assetType, name), "AssetManager")
    end
end

---Clear all cached assets
function AssetManager.clear()
    AssetManager.cache = {
        sprites = {},
        audio = {},
        fonts = {},
        shaders = {},
        atlas = {},
    }
    Logger.info("All assets cleared", "AssetManager")
end

---Get count of loaded assets
---@return table<string, number>
function AssetManager.getStats()
    local stats = {}
    for assetType, assets in pairs(AssetManager.cache) do
        local count = 0
        for _ in pairs(assets) do
            count = count + 1
        end
        stats[assetType] = count
    end
    return stats
end

return AssetManager
