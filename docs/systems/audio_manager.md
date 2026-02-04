# Audio Manager

Sistema di gestione audio per LÖVE2D con volume groups, fading, pooling SFX e integrazione StateMachine.

## Quick Start

```lua
-- Audio manager is initialized automatically via Game.audio
-- Load and play music
Game.audio:loadMusic("background", "assets/sounds/music/bg.ogg")
Game.audio:playMusic("background", { fadeIn = 1.5 })

-- Play sound effect
Game.audio:loadSound("jump", "assets/sounds/sfx/jump.ogg", 4)
Game.audio:playSound("jump")

-- Adjust volume
Game.audio:setVolume("master", 0.8)
Game.audio:setVolume("music", 0.5)
```

## Concepts

### Volume Groups

Three volume groups with multiplication:
- **master**: Global multiplier (default 1.0)
- **music**: Music volume (default 0.7)
- **sound**: SFX volume (default 1.0)

Effective volume = `master × group`

### Fading

```lua
-- Play with fade in
Game.audio:playMusic("theme", { fadeIn = 2.0 })

-- Fade out and stop
Game.audio:stopMusic(1.5)

-- Crossfade to new track
Game.audio:crossfade("newtrack", 1.0)
```

### Pooling

SFX pooling prevents overlapping sound cutoff:
1. Find available (stopped) source
2. Clone if pool not full
3. Reuse oldest if pool full

```lua
Game.audio:loadSound("shot", "shot.ogg", 8)  -- pool of 8
```

### State Integration

```lua
-- Map states to music
Game.audio:setStateMusic({
    menu = "menu_theme",
    gameplay = "gameplay_theme",
    pause = false,  -- don't change (overlay)
})

-- Bind to StateMachine
Game.audio:bindStateMachine(Game.stateMachine)
```

## API Reference

### Core

| Method | Description |
|--------|-------------|
| `new(settings?)` | Create instance |
| `getEffectiveVolume(group)` | Get master × group |
| `setVolume(group, volume)` | Set volume (0-1) |
| `getVolume(group)` | Get volume |
| `update(dt)` | Update (fading) |
| `stopAll()` | Stop all audio |
| `pauseAll()` | Pause all |
| `resumeAll()` | Resume all |

### Music

| Method | Description |
|--------|-------------|
| `loadMusic(name, path?)` | Load music (stream) |
| `playMusic(name, options?)` | Play music |
| `stopMusic(fadeOut?)` | Stop with optional fade |
| `pauseMusic()` | Pause |
| `resumeMusic()` | Resume |
| `fadeIn(duration?, callback?)` | Fade in |
| `fadeOut(duration?, callback?)` | Fade out |
| `crossfade(name, duration?)` | Crossfade to new |
| `isMusicPlaying()` | Check if playing |
| `getCurrentMusic()` | Get current name |

**playMusic options:**
```lua
{ fadeIn = 2.0, loop = true, volume = 1.0 }
```

### SFX

| Method | Description |
|--------|-------------|
| `loadSound(name, path?, poolSize?)` | Load sound (static) |
| `playSound(name, options?)` | Play with pooling |
| `stopSound(name)` | Stop all instances |
| `preloadSounds(list)` | Batch preload |

**playSound options:**
```lua
{ volume = 1.0, pitch = 1.0, loop = false }
```

### State Integration

| Method | Description |
|--------|-------------|
| `setStateMusic(mapping)` | Set state→music map |
| `bindStateMachine(sm)` | Bind to StateMachine |
| `unbindStateMachine()` | Unbind |
| `onStateChange(new, old)` | Handle state change |

## Configuration

Edit `src/constants/audio_defaults.lua`:

```lua
AudioDefaults.settings = {
    musicPath = "assets/sounds/music/",
    soundPath = "assets/sounds/sfx/",
    defaultFadeTime = 1.0,
    defaultPoolSize = 4,
}

AudioDefaults.stateMusic = {
    menu = "menu_theme",
}

AudioDefaults.preloadSounds = {
    { name = "jump", path = "jump.ogg", poolSize = 4 },
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No sound | Check `getVolume("master")` > 0 |
| Warning: file not found | File path relative to project root |
| Music not changing | Check `stateMusic` mapping |
| SFX cutting off | Increase `poolSize` |
