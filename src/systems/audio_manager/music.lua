---@class FadeState
---@field type "in"|"out"|"cross"
---@field elapsed number
---@field duration number
---@field fromVolume number
---@field toVolume number
---@field callback function|nil
---@field nextMusic string|nil
---@field nextMusicOptions table|nil

local Logger = require("src.logger")

---Music mixin for AudioManager
---@param AudioManager table
return function(AudioManager)
    ---Load a music track
    ---@param name string
    ---@param path? string full path or filename in musicPath
    function AudioManager:loadMusic(name, path)
        path = path or (self.settings.musicPath .. name)

        local success, result = pcall(love.audio.newSource, path, "stream")
        if success then
            self.music[name] = result
            Logger.debug(string.format("Loaded music: %s", name), "AudioManager")
        else
            Logger.warning(string.format("Failed to load music: %s from %s", name, path), "AudioManager")
        end
    end

    ---Play music
    ---@param name string
    ---@param options? {fadeIn: number|nil, loop: boolean, volume: number|nil}
    function AudioManager:playMusic(name, options)
        options = options or {}
        local loop = options.loop ~= false -- default true

        -- Stop current music
        if self.currentMusic then
            self.currentMusic:stop()
        end
        self._fadeState = nil

        -- Get or load music
        local source = self.music[name]
        if not source then
            -- Try to load
            self:loadMusic(name)
            source = self.music[name]
        end

        if not source then
            Logger.warning(string.format("Music not found: %s", name), "AudioManager")
            return
        end

        -- Clone for playback
        source = source:clone()
        source:setLooping(loop)

        -- Set volume
        local targetVolume = options.volume or 1.0
        if options.fadeIn then
            source:setVolume(0)
            self._fadeState = {
                type = "in",
                elapsed = 0,
                duration = options.fadeIn,
                fromVolume = 0,
                toVolume = targetVolume,
                callback = nil,
            }
        else
            source:setVolume(self:getEffectiveVolume("music") * targetVolume)
        end

        source:play()
        self.currentMusic = source
        self.currentMusicName = name
        self._musicTargetVolume = targetVolume

        Logger.debug(string.format("Playing music: %s", name), "AudioManager")
    end

    ---Stop current music
    ---@param fadeOut? number fade duration in seconds
    function AudioManager:stopMusic(fadeOut)
        if not self.currentMusic then return end

        if fadeOut and fadeOut > 0 then
            self:fadeOut(fadeOut, function()
                if self.currentMusic then
                    self.currentMusic:stop()
                    self.currentMusic = nil
                    self.currentMusicName = nil
                end
            end)
        else
            self.currentMusic:stop()
            self.currentMusic = nil
            self.currentMusicName = nil
            self._fadeState = nil
        end
    end

    ---Pause current music
    function AudioManager:pauseMusic()
        if self.currentMusic then
            self.currentMusic:pause()
        end
    end

    ---Resume current music
    function AudioManager:resumeMusic()
        if self.currentMusic then
            self.currentMusic:play()
        end
    end

    ---Fade in current music
    ---@param duration? number
    ---@param callback? function
    function AudioManager:fadeIn(duration, callback)
        if not self.currentMusic then return end

        duration = duration or self.settings.defaultFadeTime
        local targetVolume = self._musicTargetVolume or 1.0

        self._fadeState = {
            type = "in",
            elapsed = 0,
            duration = duration,
            fromVolume = self.currentMusic:getVolume() / self:getEffectiveVolume("music"),
            toVolume = targetVolume,
            callback = callback,
        }
    end

    ---Fade out current music
    ---@param duration? number
    ---@param callback? function
    function AudioManager:fadeOut(duration, callback)
        if not self.currentMusic then
            if callback then callback() end
            return
        end

        duration = duration or self.settings.defaultFadeTime

        self._fadeState = {
            type = "out",
            elapsed = 0,
            duration = duration,
            fromVolume = self._musicTargetVolume or 1.0,
            toVolume = 0,
            callback = callback,
        }
    end

    ---Crossfade to new music
    ---@param name string
    ---@param duration? number
    ---@param options? {loop: boolean, volume: number|nil}
    function AudioManager:crossfade(name, duration, options)
        duration = duration or self.settings.defaultFadeTime
        options = options or {}

        if not self.currentMusic then
            -- No current music, just play with fade in
            options.fadeIn = duration
            self:playMusic(name, options)
            return
        end

        -- Fade out current and fade in new
        self._fadeState = {
            type = "cross",
            elapsed = 0,
            duration = duration,
            fromVolume = self._musicTargetVolume or 1.0,
            toVolume = 0,
            nextMusic = name,
            nextMusicOptions = options,
        }
    end

    ---Check if music is playing
    ---@return boolean
    function AudioManager:isMusicPlaying()
        return self.currentMusic ~= nil and self.currentMusic:isPlaying()
    end

    ---Get current music name
    ---@return string|nil
    function AudioManager:getCurrentMusic()
        return self.currentMusicName
    end

    -- Override update to add fade logic
    local baseUpdate = AudioManager.update
    function AudioManager:update(dt)
        if baseUpdate then baseUpdate(self, dt) end

        -- Handle fading
        if self._fadeState and self.currentMusic then
            local fade = self._fadeState
            fade.elapsed = fade.elapsed + dt

            local progress = math.min(fade.elapsed / fade.duration, 1.0)
            local volume = fade.fromVolume + (fade.toVolume - fade.fromVolume) * progress

            self.currentMusic:setVolume(self:getEffectiveVolume("music") * volume)

            if progress >= 1.0 then
                if fade.type == "out" then
                    -- Fade out complete
                    if fade.callback then fade.callback() end
                elseif fade.type == "in" then
                    -- Fade in complete
                    self._musicTargetVolume = fade.toVolume
                    if fade.callback then fade.callback() end
                elseif fade.type == "cross" then
                    -- Crossfade: stop current and play next
                    self.currentMusic:stop()
                    self.currentMusic = nil
                    self.currentMusicName = nil

                    local opts = fade.nextMusicOptions or {}
                    opts.fadeIn = fade.duration
                    self:playMusic(fade.nextMusic, opts)
                    return -- New fade state created by playMusic
                end
                self._fadeState = nil
            end
        end
    end
end
