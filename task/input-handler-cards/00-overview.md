# Input Handler System - Overview

> Sistema unificato per gestire keyboard, mouse e gamepad con action mapping, context switching e rebinding.

## Obiettivo

Creare un Input Handler che:

- Unifichi keyboard, mouse e gamepad sotto un'unica API
- Supporti action mapping astratto ("jump" invece di "space")
- Gestisca stati `isPressed`, `isDown`, `isReleased`
- Permetta context switching (gameplay vs menu vs pause)
- Predisponga rebinding runtime
- Sia estendibile per multiplayer futuro

## Architettura

```
InputHandler (core)
├── InputAction      → definizione singola azione + binding
├── InputState       → traccia pressed/held/released per azione
├── InputContext     → raggruppa azioni attive insieme
└── InputDefaults    → configurazione default (constants)
```

## Flusso Dati

```
LÖVE callbacks (keypressed, mousepressed, gamepadpressed...)
    ↓
InputHandler:eventCallback()  → cattura raw input
    ↓
InputHandler:update(dt)       → processa stati, aggiorna InputState
    ↓
InputHandler:isPressed("jump") → query dal gameplay code
    ↓
InputHandler:lateUpdate()     → reset pressed/released flags
```

## Files da Creare

| File                                          | Scopo                         |
| --------------------------------------------- | ----------------------------- |
| `src/systems/input_handler/init.lua`          | Aggregatore                   |
| `src/systems/input_handler/input_action.lua`  | Struttura dati azione         |
| `src/systems/input_handler/input_state.lua`   | Tracking stato frame-by-frame |
| `src/systems/input_handler/input_context.lua` | Raggruppamento azioni         |
| `src/systems/input_handler/input_handler.lua` | Sistema centrale              |
| `src/constants/input_defaults.lua`            | Config default                |
| `spec/input_*_spec.lua`                       | Test suite                    |
| `docs/input_handler.md`                       | Documentazione                |

## Cards

1. **InputAction** - Struttura dati azione
2. **InputState** - Tracking stati
3. **InputContext** - Raggruppamento azioni
4. **InputHandler Core** - Struttura base
5. **InputHandler Context** - Gestione contesti
6. **InputHandler Events** - Cattura eventi LÖVE
7. **InputHandler Query** - API di query
8. **InputHandler Rebinding** - Sistema rebinding
9. **InputDefaults** - Configurazione default
10. **Integration** - Init aggregator + main.lua
11. **Tests** - Test suite completa
12. **Documentation** - Docs finale

## Ordine Implementazione

```
InputAction → InputState → InputContext → InputHandler (4-7) → InputDefaults → Integration → Tests → Rebinding → Docs
```

## Dipendenze

- Nessuna dipendenza esterna
- Usa pattern già esistenti nel template (factory, metatable)
- Integrazione con Init Aggregator Pattern
