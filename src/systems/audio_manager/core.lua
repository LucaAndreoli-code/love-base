---@class AudioManagerSettings
---@field musicPath string
---@field soundPath string
---@field defaultFadeTime number
---@field defaultMusicVolume number
---@field defaultSoundVolume number
---@field defaultMasterVolume number
---@field defaultPoolSize number

---@class AudioManager
---@field music table<string, love.Source>
---@field sounds table<string, SoundEntry>
---@field currentMusic love.Source|nil
---@field currentMusicName string|nil
---@field volumes table<string, number>
---@field settings AudioManagerSettings
---@field stateMusic table<string, string|false>
---@field _fadeState FadeState|nil
---@field _stateMachine table|nil
---@field _paused boolean
local AudioManager = {}
AudioManager.__index = AudioManager

local Logger = require("src.logger")

-- Default settings
local DEFAULT_SETTINGS = {
    musicPath = "assets/sounds/music/",
    soundPath = "assets/sounds/sfx/",
    defaultFadeTime = 1.0,
    defaultMusicVolume = 0.7,
    defaultSoundVolume = 1.0,
    defaultMasterVolume = 1.0,
    defaultPoolSize = 4,
}

---Create a new AudioManager instance
---@param settings? AudioManagerSettings
---@return AudioManager
function AudioManager.new(settings)
    local self = setmetatable({}, AudioManager)

    -- Merge with defaults
    self.settings = {}
    for k, v in pairs(DEFAULT_SETTINGS) do
        self.settings[k] = v
    end
    if settings then
        for k, v in pairs(settings) do
            self.settings[k] = v
        end
    end

    -- Initialize storage
    self.music = {}
    self.sounds = {}
    self.currentMusic = nil
    self.currentMusicName = nil
    self.stateMusic = {}
    self._fadeState = nil
    self._stateMachine = nil
    self._paused = false

    -- Initialize volumes
    self.volumes = {
        master = self.settings.defaultMasterVolume,
        music = self.settings.defaultMusicVolume,
        sound = self.settings.defaultSoundVolume,
    }

    Logger.debug("AudioManager created", "AudioManager")
    return self
end

---Get effective volume (master * group)
---@param group string "music"|"sound"
---@return number
function AudioManager:getEffectiveVolume(group)
    local groupVolume = self.volumes[group] or 1.0
    local masterVolume = self.volumes.master or 1.0
    return masterVolume * groupVolume
end

---Set volume for a group
---@param group string "master"|"music"|"sound"
---@param volume number 0.0 to 1.0
function AudioManager:setVolume(group, volume)
    volume = math.max(0, math.min(1, volume))
    self.volumes[group] = volume

    -- Update current music volume if changing music or master
    if (group == "music" or group == "master") and self.currentMusic then
        self.currentMusic:setVolume(self:getEffectiveVolume("music"))
    end

    Logger.debug(string.format("Volume %s set to %.2f", group, volume), "AudioManager")
end

---Get volume for a group
---@param group string "master"|"music"|"sound"
---@return number
function AudioManager:getVolume(group)
    return self.volumes[group] or 1.0
end

---Update function (called every frame)
---@param dt number delta time
function AudioManager:update(dt)
    -- Fade logic is implemented in music.lua mixin
end

---Stop all audio
function AudioManager:stopAll()
    -- Stop music
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentMusic = nil
        self.currentMusicName = nil
    end
    self._fadeState = nil

    -- Stop all sounds
    for _, entry in pairs(self.sounds) do
        if entry.source then
            entry.source:stop()
        end
        if entry.pool then
            for _, src in ipairs(entry.pool) do
                src:stop()
            end
        end
    end

    Logger.debug("All audio stopped", "AudioManager")
end

---Pause all audio
function AudioManager:pauseAll()
    if self._paused then return end
    self._paused = true

    if self.currentMusic then
        self.currentMusic:pause()
    end

    for _, entry in pairs(self.sounds) do
        if entry.source then
            entry.source:pause()
        end
        if entry.pool then
            for _, src in ipairs(entry.pool) do
                src:pause()
            end
        end
    end

    Logger.debug("All audio paused", "AudioManager")
end

---Resume all audio
function AudioManager:resumeAll()
    if not self._paused then return end
    self._paused = false

    if self.currentMusic then
        self.currentMusic:play()
    end

    -- Note: We don't resume sounds as they are typically short-lived
    Logger.debug("All audio resumed", "AudioManager")
end

return AudioManager
