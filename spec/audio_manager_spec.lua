-- Mock LÖVE APIs for testing
_G.love = {
    audio = {
        newSource = function(path, type)
            return {
                path = path,
                type = type,
                _volume = 1.0,
                _pitch = 1.0,
                _looping = false,
                _playing = false,
                _paused = false,
                setVolume = function(self, v) self._volume = v end,
                getVolume = function(self) return self._volume end,
                setPitch = function(self, p) self._pitch = p end,
                setLooping = function(self, l) self._looping = l end,
                play = function(self)
                    self._playing = true; self._paused = false
                end,
                stop = function(self) self._playing = false end,
                pause = function(self)
                    self._paused = true; self._playing = false
                end,
                isPlaying = function(self) return self._playing end,
                clone = function(self)
                    local c = {}
                    for k, v in pairs(self) do c[k] = v end
                    return c
                end,
            }
        end,
    },
    filesystem = {
        getInfo = function(path)
            -- Simulate file exists
            return { type = "file" }
        end,
    },
}

-- Load Logger mock
package.loaded["src.logger"] = {
    debug = function() end,
    info = function() end,
    warning = function() end,
    error = function() end,
}

-- Load AudioManager
local AudioManager = require("src.systems.audio_manager")

describe("AudioManager", function()
    local manager

    before_each(function()
        manager = AudioManager.new()
    end)

    describe("Core", function()
        it("creates with default settings", function()
            assert.is_not_nil(manager)
            assert.equals(1.0, manager.volumes.master)
            assert.equals(0.7, manager.volumes.music)
            assert.equals(1.0, manager.volumes.sound)
        end)

        it("creates with custom settings", function()
            local custom = AudioManager.new({
                defaultMasterVolume = 0.5,
                defaultMusicVolume = 0.5,
            })
            assert.equals(0.5, custom.volumes.master)
            assert.equals(0.5, custom.volumes.music)
        end)

        it("calculates effective volume correctly", function()
            manager.volumes.master = 0.8
            manager.volumes.music = 0.5
            assert.equals(0.4, manager:getEffectiveVolume("music"))
        end)

        it("setVolume/getVolume work", function()
            manager:setVolume("master", 0.6)
            assert.equals(0.6, manager:getVolume("master"))
        end)

        it("stopAll doesn't crash with no audio", function()
            assert.has_no.errors(function()
                manager:stopAll()
            end)
        end)

        it("pauseAll/resumeAll don't crash with no audio", function()
            assert.has_no.errors(function()
                manager:pauseAll()
                manager:resumeAll()
            end)
        end)

        it("update doesn't crash", function()
            assert.has_no.errors(function()
                manager:update(0.016)
            end)
        end)
    end)

    describe("Music", function()
        it("loadMusic loads a source", function()
            manager:loadMusic("test", "test.ogg")
            assert.is_not_nil(manager.music["test"])
        end)

        it("playMusic with non-existent file doesn't crash", function()
            -- Override newSource to fail
            local origNew = love.audio.newSource
            love.audio.newSource = function() error("file not found") end

            assert.has_no.errors(function()
                manager:playMusic("nonexistent")
            end)

            love.audio.newSource = origNew
        end)

        it("playMusic/stopMusic cycle works", function()
            manager:loadMusic("test", "test.ogg")
            manager:playMusic("test")

            assert.is_true(manager:isMusicPlaying())
            assert.equals("test", manager:getCurrentMusic())

            manager:stopMusic()
            assert.is_nil(manager.currentMusic)
        end)

        it("isMusicPlaying returns correct state", function()
            assert.is_false(manager:isMusicPlaying())

            manager:loadMusic("test", "test.ogg")
            manager:playMusic("test")
            assert.is_true(manager:isMusicPlaying())
        end)

        it("fade updates volume over time", function()
            manager:loadMusic("test", "test.ogg")
            manager:playMusic("test", { fadeIn = 1.0 })

            local initVolume = manager.currentMusic._volume

            -- Simulate time passing
            manager:update(0.5) -- 50% through fade

            -- Volume should have increased
            assert.is_true(manager.currentMusic._volume > initVolume)
        end)

        it("pauseMusic/resumeMusic work", function()
            manager:loadMusic("test", "test.ogg")
            manager:playMusic("test")

            manager:pauseMusic()
            assert.is_false(manager.currentMusic:isPlaying())

            manager:resumeMusic()
            assert.is_true(manager.currentMusic:isPlaying())
        end)
    end)

    describe("SFX", function()
        it("loadSound creates entry with pool", function()
            manager:loadSound("test", "test.ogg", 4)
            assert.is_not_nil(manager.sounds["test"])
            assert.equals(4, manager.sounds["test"].poolSize)
        end)

        it("playSound with non-existent file returns nil, doesn't crash", function()
            local origNew = love.audio.newSource
            love.audio.newSource = function() error("file not found") end

            local result
            assert.has_no.errors(function()
                result = manager:playSound("nonexistent")
            end)
            assert.is_nil(result)

            love.audio.newSource = origNew
        end)

        it("playSound returns source", function()
            manager:loadSound("test", "test.ogg")
            local source = manager:playSound("test")
            assert.is_not_nil(source)
        end)

        it("pooling reuses stopped sources", function()
            manager:loadSound("test", "test.ogg", 2)

            local s1 = manager:playSound("test")
            local s2 = manager:playSound("test")

            -- Pool should have 2 sources
            assert.equals(2, #manager.sounds["test"].pool)

            -- Stop first and play again
            s1:stop()
            local s3 = manager:playSound("test")

            -- Should reuse stopped source
            assert.equals(2, #manager.sounds["test"].pool)
        end)

        it("pool doesn't exceed max size", function()
            manager:loadSound("test", "test.ogg", 2)

            manager:playSound("test")
            manager:playSound("test")
            manager:playSound("test")
            manager:playSound("test")

            -- Pool should not exceed poolSize
            assert.equals(2, #manager.sounds["test"].pool)
        end)

        it("preloadSounds loads multiple sounds", function()
            manager:preloadSounds({
                { name = "jump", path = "jump.ogg", poolSize = 4 },
                { name = "hit",  path = "hit.ogg" },
            })

            assert.is_not_nil(manager.sounds["jump"])
            assert.is_not_nil(manager.sounds["hit"])
        end)
    end)

    describe("State Integration", function()
        it("setStateMusic stores mapping", function()
            manager:setStateMusic({
                menu = "menu_theme",
                gameplay = "gameplay",
            })

            assert.equals("menu_theme", manager.stateMusic["menu"])
            assert.equals("gameplay", manager.stateMusic["gameplay"])
        end)

        it("onStateChange plays correct music", function()
            manager:loadMusic("menu_theme", "menu.ogg")
            manager:setStateMusic({
                menu = "menu_theme",
            })

            manager:onStateChange("menu", nil)
            assert.equals("menu_theme", manager:getCurrentMusic())
        end)

        it("false mapping doesn't change music", function()
            manager:loadMusic("bgm", "bgm.ogg")
            manager:playMusic("bgm")

            manager:setStateMusic({
                pause = false,
            })

            manager:onStateChange("pause", "gameplay")
            assert.equals("bgm", manager:getCurrentMusic())
        end)

        it("nil mapping doesn't change music", function()
            manager:loadMusic("bgm", "bgm.ogg")
            manager:playMusic("bgm")

            manager:setStateMusic({})

            manager:onStateChange("anystate", nil)
            assert.equals("bgm", manager:getCurrentMusic())
        end)
    end)

    describe("setupFromDefaults", function()
        it("applies settings and mapping", function()
            local defaults = {
                settings = {
                    defaultMusicVolume = 0.5,
                },
                stateMusic = {
                    menu = "menu_theme",
                },
                preloadSounds = {},
            }

            AudioManager.setupFromDefaults(manager, defaults)

            assert.equals(0.5, manager.settings.defaultMusicVolume)
            assert.equals("menu_theme", manager.stateMusic["menu"])
        end)
    end)
end)
