# Asset Manager

The Asset Manager handles loading, caching, and accessing game assets (sprites, audio, fonts, shaders, and sprite atlases).

## Overview

- **Preload strategy**: Load all assets at startup via manifest
- **Placeholder system**: Missing assets return visible placeholders (magenta checkerboard for sprites)
- **Type-safe access**: Separate methods for each asset type

## Quick Start

```lua
local Game = require("src.init")

-- Load all assets from manifest
Game.systems.assetManager.loadManifest("assets/manifest.lua")

-- Use assets
local playerSprite = Game.systems.assetManager.getSprite("player")
local shootSound = Game.systems.assetManager.getAudio("shoot")
```

## Manifest Format

Create `assets/manifest.lua`:

```lua
return {
    sprites = {
        player = "assets/sprites/player.png",
        enemy = "assets/sprites/enemy.png",
    },
    
    audio = {
        shoot = { path = "assets/sounds/shoot.wav", type = "static" },
        music = { path = "assets/sounds/bgm.ogg", type = "stream" },
    },
    
    fonts = {
        main = { path = "assets/font/pixel.ttf", size = 16 },
        title = { path = "assets/font/pixel.ttf", size = 32 },
    },
    
    shaders = {
        glow = "shaders/glow.glsl",
    },
    
    atlas = {
        playerAnim = { 
            path = "assets/sprites/player_sheet.png", 
            frameWidth = 32, 
            frameHeight = 32 
        },
    },
}
```

## API Reference

### Loading

#### `loadManifest(path)`
Load multiple assets from a manifest file.
```lua
local loaded, failed = Game.systems.assetManager.loadManifest("assets/manifest.lua")
print(string.format("Loaded %d assets, %d failed", loaded, failed))
```

#### `loadSprite(name, path)`
Load a single sprite.
```lua
Game.systems.assetManager.loadSprite("player", "assets/sprites/player.png")
```

#### `loadAudio(name, path, sourceType)`
Load a single audio source. `sourceType` is "static" (default) or "stream".
```lua
Game.systems.assetManager.loadAudio("music", "assets/sounds/bgm.ogg", "stream")
```

#### `loadFont(name, path, size)`
Load a font at a specific size.
```lua
Game.systems.assetManager.loadFont("main", "assets/font/pixel.ttf", 16)
```

#### `loadShader(name, path)`
Load a GLSL shader.
```lua
Game.systems.assetManager.loadShader("glow", "shaders/glow.glsl")
```

#### `loadAtlas(name, path, frameWidth, frameHeight)`
Load a spritesheet as an atlas with uniform grid frames.
```lua
Game.systems.assetManager.loadAtlas("playerAnim", "assets/sprites/player.png", 32, 32)
```

### Accessing

#### `getSprite(name)` → `love.Image`
Returns the sprite or a magenta placeholder if not loaded.

#### `getAudio(name)` → `love.Source`
Returns the audio source or a silent placeholder.

#### `getFont(name)` → `love.Font`
Returns the font or LÖVE's default font.

#### `getShader(name)` → `love.Shader|nil`
Returns the shader or nil (shaders gracefully disable when nil).

#### `getAtlas(name)` → `AtlasData`
Returns atlas data containing image and quads.

#### `getQuad(atlasName, frameIndex)` → `love.Quad`
Returns a specific frame (1-indexed) from an atlas.
```lua
-- Draw frame 3 of player animation
local atlas = Game.systems.assetManager.getAtlas("playerAnim")
local quad = Game.systems.assetManager.getQuad("playerAnim", 3)
love.graphics.draw(atlas.image, quad, x, y)
```

### Utilities

#### `isLoaded(assetType, name)` → `boolean`
Check if an asset is loaded.
```lua
if Game.systems.assetManager.isLoaded("sprites", "player") then
    -- asset ready
end
```

#### `unload(assetType, name)`
Remove an asset from cache to free memory.
```lua
Game.systems.assetManager.unload("audio", "menuMusic")
```

#### `clear()`
Remove all cached assets.

#### `getStats()` → `table<string, number>`
Get count of loaded assets by type.
```lua
local stats = Game.systems.assetManager.getStats()
print(stats.sprites)  -- number of loaded sprites
```

## Atlas (Spritesheet) System

Atlases use a uniform grid layout. Frames are numbered left-to-right, top-to-bottom, starting at 1.

### Frame Layout Example
For a 128x64 image with 32x32 frames:
```
+---+---+---+---+
| 1 | 2 | 3 | 4 |
+---+---+---+---+
| 5 | 6 | 7 | 8 |
+---+---+---+---+
```

### AtlasData Structure
```lua
---@class AtlasData
---@field image love.Image       -- The spritesheet image
---@field quads love.Quad[]      -- Array of quads (1-indexed)
---@field frameWidth number      -- Width of each frame
---@field frameHeight number     -- Height of each frame
---@field columns number         -- Number of columns
---@field rows number            -- Number of rows
---@field frameCount number      -- Total number of frames
```

### Animation Example
```lua
local currentFrame = 1
local frameTimer = 0
local frameDuration = 0.1

function love.update(dt)
    frameTimer = frameTimer + dt
    if frameTimer >= frameDuration then
        frameTimer = frameTimer - frameDuration
        local atlas = Game.systems.assetManager.getAtlas("playerRun")
        currentFrame = (currentFrame % atlas.frameCount) + 1
    end
end

function love.draw()
    local atlas = Game.systems.assetManager.getAtlas("playerRun")
    local quad = Game.systems.assetManager.getQuad("playerRun", currentFrame)
    love.graphics.draw(atlas.image, quad, player.x, player.y)
end
```

## Placeholders

When an asset fails to load or is requested before loading, placeholders are returned:

| Type | Placeholder |
|------|-------------|
| sprites | 16x16 magenta/dark magenta checkerboard |
| audio | Silent audio source |
| fonts | LÖVE default font |
| shaders | nil (disables shader) |
| atlas | Single-frame magenta placeholder |

Placeholders log a WARNING to help identify missing assets during development.

## Error Handling

- Load functions return `boolean` success status
- Get functions always return a valid object (placeholder if needed)
- Warnings are logged for missing assets
- Errors are logged for manifest parsing failures

## File Structure

```
src/systems/asset_manager/
├── init.lua      # Main module, API, cache, placeholders
├── loaders.lua   # Type-specific loading functions
└── atlas.lua     # Spritesheet quad generation
```
