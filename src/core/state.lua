--[[
    RITMINITY - Core State Manager
    Sistema de gestión de estados del juego
]]

local StateManager = {}
StateManager.states = {}
StateManager.current = nil
StateManager.currentName = nil

function StateManager:initialize()
    self.states = {}
    self.current = nil
    self.currentName = nil
end

function StateManager:register(name, state)
    if not state then
        print("[StateManager] Error: Intentando registrar estado '" .. tostring(name) .. "' que es nil")
        return
    end
    self.states[name] = state
    if state.init then
        state:init()
    end
end

function StateManager:change(name, params)
    local newState = self.states[name]
    if not newState then return end
    
    if self.current and self.current.exit then
        self.current:exit()
    end
    
    self.current = newState
    self.currentName = name
    
    if self.current.enter then
        self.current:enter(params)
    end
end

function StateManager:update(dt)
    if self.current and self.current.update then
        self.current:update(dt)
    end
end

function StateManager:draw()
    if self.current and self.current.draw then
        self.current:draw()
    end
end

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

return StateManager