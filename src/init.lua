local Game = {}

function Game.load()
    Game.logger = require("src.logger")
    Game.debug = require("src.debug")

    Game.scenes = require("src.scenes.init")
    Game.constants = require("src.constants.init")
    Game.systems = require("src.systems.init")
    Game.utils = require("src.utils.init")
    Game.ui = require("src.ui.init")

    Game.scenes:load()
    Game.constants:load()
    Game.systems:load()
    Game.utils:load()
    Game.ui:load()
    Game.debug:load()

    -- Create input handler instance
    local InputHandler = Game.systems.inputHandler
    Game.input = InputHandler.new(Game.constants.inputDefaults.settings)
    InputHandler.setupFromDefaults(Game.input, Game.constants.inputDefaults)

    -- Create input prompts instance (for displaying input icons)
    Game.prompts = Game.systems.InputPrompts.new(Game.input)

    -- Initialize debug with prompts reference (registers input callback)
    Game.debug:init(Game.prompts)

    -- Debug context always active in debug mode
    if arg and arg[2] == "--debug" then
        Game.input:pushContext("debug")
    end

    -- Create audio manager instance
    local AudioManager = Game.systems.audioManager
    Game.audio = AudioManager.new(Game.constants.audioDefaults.settings)
    AudioManager.setupFromDefaults(Game.audio, Game.constants.audioDefaults)

    -- Create asset manager instance
    Game.assets = Game.systems.assetManager

    -- Create state machine
    local StateMachine = Game.systems.stateMachine
    Game.stateMachine = StateMachine.new()

    Game.logger.info("Game Started!", "Game")
end

function Game.update(dt)
    -- Input update BEFORE game logic
    Game.input:update(dt)

    -- Audio update
    Game.audio:update(dt)

    -- StateMachine update (current scene)
    Game.stateMachine:update(dt)

    -- Debug controls
    if Game.input:isPressed("debug_toggle") then
        Game.debug:toggle()
    end
end

function Game.lateUpdate()
    -- Input late update AFTER game logic
    Game.input:lateUpdate()
end

function Game.draw()
    -- Draw all states in stack (for layered rendering like pause over gameplay)
    Game.stateMachine:draw()

    -- Debug overlay on top
    Game.debug:draw()
end

function Game.keypressed(key, scancode, isrepeat)
    -- Handle other keypresses here
    Game.input:keypressed(key, scancode, isrepeat)
    Game.debug:keypressed(key)
end

return Game
