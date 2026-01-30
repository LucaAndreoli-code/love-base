# Card 08: InputHandler Rebinding

> Sistema per modificare i binding a runtime e serializzare/deserializzare.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_handler.lua` (estensione Card 04-07)

## Descrizione

Permette di:
1. Modificare binding esistenti
2. Entrare in "rebind mode" per catturare il prossimo input
3. Salvare/caricare configurazione binding

## Interfaccia

```lua
--------------------------------------------------
-- Direct Rebinding
--------------------------------------------------

--- Cambia binding per un'azione
---@param actionName string
---@param inputType "keyboard"|"mouse"|"gamepadButton"|"gamepadAxis"
---@param value string|number  -- tasto, bottone, o asse
---@param contextName? string  -- se nil, cerca in tutti i contesti
---@return boolean  -- true se trovato e modificato
function InputHandler:setBinding(actionName, inputType, value, contextName)

--- Ottiene binding corrente
---@param actionName string
---@param inputType "keyboard"|"mouse"|"gamepadButton"|"gamepadAxis"
---@param contextName? string
---@return string|number|nil
function InputHandler:getBinding(actionName, inputType, contextName)

--- Reset un'azione ai default
---@param actionName string
---@param contextName? string
function InputHandler:resetBinding(actionName, contextName)

--- Reset tutti i binding ai default
function InputHandler:resetAllBindings()

--------------------------------------------------
-- Interactive Rebinding Mode
--------------------------------------------------

--- Entra in modalità rebind
---@param actionName string
---@param inputType "keyboard"|"mouse"|"gamepadButton"  -- no axis in rebind mode
---@param callback? fun(success: boolean, newValue: string|number)
function InputHandler:startRebind(actionName, inputType, callback)

--- Annulla rebind in corso
function InputHandler:cancelRebind()

--- Verifica se siamo in rebind mode
---@return boolean
function InputHandler:isRebinding()

--- Info sul rebind in corso
---@return { actionName: string, inputType: string }|nil
function InputHandler:getRebindInfo()

--------------------------------------------------
-- Serialization
--------------------------------------------------

--- Esporta tutti i binding (per salvataggio)
---@return table
function InputHandler:exportBindings()

--- Importa binding (da caricamento)
---@param data table
function InputHandler:importBindings(data)
```

## Stato Rebind

```lua
---@class RebindState
---@field active boolean
---@field actionName string|nil
---@field inputType string|nil
---@field contextName string|nil
---@field callback function|nil
---@field originalAction InputAction|nil  -- backup per cancel

-- Aggiungere a InputHandler
self._rebind = {
    active = false,
    actionName = nil,
    inputType = nil,
    contextName = nil,
    callback = nil,
    originalAction = nil,
}
```

## Implementazione Direct Rebinding

```lua
function InputHandler:setBinding(actionName, inputType, value, contextName)
    local action = self:_findAction(actionName, contextName)
    if not action then return false end
    
    -- Valida inputType
    local validTypes = { keyboard = true, mouse = true, gamepadButton = true, gamepadAxis = true }
    if not validTypes[inputType] then return false end
    
    action[inputType] = value
    return true
end

function InputHandler:getBinding(actionName, inputType, contextName)
    local action = self:_findAction(actionName, contextName)
    if not action then return nil end
    return action[inputType]
end

--- Trova un'azione nei contesti
---@private
function InputHandler:_findAction(actionName, contextName)
    if contextName then
        local context = self.contexts[contextName]
        return context and context:getAction(actionName)
    end
    
    -- Cerca in tutti i contesti
    for _, context in pairs(self.contexts) do
        local action = context:getAction(actionName)
        if action then return action end
    end
    return nil
end
```

## Implementazione Rebind Mode

```lua
function InputHandler:startRebind(actionName, inputType, callback)
    local action = self:_findAction(actionName)
    if not action then
        if callback then callback(false, nil) end
        return
    end
    
    self._rebind = {
        active = true,
        actionName = actionName,
        inputType = inputType,
        callback = callback,
        originalAction = action:clone(),  -- backup
    }
    
    -- In rebind mode, i normali input sono ignorati
    -- I callback LÖVE devono controllare isRebinding()
end

function InputHandler:cancelRebind()
    if not self._rebind.active then return end
    
    -- Ripristina backup se necessario
    if self._rebind.callback then
        self._rebind.callback(false, nil)
    end
    
    self:_clearRebind()
end

function InputHandler:isRebinding()
    return self._rebind.active
end

function InputHandler:getRebindInfo()
    if not self._rebind.active then return nil end
    return {
        actionName = self._rebind.actionName,
        inputType = self._rebind.inputType,
    }
end

---@private
function InputHandler:_clearRebind()
    self._rebind = {
        active = false,
        actionName = nil,
        inputType = nil,
        callback = nil,
        originalAction = nil,
    }
end

--- Chiamato internamente quando un input viene catturato durante rebind
---@private
function InputHandler:_completeRebind(value)
    if not self._rebind.active then return end
    
    local success = self:setBinding(
        self._rebind.actionName,
        self._rebind.inputType,
        value
    )
    
    if self._rebind.callback then
        self._rebind.callback(success, value)
    end
    
    self:_clearRebind()
end
```

## Modifiche ai Callback per Rebind

I callback eventi devono controllare `isRebinding()`:

```lua
function InputHandler:keypressed(key, scancode, isrepeat)
    if isrepeat then return end
    
    -- Rebind mode: cattura questo tasto
    if self._rebind.active and self._rebind.inputType == "keyboard" then
        -- Escape per annullare
        if key == "escape" then
            self:cancelRebind()
        else
            self:_completeRebind(key)
        end
        return  -- non processare come input normale
    end
    
    -- Normale processing
    self._rawInputs["key:" .. key] = true
