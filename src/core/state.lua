--[[
    RITMINITY - Core State Manager
    Sistema de gestión de estados del juego
]]

local StateManager = {}
<<<<<<< HEAD
StateManager.states = {}
StateManager.current = nil
StateManager.currentName = nil
=======
StateManager.__index = StateManager
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5

function StateManager:initialize()
    self.states = {}
    self.current = nil
<<<<<<< HEAD
    self.currentName = nil
end

function StateManager:register(name, state)
    if not state then
        print("[StateManager] Error: Intentando registrar estado '" .. tostring(name) .. "' que es nil")
        return
    end
    self.states[name] = state
=======
    self.previous = nil
    self.transition = {
        active = false,
        from = nil,
        to = nil,
        progress = 0,
        duration = 0.3
    }
end

-- Registrar un estado
function StateManager:register(name, state)
    self.states[name] = state
    
    -- Inicializar el estado si tiene método init
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    if state.init then
        state:init()
    end
end

<<<<<<< HEAD
function StateManager:change(name, params)
    local newState = self.states[name]
    if not newState then return end
    
=======
-- Cambiar de estado
function StateManager:change(stateName, params)
    local newState = self.states[stateName]
    
    if not newState then
        print("[StateManager] Estado no encontrado: " .. tostring(stateName))
        return false
    end
    
    -- Llamar al método de salida del estado actual
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    if self.current and self.current.exit then
        self.current:exit()
    end
    
<<<<<<< HEAD
    self.current = newState
    self.currentName = name
    
    if self.current.enter then
        self.current:enter(params)
    end
end

=======
    -- Guardar estado anterior
    self.previous = self.current
    
    -- Establecer nuevo estado
    self.current = newState
    
    -- Llamar al método de entrada del nuevo estado
    if self.current.enter then
        self.current:enter(params)
    end
    
    return true
end

-- Obtener estado actual
function StateManager:getCurrent()
    return self.current
end

-- Obtener estado anterior
function StateManager:getPrevious()
    return self.previous
end

-- Verificar si estamos en un estado específico
function StateManager:is(stateName)
    return self.current == self.states[stateName]
end

-- Push - guardar estado actual y cambiar
function StateManager:push(stateName, params)
    local newState = self.states[stateName]
    
    if not newState then
        return false
    end
    
    -- Llamar al método de salida del estado actual
    if self.current and self.current.exit then
        self.current:exit()
    end
    
    -- Establecer nuevo estado
    self.current = newState
    
    -- Llamar al método de entrada
    if self.current.enter then
        self.current:enter(params)
    end
    
    return true
end

-- Pop - volver al estado anterior
function StateManager:pop()
    if not self.previous then
        return false
    end
    
    -- Llamar al método de salida del estado actual
    if self.current and self.current.exit then
        self.current:exit()
    end
    
    -- Restaurar estado anterior
    self.current = self.previous
    self.previous = nil
    
    -- Llamar al método de entrada
    if self.current.enter then
        self.current:enter()
    end
    
    return true
end

-- Actualizar estado actual
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
function StateManager:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

<<<<<<< HEAD
=======
-- Renderizar estado actual
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
function StateManager:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

<<<<<<< HEAD
function StateManager:handleInput(key, scancode, isRepeat)
    if self.current and self.current.handleInput then
        self.current:handleInput(key, scancode, isRepeat)
    end
end

function StateManager:keyreleased(key, scancode)
    if self.current and self.current.keyreleased then
        self.current:keyreleased(key, scancode)
    end
end

=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
return StateManager