# Card 05: InputHandler Context Management

> Metodi per registrare e attivare/disattivare contesti.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_handler.lua` (estensione Card 04)

## Descrizione

Gestione dei contesti: registrazione, attivazione esclusiva (switch) e layering (push/pop per pause overlay).

## Interfaccia

```lua
--- Registra un contesto
---@param context InputContext
function InputHandler:addContext(context)

--- Rimuove un contesto registrato
---@param name string
---@return boolean  -- true se rimosso
function InputHandler:removeContext(name)

--- Ottiene un contesto per nome
---@param name string
---@return InputContext|nil
function InputHandler:getContext(name)

--- Attiva SOLO questo contesto (disattiva tutti gli altri)
--- Uso tipico: switch tra menu e gameplay
---@param name string
function InputHandler:setContext(name)

--- Aggiunge un contesto al set attivo (stack-like)
--- Uso tipico: aprire pause sopra gameplay
---@param name string
function InputHandler:pushContext(name)

--- Rimuove un contesto dal set attivo
--- Uso tipico: chiudere pause, tornare a gameplay
---@param name string
function InputHandler:popContext(name)

--- Verifica se un contesto è attivo
---@param name string
---@return boolean
function InputHandler:isContextActive(name)

--- Ottiene lista contesti attivi
---@return table<string>
function InputHandler:getActiveContexts()

--- Disattiva tutti i contesti
function InputHandler:clearContexts()
```

## Implementazione

```lua
function InputHandler:addContext(context)
    self.contexts[context.name] = context
end

function InputHandler:removeContext(name)
    if self.contexts[name] then
        self.contexts[name] = nil
        self.activeContexts[name] = nil
        return true
    end
    return false
end

function InputHandler:getContext(name)
    return self.contexts[name]
end

function InputHandler:setContext(name)
    -- Verifica che il contesto esista
    if not self.contexts[name] then
        Game.logger.warning("Context not found: " .. name, "InputHandler")
        return
    end
    
    -- Pulisci tutti gli stati quando cambi contesto completamente
    for _, state in pairs(self.states) do
        state:clear()
    end
    
    -- Disattiva tutti, attiva solo questo
    self.activeContexts = {}
    self.activeContexts[name] = true
    
    -- Crea stati per le azioni del nuovo contesto
    self:_createStatesForContext(name)
end

function InputHandler:pushContext(name)
    if not self.contexts[name] then
        Game.logger.warning("Context not found: " .. name, "InputHandler")
        return
    end
    
    self.activeContexts[name] = true
    self:_createStatesForContext(name)
end

function InputHandler:popContext(name)
    self.activeContexts[name] = nil
    -- Non pulire gli stati: potrebbero servire ad altri contesti attivi
end

function InputHandler:isContextActive(name)
    return self.activeContexts[name] == true
end

function InputHandler:getActiveContexts()
    local result = {}
    for name, active in pairs(self.activeContexts) do
        if active then
            table.insert(result, name)
        end
    end
    return result
end

function InputHandler:clearContexts()
    self.activeContexts = {}
    for _, state in pairs(self.states) do
        state:clear()
    end
end
```

## Comportamento set vs push/pop

### `setContext` - Switch Esclusivo
```lua
-- Scenario: da menu a gameplay
inputHandler:setContext("gameplay")
-- Risultato: SOLO gameplay attivo
-- Tutti gli stati vengono resettati
```

### `pushContext` / `popContext` - Layering
```lua
-- Scenario: apri pausa durante gameplay
inputHandler:setContext("gameplay")      -- solo gameplay
inputHandler:pushContext("pause")        -- gameplay + pause attivi

-- Ora sia "jump" (gameplay) che "unpause" (pause) rispondono
-- Ma tipicamente in pause non aggiorni il gameplay...

