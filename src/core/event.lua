--[[
    RITMINITY - Core Event System
    Sistema de eventos para comunicación entre módulos
]]

local EventSystem = {}
EventSystem.__index = EventSystem

-- Tabla de listeners
EventSystem.listeners = {}
EventSystem.eventQueue = {}
EventSystem.maxQueueSize = 100

function EventSystem:initialize()
    self.listeners = {}
    self.eventQueue = {}
end

-- Registrar un listener para un evento
function EventSystem:on(eventName, callback, context)
    if not self.listeners[eventName] then
        self.listeners[eventName] = {}
    end
    
    local listener = {
        callback = callback,
        context = context or nil,
        id = tostring(callback) .. tostring(os.time())
    }
    
    table.insert(self.listeners[eventName], listener)
    
    return listener
end

-- Desregistrar un listener
function EventSystem:off(eventName, listenerId)
    if not self.listeners[eventName] then
        return
    end
    
    for i, listener in ipairs(self.listeners[eventName]) do
        if listener.id == listenerId then
            table.remove(self.listeners[eventName], i)
            return true
        end
    end
    
    return false
end

-- Emitir un evento inmediatamente
function EventSystem:emit(eventName, ...)
    if not self.listeners[eventName] then
        return
    end
    
    local args = {...}
    
    for _, listener in ipairs(self.listeners[eventName]) do
        if listener.callback then
            if listener.context then
                listener.callback(listener.context, unpack(args))
            else
                listener.callback(unpack(args))
            end
        end
    end
end

-- Encolar un evento para procesamiento diferido
function EventSystem:queue(eventName, ...)
    if #self.eventQueue >= self.maxQueueSize then
        return false
    end
    
    table.insert(self.eventQueue, {
        name = eventName,
        args = {...},
        timestamp = os.time()
    })
    
    return true
end

-- Procesar eventos en cola
function EventSystem:update(dt)
    while #self.eventQueue > 0 do
        local event = table.remove(self.eventQueue, 1)
        self:emit(event.name, unpack(event.args))
    end
end

-- Obtener número de listeners
function EventSystem:listenerCount(eventName)
    if not self.listeners[eventName] then
        return 0
    end
    return #self.listeners[eventName]
end

-- Limpiar todos los listeners de un evento
function EventSystem:clear(eventName)
    if eventName then
        self.listeners[eventName] = {}
    else
        self.listeners = {}
    end
end

-- One-time listener
function EventSystem:once(eventName, callback, context)
    local wrapper
    local listenerId
    
    local function wrapperFunc(...)
        callback(...)
        self:off(eventName, listenerId)
    end
    
    listenerId = self:on(eventName, wrapperFunc, context)
    return listenerId
end

-- Eventos predefinidos del juego
EventSystem.EVENTS = {
    -- Gameplay
    GAME_START = "game:start",
    GAME_PAUSE = "game:pause",
    GAME_RESUME = "game:resume",
    GAME_END = "game:end",
    NOTE_HIT = "note:hit",
    NOTE_MISS = "note:miss",
    COMBO_BREAK = "combo:break",
    SCORE_UPDATE = "score:update",
    ACCURACY_UPDATE = "accuracy:update",
    
    -- Audio
    AUDIO_LOAD = "audio:load",
    AUDIO_PLAY = "audio:play",
    AUDIO_PAUSE = "audio:pause",
    AUDIO_STOP = "audio:stop",
    AUDIO_SYNC = "audio:sync",
    
    -- Input
    KEY_PRESS = "input:keypress",
    KEY_RELEASE = "input:keyrelease",
    MOUSE_PRESS = "input:mousepress",
    MOUSE_RELEASE = "input:mouserelease",
    
    -- UI
    SCREEN_CHANGE = "screen:change",
    MENU_SELECT = "menu:select",
    MENU_CONFIRM = "menu:confirm",
    MENU_BACK = "menu:back",
    
    -- Network
    NETWORK_CONNECT = "network:connect",
    NETWORK_DISCONNECT = "network:disconnect",
    NETWORK_ERROR = "network:error",
    LOBBY_JOIN = "lobby:join",
    LOBBY_LEAVE = "lobby:leave",
    PLAYER_READY = "player:ready",
    
    -- Chart
    CHART_LOAD = "chart:load",
    CHART_UNLOAD = "chart:unload",
    CHART_COMPLETE = "chart:complete",
    
    -- Mods
    MOD_TOGGLE = "mod:toggle",
    MOD_APPLY = "mod:apply",
    
    -- Replay
    REPLAY_START = "replay:start",
    REPLAY_STOP = "replay:stop",
    REPLAY_SAVE = "replay:save"
}

return EventSystem