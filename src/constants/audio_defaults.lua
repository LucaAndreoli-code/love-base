local AudioDefaults = {}

AudioDefaults.settings = {
    musicPath = "assets/sounds/music/",
    soundPath = "assets/sounds/sfx/",
    defaultFadeTime = 1.0,
    defaultMusicVolume = 0.7,
    defaultSoundVolume = 1.0,
    defaultMasterVolume = 1.0,
    defaultPoolSize = 4,
}

AudioDefaults.stateMusic = {
    -- empty by default
    -- format: stateName = "music_name" or false
}

AudioDefaults.preloadSounds = {
    -- empty by default
    -- format: { name = "jump", path = "jump.ogg", poolSize = 4 }
}

return AudioDefaults