inputHandler:popContext("pause")         -- torna solo gameplay
```

## Conflitti tra Contesti

Se la stessa azione esiste in più contesti attivi:
- Vince il primo contesto trovato (ordine non garantito)
- **Raccomandazione**: evita azioni con lo stesso nome in contesti che possono essere attivi insieme

```lua
-- EVITA questo:
gameplayContext:addAction(InputAction.new({ name = "confirm", keyboard = "e" }))
pauseContext:addAction(InputAction.new({ name = "confirm", keyboard = "return" }))

-- Se entrambi attivi, comportamento ambiguo

-- MEGLIO:
gameplayContext:addAction(InputAction.new({ name = "interact", keyboard = "e" }))
pauseContext:addAction(InputAction.new({ name = "confirm", keyboard = "return" }))
```

## Esempio Flusso Completo

```lua
-- Setup iniziale
local gameplay = InputContext.new("gameplay")
gameplay:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
gameplay:addAction(InputAction.new({ name = "pause", keyboard = "escape" }))

local pause = InputContext.new("pause")
pause:addAction(InputAction.new({ name = "unpause", keyboard = "escape" }))
pause:addAction(InputAction.new({ name = "quit", keyboard = "q" }))

local menu = InputContext.new("menu")
menu:addAction(InputAction.new({ name = "start", keyboard = "return" }))

inputHandler:addContext(gameplay)
inputHandler:addContext(pause)
inputHandler:addContext(menu)

-- Game flow
inputHandler:setContext("menu")      -- Partenza: menu

-- Player preme Start
inputHandler:setContext("gameplay")  -- Switch a gameplay

-- Player preme Escape
inputHandler:pushContext("pause")    -- Overlay pause

-- Player preme Escape di nuovo (unpause)
inputHandler:popContext("pause")     -- Torna gameplay

-- Player muore, torna al menu
inputHandler:setContext("menu")
```

## Test Cases

```lua
describe("InputHandler Context Management", function()
    local InputContext = require("src.systems.input_context")
    local InputAction = require("src.systems.input_action")
    
    local function createHandler()
        local handler = InputHandler.new()
        
        local ctx1 = InputContext.new("gameplay")
        ctx1:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
        
        local ctx2 = InputContext.new("pause")
        ctx2:addAction(InputAction.new({ name = "unpause", keyboard = "escape" }))
        
        handler:addContext(ctx1)
        handler:addContext(ctx2)
        
        return handler
    end
    
    it("registers contexts", function()
        local handler = createHandler()
        assert.is_not_nil(handler:getContext("gameplay"))
        assert.is_not_nil(handler:getContext("pause"))
    end)
    
    it("sets context exclusively", function()
        local handler = createHandler()
        handler:setContext("gameplay")
        
        assert.is_true(handler:isContextActive("gameplay"))
        assert.is_false(handler:isContextActive("pause"))
    end)
    
    it("pushes multiple contexts", function()
        local handler = createHandler()
        handler:setContext("gameplay")
        handler:pushContext("pause")
        
        assert.is_true(handler:isContextActive("gameplay"))
        assert.is_true(handler:isContextActive("pause"))
    end)
    
    it("pops context", function()
        local handler = createHandler()
        handler:setContext("gameplay")
        handler:pushContext("pause")
        handler:popContext("pause")
        
        assert.is_true(handler:isContextActive("gameplay"))
        assert.is_false(handler:isContextActive("pause"))
    end)
    
    it("clears all contexts", function()
        local handler = createHandler()
        handler:setContext("gameplay")
        handler:pushContext("pause")
        handler:clearContexts()
        
        assert.equals(0, #handler:getActiveContexts())
    end)
    
    it("warns on invalid context", function()
        local handler = createHandler()
        -- Should not crash, just warn
        handler:setContext("nonexistent")
        assert.equals(0, #handler:getActiveContexts())
    end)
    
    it("removes context", function()
        local handler = createHandler()
        handler:setContext("gameplay")
        handler:removeContext("gameplay")
        
        assert.is_nil(handler:getContext("gameplay"))
        assert.is_false(handler:isContextActive("gameplay"))
    end)
end)
```

## Dipendenze
- Card 04: InputHandler Core

## Prossima Card
→ Card 06: InputHandler Event Capture
