---@diagnostic disable: undefined-global
-- Mock LÖVE APIs for testing outside LÖVE runtime
local mockImage = { getWidth = function() return 64 end, getHeight = function() return 64 end }
local mockSource = {}
local mockFont = {}
local mockShader = {}
local mockQuad = {}
local mockImageData = { setPixel = function() end }
local mockSoundData = { setSample = function() end }

-- Setup mocks before requiring modules
_G.love = {
    graphics = {
        newImage = function() return mockImage end,
        newFont = function() return mockFont end,
        newShader = function() return mockShader end,
        newQuad = function() return mockQuad end,
        getFont = function() return mockFont end,
    },
    audio = {
        newSource = function() return mockSource end,
    },
    image = {
        newImageData = function() return mockImageData end,
    },
    sound = {
        newSoundData = function() return mockSoundData end,
    },
    filesystem = {
        load = function(path)
            -- Return a mock manifest loader
            if path:match("manifest") then
                return function()
                    return {
                        sprites = { player = "assets/sprites/player.png" },
                        audio = { shoot = { path = "assets/sounds/shoot.wav", type = "static" } },
                    }
                end
            end
            return nil, "File not found"
        end,
        read = function() return "// shader code" end,
    },
}

-- Now require the modules
local Loaders = require("src.systems.asset_manager.loaders")
local Atlas = require("src.systems.asset_manager.atlas")
local AssetManager = require("src.systems.asset_manager")

describe("Loaders", function()
    describe("sprite", function()
        it("returns image on success", function()
            local result = Loaders.sprite("test.png")
            assert.is_not_nil(result)
        end)
    end)

    describe("audio", function()
        it("returns source on success", function()
            local result = Loaders.audio("test.wav", "static")
            assert.is_not_nil(result)
        end)

        it("defaults to static type", function()
            local result = Loaders.audio("test.wav")
            assert.is_not_nil(result)
        end)
    end)

    describe("font", function()
        it("returns font on success", function()
            local result = Loaders.font("test.ttf", 16)
            assert.is_not_nil(result)
        end)
    end)

    describe("shader", function()
        it("returns shader on success", function()
            local result = Loaders.shader("test.glsl")
            assert.is_not_nil(result)
        end)
    end)
end)

describe("Atlas", function()
    describe("create", function()
        it("creates atlas data from image", function()
            local data = Atlas.create(mockImage, 32, 32)

            assert.is_not_nil(data)
            assert.equals(32, data.frameWidth)
            assert.equals(32, data.frameHeight)
            assert.equals(2, data.columns) -- 64 / 32
            assert.equals(2, data.rows)    -- 64 / 32
            assert.equals(4, data.frameCount)
        end)

        it("returns nil for nil image", function()
            local data = Atlas.create(nil, 32, 32)
            assert.is_nil(data)
        end)

        it("returns nil when frame size exceeds image", function()
            local smallImage = { getWidth = function() return 16 end, getHeight = function() return 16 end }
            local data = Atlas.create(smallImage, 32, 32)
            assert.is_nil(data)
        end)
    end)

    describe("getQuad", function()
        it("returns quad by index", function()
            local data = Atlas.create(mockImage, 32, 32)
            local quad = Atlas.getQuad(data, 1)
            assert.is_not_nil(quad)
        end)

        it("returns nil for invalid index", function()
            local data = Atlas.create(mockImage, 32, 32)
            local quad = Atlas.getQuad(data, 99)
            assert.is_nil(quad)
        end)

        it("returns nil for nil atlas", function()
            local quad = Atlas.getQuad(nil, 1)
            assert.is_nil(quad)
        end)
    end)
end)

describe("AssetManager", function()
    before_each(function()
        AssetManager.clear()
    end)

    describe("placeholders", function()
        it("has sprite placeholder", function()
            assert.is_not_nil(AssetManager.placeholders.sprite)
        end)

        it("has audio placeholder", function()
            assert.is_not_nil(AssetManager.placeholders.audio)
        end)

        it("has font placeholder", function()
            assert.is_not_nil(AssetManager.placeholders.font)
        end)

        it("has nil shader placeholder", function()
            assert.is_nil(AssetManager.placeholders.shader)
        end)

        it("has atlas placeholder", function()
            assert.is_not_nil(AssetManager.placeholders.atlas)
            assert.equals(1, AssetManager.placeholders.atlas.frameCount)
        end)
    end)

    describe("loadSprite", function()
        it("loads and caches sprite", function()
            local success = AssetManager.loadSprite("test", "test.png")
            assert.is_true(success)
            assert.is_true(AssetManager.isLoaded("sprites", "test"))
        end)
    end)

    describe("loadAudio", function()
        it("loads and caches audio", function()
            local success = AssetManager.loadAudio("test", "test.wav", "static")
            assert.is_true(success)
            assert.is_true(AssetManager.isLoaded("audio", "test"))
        end)
    end)

    describe("loadAtlas", function()
        it("loads and caches atlas", function()
            local success = AssetManager.loadAtlas("test", "test.png", 32, 32)
            assert.is_true(success)
            assert.is_true(AssetManager.isLoaded("atlas", "test"))
        end)
    end)

    describe("getSprite", function()
        it("returns cached sprite", function()
            AssetManager.loadSprite("test", "test.png")
            local sprite = AssetManager.getSprite("test")
            assert.is_not_nil(sprite)
        end)

        it("returns placeholder for missing sprite", function()
            local sprite = AssetManager.getSprite("nonexistent")
            assert.equals(AssetManager.placeholders.sprite, sprite)
        end)
    end)

    describe("getQuad", function()
        it("returns quad from cached atlas", function()
            AssetManager.loadAtlas("test", "test.png", 32, 32)
            local quad = AssetManager.getQuad("test", 1)
            assert.is_not_nil(quad)
        end)

        it("returns placeholder quad for missing atlas", function()
            local quad = AssetManager.getQuad("nonexistent", 1)
            assert.equals(AssetManager.placeholders.atlas.quads[1], quad)
        end)
    end)

    describe("loadManifest", function()
        it("loads assets from manifest", function()
            local loaded, failed = AssetManager.loadManifest("assets/manifest.lua")
            assert.is_true(loaded >= 1)
        end)
    end)

    describe("isLoaded", function()
        it("returns false for unloaded asset", function()
            assert.is_false(AssetManager.isLoaded("sprites", "test"))
        end)

        it("returns true for loaded asset", function()
            AssetManager.loadSprite("test", "test.png")
            assert.is_true(AssetManager.isLoaded("sprites", "test"))
        end)
    end)

    describe("unload", function()
        it("removes asset from cache", function()
            AssetManager.loadSprite("test", "test.png")
            AssetManager.unload("sprites", "test")
            assert.is_false(AssetManager.isLoaded("sprites", "test"))
        end)
    end)

    describe("clear", function()
        it("removes all assets", function()
            AssetManager.loadSprite("test1", "test.png")
            AssetManager.loadSprite("test2", "test.png")
            AssetManager.clear()

            local stats = AssetManager.getStats()
            assert.equals(0, stats.sprites)
        end)
    end)

    describe("getStats", function()
        it("returns correct counts", function()
            AssetManager.loadSprite("s1", "test.png")
            AssetManager.loadSprite("s2", "test.png")
            AssetManager.loadAudio("a1", "test.wav")

            local stats = AssetManager.getStats()
            assert.equals(2, stats.sprites)
            assert.equals(1, stats.audio)
        end)
    end)
end)
