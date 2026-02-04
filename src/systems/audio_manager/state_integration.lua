local Logger = require("src.logger")

---State Integration mixin for AudioManager
---@param AudioManager table
return function(AudioManager)
    ---Set state-to-music mapping
    ---@param mapping table<string, string|false> state name -> music name or false to not change
    function AudioManager:setStateMusic(mapping)
        self.stateMusic = mapping or {}
        Logger.debug("State music mapping set", "AudioManager")
    end

    ---Bind to a StateMachine to auto-change music on state transitions
    ---@param stateMachine table
    function AudioManager:bindStateMachine(stateMachine)
        if not stateMachine then return end

        self._stateMachine = stateMachine

        -- Store original methods
        self._originalSetState = stateMachine.setState
        self._originalPopState = stateMachine.popState

        -- Wrap setState
        local audioManager = self
        stateMachine.setState = function(sm, name, params)
            local oldState = sm:getState()
            audioManager._originalSetState(sm, name, params)
            audioManager:onStateChange(name, oldState)
        end

        -- Wrap popState
        stateMachine.popState = function(sm, params)
            local oldState = sm:getState()
            audioManager._originalPopState(sm, params)
            local newState = sm:getState()
            if newState then
                audioManager:onStateChange(newState, oldState)
            end
        end

        Logger.debug("Bound to StateMachine", "AudioManager")
    end

    ---Unbind from StateMachine
    function AudioManager:unbindStateMachine()
        if not self._stateMachine then return end

        -- Restore original methods
        if self._originalSetState then
            self._stateMachine.setState = self._originalSetState
        end
        if self._originalPopState then
            self._stateMachine.popState = self._originalPopState
        end

        self._stateMachine = nil
        self._originalSetState = nil
        self._originalPopState = nil

        Logger.debug("Unbound from StateMachine", "AudioManager")
    end

    ---Handle state change
    ---@param newState string
    ---@param oldState string|nil
    function AudioManager:onStateChange(newState, oldState)
        local musicAction = self.stateMusic[newState]

        if musicAction == nil then
            -- Not in mapping, don't change
            return
        elseif musicAction == false then
            -- False = overlay state, don't change
            return
        elseif type(musicAction) == "string" then
            -- Change to this music (with crossfade)
            if self.currentMusicName ~= musicAction then
                self:crossfade(musicAction)
            end
        end
    end
end
