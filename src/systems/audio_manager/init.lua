local AudioManager = require("src.systems.audio_manager.core")

-- Apply mixins
require("src.systems.audio_manager.music")(AudioManager)
require("src.systems.audio_manager.sfx")(AudioManager)
require("src.systems.audio_manager.state_integration")(AudioManager)

---Setup AudioManager from defaults configuration
---@param manager AudioManager
---@param defaults table
function AudioManager.setupFromDefaults(manager, defaults)
    if not defaults then return end

    -- Apply settings (already done in constructor, but allow override)
    if defaults.settings then
        for k, v in pairs(defaults.settings) do
            manager.settings[k] = v
        end
    end

    -- Set state-to-music mapping
    if defaults.stateMusic then
        manager:setStateMusic(defaults.stateMusic)
    end

    -- Preload sounds
    if defaults.preloadSounds and #defaults.preloadSounds > 0 then
        manager:preloadSounds(defaults.preloadSounds)
    end
end

return AudioManager