end

function InputHandler:mousepressed(x, y, button, istouch)
    if self._rebind.active and self._rebind.inputType == "mouse" then
        self:_completeRebind(button)
        return
    end
    
    -- Normale processing...
end

function InputHandler:gamepadpressed(joystick, button)
    if joystick ~= self._activeGamepad then return end
    
    if self._rebind.active and self._rebind.inputType == "gamepadButton" then
        self:_completeRebind(button)
        return
    end
    
    -- Normale processing...
end
```

## Serializzazione

```lua
function InputHandler:exportBindings()
    local data = {
        version = 1,  -- per future migrazioni
        contexts = {}
    }
    
    for contextName, context in pairs(self.contexts) do
        data.contexts[contextName] = {}
        for actionName, action in pairs(context:getActions()) do
            data.contexts[contextName][actionName] = action:serialize()
        end
    end
    
    return data
end

function InputHandler:importBindings(data)
    if not data or not data.contexts then return end
    
    -- Versioning per future migrazioni
    local version = data.version or 1
    
    for contextName, actions in pairs(data.contexts) do
        local context = self.contexts[contextName]
        if context then
            for actionName, actionData in pairs(actions) do
                local existingAction = context:getAction(actionName)
                if existingAction then
                    -- Aggiorna solo i binding, mantieni il resto
                    existingAction.keyboard = actionData.keyboard
                    existingAction.mouse = actionData.mouse
                    existingAction.gamepadButton = actionData.gamepadButton
                    existingAction.gamepadAxis = actionData.gamepadAxis
                    existingAction.axisDirection = actionData.axisDirection
                    existingAction.axisThreshold = actionData.axisThreshold
                end
            end
        end
    end
end
```

## Default Bindings Storage

Per `resetBinding`, serve memorizzare i default:

```lua
function InputHandler.new(settings)
    -- ... existing code ...
    
    self._defaultBindings = nil  -- popolato dopo setup iniziale
end

--- Salva stato corrente come default (chiamare dopo setup iniziale)
function InputHandler:saveAsDefault()
    self._defaultBindings = self:exportBindings()
end

function InputHandler:resetBinding(actionName, contextName)
    if not self._defaultBindings then return end
    
    local action = self:_findAction(actionName, contextName)
    if not action then return end
    
    -- Trova default
    for ctxName, actions in pairs(self._defaultBindings.contexts) do
        if actions[actionName] then
            local default = actions[actionName]
            action.keyboard = default.keyboard
            action.mouse = default.mouse
            action.gamepadButton = default.gamepadButton
            action.gamepadAxis = default.gamepadAxis
            break
        end
    end
end

function InputHandler:resetAllBindings()
    if self._defaultBindings then
        self:importBindings(self._defaultBindings)
    end
end
```

## Esempio Flusso UI Rebinding

```lua
-- In un menu opzioni
local rebindButton = Button.new({
    text = "Jump: " .. input:getBinding("jump", "keyboard"),
    onClick = function()
        ui:showMessage("Press a key...")
        input:startRebind("jump", "keyboard", function(success, newKey)
            if success then
                rebindButton.text = "Jump: " .. newKey
                ui:showMessage("Bound to " .. newKey)
            else
                ui:showMessage("Cancelled")
            end
        end)
    end
})

-- Salvataggio
local saveButton = Button.new({
    text = "Save",
    onClick = function()
        local data = input:exportBindings()
        local json = Game.utils.json.encode(data)
        love.filesystem.write("bindings.json", json)
    end
})

-- Caricamento
function loadBindings()
    local content = love.filesystem.read("bindings.json")
    if content then
        local data = Game.utils.json.decode(content)
        input:importBindings(data)
    end
end
```

## Test Cases

```lua
describe("InputHandler Rebinding", function()
    it("sets binding directly", function()
        local handler = setupHandler()  -- con action "jump" = space
        
        local success = handler:setBinding("jump", "keyboard", "w")
        
        assert.is_true(success)
        assert.equals("w", handler:getBinding("jump", "keyboard"))
    end)
    
    it("enters rebind mode", function()
        local handler = setupHandler()
        handler:startRebind("jump", "keyboard")
        
        assert.is_true(handler:isRebinding())
        assert.equals("jump", handler:getRebindInfo().actionName)
    end)
    
    it("captures key during rebind", function()
        local handler = setupHandler()
        local captured = nil
        
        handler:startRebind("jump", "keyboard", function(success, key)
            captured = key
        end)
        
        handler:keypressed("w", "w", false)
        
        assert.equals("w", captured)
        assert.is_false(handler:isRebinding())
    end)
    
    it("cancels rebind with escape", function()
        local handler = setupHandler()
        local cancelled = false
        
        handler:startRebind("jump", "keyboard", function(success, key)
            cancelled = not success
        end)
        
        handler:keypressed("escape", "escape", false)
        
        assert.is_true(cancelled)
        assert.is_false(handler:isRebinding())
    end)
    
    it("exports and imports bindings", function()
        local handler = setupHandler()
        handler:setBinding("jump", "keyboard", "w")
        
        local data = handler:exportBindings()
        handler:setBinding("jump", "keyboard", "q")  -- cambia
        handler:importBindings(data)
        
        assert.equals("w", handler:getBinding("jump", "keyboard"))
    end)
    
    it("resets to default", function()
        local handler = setupHandler()  -- jump = space
        handler:saveAsDefault()
        handler:setBinding("jump", "keyboard", "w")
        handler:resetBinding("jump")
        
        assert.equals("space", handler:getBinding("jump", "keyboard"))
    end)
end)
```

## Dipendenze
- Card 01: InputAction (serialize/deserialize)
- Card 04-07: InputHandler base

## Prossima Card
→ Card 09: Input Defaults Config
