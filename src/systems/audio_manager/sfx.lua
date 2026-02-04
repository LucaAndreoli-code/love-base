---@class SoundEntry
---@field source love.Source
---@field pool love.Source[]
---@field poolSize number

local Logger = require("src.logger")

---SFX mixin for AudioManager
---@param AudioManager table
return function(AudioManager)
    ---Load a sound effect
    ---@param name string
    ---@param path? string full path or filename in soundPath
    ---@param poolSize? number default from settings
    function AudioManager:loadSound(name, path, poolSize)
        path = path or (self.settings.soundPath .. name)
        poolSize = poolSize or self.settings.defaultPoolSize

        local success, result = pcall(love.audio.newSource, path, "static")
        if success then
            ---@type SoundEntry
            self.sounds[name] = {
                source = result,
                pool = { result },
                poolSize = poolSize,
            }
            Logger.debug(string.format("Loaded sound: %s (pool size: %d)", name, poolSize), "AudioManager")
        else
            Logger.warning(string.format("Failed to load sound: %s from %s", name, path), "AudioManager")
        end
    end

    ---Play a sound effect
    ---@param name string
    ---@param options? {volume: number|nil, pitch: number|nil, loop: boolean}
    ---@return love.Source|nil
    function AudioManager:playSound(name, options)
        options = options or {}
        local volume = options.volume or 1.0
        local pitch = options.pitch or 1.0
        local loop = options.loop or false

        -- Get or load sound
        local entry = self.sounds[name]
        if not entry then
            -- Try to load
            self:loadSound(name)
            entry = self.sounds[name]
        end

        if not entry then
            Logger.warning(string.format("Sound not found: %s", name), "AudioManager")
            return nil
        end

        -- Find available source from pool
        local source = nil

        -- 1. Find a stopped source
        for _, src in ipairs(entry.pool) do
            if not src:isPlaying() then
                source = src
                break
            end
        end

        -- 2. Clone if pool not full
        if not source and #entry.pool < entry.poolSize then
            source = entry.source:clone()
            table.insert(entry.pool, source)
        end

        -- 3. Reuse oldest (first in pool, stop and restart)
        if not source then
            source = entry.pool[1]
            source:stop()
        end

        -- Configure and play
        source:setVolume(self:getEffectiveVolume("sound") * volume)
        source:setPitch(pitch)
        source:setLooping(loop)
        source:play()

        return source
    end

    ---Stop a specific sound
    ---@param name string
    function AudioManager:stopSound(name)
        local entry = self.sounds[name]
        if not entry then return end

        for _, src in ipairs(entry.pool) do
            src:stop()
        end
    end

    ---Preload multiple sounds
    ---@param soundList table[] array of {name: string, path?: string, poolSize?: number}
    function AudioManager:preloadSounds(soundList)
        for _, sound in ipairs(soundList) do
            self:loadSound(sound.name, sound.path, sound.poolSize)
        end
        Logger.debug(string.format("Preloaded %d sounds", #soundList), "AudioManager")
    end
end
