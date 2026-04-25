--[[
    RITMINITY - Network Manager
    Sistema de multiplayer P2P y comunicación en red
]]

-- Intentar cargar socket (puede no estar disponible en Love2D)
local socket_ok, socket = pcall(require, "socket")

local NetworkManager = {}
NetworkManager.__index = NetworkManager

-- Singleton instance
local instance = nil

-- Bandera para saber si el módulo de red está disponible
NetworkManager.networkAvailable = socket_ok

function NetworkManager:getInstance()
    if not instance then
        instance = NetworkManager:new()
        instance:initialize()
    end
    return instance
end

-- Estado de conexión
NetworkManager.state = {
    disconnected = "disconnected",
    connecting = "connecting",
    connected = "connected",
    error = "error"
}

-- Tipos de mensaje
NetworkManager.messageTypes = {
    HELLO = 0x01,
    WELCOME = 0x02,
    JOIN_LOBBY = 0x10,
    LEAVE_LOBBY = 0x11,
    LOBBY_UPDATE = 0x12,
    CHAT_MESSAGE = 0x20,
    GAME_START = 0x30,
    GAME_STATE = 0x31,
    PLAYER_READY = 0x32,
    PLAYER_SCORE = 0x33,
    PLAYER_INPUT = 0x34,
    SYNC_TIME = 0x40,
    PING = 0x50,
    PONG = 0x51
}

function NetworkManager:initialize()
    self.currentState = self.state.disconnected
    self.connections = {}
    self.lobbies = {}
    self.currentLobby = nil
    self.serverAddress = nil
    self.serverPort = nil
    self.client = nil
    self.udpSocket = nil
    self.tcpSocket = nil
    self.connectionSocket = nil
    self.connectedAddress = nil
    self.connectedPort = nil
    self.connectionPending = false
    self.receiveBuffer = ""
    
    -- Callbacks
    self.callbacks = {
        onConnect = nil,
        onDisconnect = nil,
        onLobbyJoin = nil,
        onLobbyLeave = nil,
        onChatMessage = nil,
        onGameStart = nil,
        onPlayerJoin = nil,
        onPlayerLeave = nil,
        onPlayerReady = nil,
        onGameState = nil
    }
    
    -- Configuración
    self.config = {
        maxPlayers = 8,
        timeout = 30,
        retryAttempts = 3,
        pingInterval = 5,
        syncInterval = 1
    }
    
    -- Jugadores conectados
    self.players = {}
    self.localPlayer = {
        id = 0,
        name = "Player",
        ready = false,
        score = 0,
        combo = 0
    }
    
    -- Sincronización
    self.serverTime = 0
    self.clientTime = 0
    self.timeOffset = 0
    self.lastPing = 0
    self.lastPong = 0
end

-- Conectar a servidor
function NetworkManager:connect(address, port)
    self.serverAddress = address
    self.serverPort = port
    self.currentState = self.state.connecting
    
    -- Intentar crear socket TCP
    self.tcpSocket = socket.tcp()
    self.tcpSocket:settimeout(0) -- Non-blocking
    
    local result, err = self.tcpSocket:connect(address, port)
    if result == nil and err ~= "timeout" then
        self.currentState = self.state.error
        if self.callbacks.onConnect then
            self.callbacks.onConnect(false, "Connection failed: " .. tostring(err))
        end
        return false
    end
    
    self.connectionSocket = self.tcpSocket
    self.connectedAddress = address
    self.connectedPort = port
    
    -- Esperar a que la conexión se establezca (en el próximo update)
    self.connectionPending = true
    
    return true
end

-- Desconectar
function NetworkManager:disconnect()
    if self.currentLobby then
        self:leaveLobby()
    end
    
    self.currentState = self.state.disconnected
    
    if self.callbacks.onDisconnect then
        self.callbacks.onDisconnect()
    end
end

-- Crear lobby
function NetworkManager:createLobby(name, maxPlayers)
    local lobby = {
        id = os.time(),
        name = name,
        host = self.localPlayer.id,
        players = {self.localPlayer},
        maxPlayers = maxPlayers or self.config.maxPlayers,
        state = "waiting", -- waiting, playing
        settings = {
            columnCount = 4,
            mods = "",
            speed = 1.0
        }
    }
    
    self.lobbies[lobby.id] = lobby
    self.currentLobby = lobby
    
    return lobby
end

-- Unirse a lobby
function NetworkManager:joinLobby(lobbyId)
    local lobby = self.lobbies[lobbyId]
    if not lobby then
        return false, "Lobby no encontrado"
    end
    
    if #lobby.players >= lobby.maxPlayers then
        return false, "Lobby lleno"
    end
    
    table.insert(lobby.players, self.localPlayer)
    self.currentLobby = lobby
    
    if self.callbacks.onLobbyJoin then
        self.callbacks.onLobbyJoin(lobby)
    end
    
    return true
end

-- Salir del lobby
function NetworkManager:leaveLobby()
    if not self.currentLobby then
        return false
    end
    
    -- Remover jugador del lobby
    for i, player in ipairs(self.currentLobby.players) do
        if player.id == self.localPlayer.id then
            table.remove(self.currentLobby.players, i)
            break
        end
    end
    
    local lobby = self.currentLobby
    self.currentLobby = nil
    
    if self.callbacks.onLobbyLeave then
        self.callbacks.onLobbyLeave(lobby)
    end
    
    return true
end

-- Obtener lobbies disponibles
function NetworkManager:getAvailableLobbies()
    local available = {}
    for id, lobby in pairs(self.lobbies) do
        if lobby.state == "waiting" and #lobby.players < lobby.maxPlayers then
            table.insert(available, lobby)
        end
    end
    return available
end

-- Establecer listo
function NetworkManager:setReady(ready)
    self.localPlayer.ready = ready
    
    if self.currentLobby then
        self:broadcast({
            type = self.messageTypes.PLAYER_READY,
            playerId = self.localPlayer.id,
            ready = ready
        })
    end
    
    if self.callbacks.onPlayerReady then
        self.callbacks.onPlayerReady(self.localPlayer, ready)
    end
end

-- Iniciar juego
function NetworkManager:startGame()
    if not self.currentLobby then
        return false
    end
    
    -- Verificar que todos estén listos
    for _, player in ipairs(self.currentLobby.players) do
        if not player.ready and player.id ~= self.localPlayer.id then
            return false, "No todos los jugadores están listos"
        end
    end
    
    self.currentLobby.state = "playing"
    
    -- Broadcast inicio
    self:broadcast({
        type = self.messageTypes.GAME_START,
        lobbyId = self.currentLobby.id
    })
    
    if self.callbacks.onGameStart then
        self.callbacks.onGameStart(self.currentLobby)
    end
    
    return true
end

-- Enviar estado del juego
function NetworkManager:sendGameState(state)
    if not self.currentLobby then
        return
    end
    
    self:broadcast({
        type = self.messageTypes.GAME_STATE,
        playerId = self.localPlayer.id,
        score = state.score,
        combo = state.combo,
        accuracy = state.accuracy,
        time = self:getSyncedTime()
    })
end

-- Enviar input
function NetworkManager:sendInput(column, pressed)
    if not self.currentLobby then
        return
    end
    
    self:broadcast({
        type = self.messageTypes.PLAYER_INPUT,
        playerId = self.localPlayer.id,
        column = column,
        pressed = pressed,
        time = self:getSyncedTime()
    })
end

-- Sincronizar tiempo
function NetworkManager:syncTime()
    self.clientTime = love.timer.getTime()
    
    self:broadcast({
        type = self.messageTypes.SYNC_TIME,
        clientTime = self.clientTime
    })
end

-- Obtener tiempo sincronizado
function NetworkManager:getSyncedTime()
    return self.clientTime + self.timeOffset
end

-- Enviar mensaje de chat
function NetworkManager:sendChatMessage(message)
    if not self.currentLobby then
        return false
    end
    
    self:broadcast({
        type = self.messageTypes.CHAT_MESSAGE,
        playerId = self.localPlayer.id,
        playerName = self.localPlayer.name,
        message = message,
        timestamp = os.time()
    })
    
    return true
end

-- Broadcast a todos los jugadores
function NetworkManager:broadcast(message)
    -- Por implementar: envío real a través de socket
    -- Por ahora, simulamos el broadcast
    
    -- Notificar a callbacks locales
    if message.type == self.messageTypes.CHAT_MESSAGE and self.callbacks.onChatMessage then
        self.callbacks.onChatMessage(message.playerName, message.message)
    elseif message.type == self.messageTypes.PLAYER_READY and self.callbacks.onPlayerReady then
        self.callbacks.onPlayerReady(message.playerId, message.ready)
    elseif message.type == self.messageTypes.GAME_STATE and self.callbacks.onGameState then
        self.callbacks.onGameState(message)
    end
end

-- Procesar mensaje recibido
function NetworkManager:processMessage(message)
    local msgType = message.type
    
    if msgType == self.messageTypes.WELCOME then
        self.localPlayer.id = message.playerId
    elseif msgType == self.messageTypes.PLAYER_READY then
        self:handlePlayerReady(message)
    elseif msgType == self.messageTypes.GAME_STATE then
        self:handleGameState(message)
    elseif msgType == self.messageTypes.CHAT_MESSAGE then
        if self.callbacks.onChatMessage then
            self.callbacks.onChatMessage(message.playerName, message.message)
        end
    elseif msgType == self.messageTypes.SYNC_TIME then
        self:handleTimeSync(message)
    elseif msgType == self.messageTypes.PING then
        self:handlePing(message)
    elseif msgType == self.messageTypes.PONG then
        self:handlePong(message)
    end
end

-- Manejar jugador listo
function NetworkManager:handlePlayerReady(message)
    if self.currentLobby then
        for _, player in ipairs(self.currentLobby.players) do
            if player.id == message.playerId then
                player.ready = message.ready
                break
            end
        end
    end
    
    if self.callbacks.onPlayerReady then
        self.callbacks.onPlayerReady(message.playerId, message.ready)
    end
end

-- Manejar estado de juego
function NetworkManager:handleGameState(message)
    if self.currentLobby then
        for _, player in ipairs(self.currentLobby.players) do
            if player.id == message.playerId then
                player.score = message.score
                player.combo = message.combo
                player.accuracy = message.accuracy
                break
            end
        end
    end
    
    if self.callbacks.onGameState then
        self.callbacks.onGameState(message)
    end
end

-- Manejar sincronización de tiempo
function NetworkManager:handleTimeSync(message)
    local serverTime = message.serverTime
    local clientTime = message.clientTime
    
    self.timeOffset = serverTime - clientTime
end

-- Manejar ping
function NetworkManager:handlePing(message)
    self:send({
        type = self.messageTypes.PONG,
        timestamp = message.timestamp
    })
end

-- Manejar pong
function NetworkManager:handlePong(message)
    local latency = (love.timer.getTime() - message.timestamp) * 1000
    self.lastPong = latency
end

-- Actualizar
function NetworkManager:update(dt)
    -- Manejar conexión pendiente
    if self.connectionPending then
        if self.connectionSocket then
            -- Verificar si la conexión se estableció
            local result, err = self.connectionSocket:connect()
            if result == 1 or err == "already connected" then
                self.connectionPending = false
                self.currentState = self.state.connected
                
                if self.callbacks.onConnect then
                    self.callbacks.onConnect(true, "Connected to " .. self.connectedAddress .. ":" .. self.connectedPort)
                end
            elseif err ~= "timeout" then
                self.connectionPending = false
                self.currentState = self.state.error
                
                if self.callbacks.onConnect then
                    self.callbacks.onConnect(false, "Connection failed: " .. tostring(err))
                end
            end
            -- Si sigue siendo timeout, seguimos esperando
        end
    end
    
    if self.currentState ~= self.state.connected then
        return
    end
    
    -- Recibir datos
    if self.connectionSocket then
        self:receiveData()
    end
    
    -- Ping periódico
    self.lastPing = self.lastPing + dt
    if self.lastPing > self.config.pingInterval then
        self:sendPing()
        self.lastPing = 0
    end
    
    -- Sincronización de tiempo
    self.clientTime = self.clientTime + dt
end

-- Enviar ping
function NetworkManager:sendPing()
    self:send({
        type = self.messageTypes.PING,
        timestamp = love.timer.getTime()
    })
end

-- Enviar mensaje
function NetworkManager:send(message)
    if not self.connectionSocket or self.currentState ~= self.state.connected then
        return false
    end
    
    -- Serializar mensaje
    local function serializeTable(tbl)
        local function serializeValue(v)
            if type(v) == "number" or type(v) == "boolean" then
                return tostring(v)
            elseif type(v) == "string" then
                return '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
            elseif type(v) == "table" then
                return serializeTable(v)
            else
                return "null"
            end
        end
        
        local parts = {}
        for k, v in pairs(tbl) do
            table.insert(parts, '"' .. k .. '":' .. serializeValue(v))
        end
        return '{' .. table.concat(parts, ',') .. '}'
    end
    
    local json = serializeTable(message)
    local length = #json
    
    -- Enviar longitud seguida del mensaje
    local header = string.pack(">I4", length) .. json
    
    local result, err = self.connectionSocket:send(header)
    if result == nil then
        self.currentState = self.state.error
        if self.callbacks.onDisconnect then
            self.callbacks.onDisconnect()
        end
        return false
    end
    
    return true
end

-- Recibir datos
function NetworkManager:receiveData()
    if not self.connectionSocket then
        return
    end
    
    -- Intentar recibir datos
    local data, err, partial = self.connectionSocket:receive("*a")
    
    if err == "timeout" then
        -- No hay datos disponibles, intentar de nuevo más tarde
        return
    elseif data then
        -- Procesar datos recibidos
        self:processReceivedData(data)
    elseif partial and #partial > 0 then
        -- Datos parciales recibidos
        self:processReceivedData(partial)
    elseif err == "closed" then
        -- Conexión cerrada
        self.currentState = self.state.disconnected
        if self.callbacks.onDisconnect then
            self.callbacks.onDisconnect()
        end
    end
end

-- Procesar datos recibidos
function NetworkManager:processReceivedData(data)
    -- Buffer para datos recibidos
    if not self.receiveBuffer then
        self.receiveBuffer = ""
    end
    
    self.receiveBuffer = self.receiveBuffer .. data
    
    -- Procesar mensajes completos
    while #self.receiveBuffer >= 4 do
        -- Leer longitud del mensaje (primeros 4 bytes)
        local len = string.unpack(">I4", self.receiveBuffer:sub(1, 4))
        
        -- Verificar si tenemos el mensaje completo
        if #self.receiveBuffer >= 4 + len then
            -- Extraer mensaje JSON
            local jsonStr = self.receiveBuffer:sub(5, 4 + len)
            
            -- Desactivar el mensaje del buffer
            self.receiveBuffer = self.receiveBuffer:sub(5 + len)
            
            -- Parsear JSON
            local success, message = pcall(function()
                return load("return " .. jsonStr)()
            end)
            
            if success and message then
                self:processMessage(message)
            else
                -- Error al parsear mensaje, descartarlo
            end
        else
            -- No tenemos el mensaje completo aún
            break
        end
    end
end

-- Registrar callback
function NetworkManager:on(event, callback)
    self.callbacks[event] = callback
end

-- Obtener estado
function NetworkManager:getState()
    return self.currentState
end

-- Obtener lobby actual
function NetworkManager:getCurrentLobby()
    return self.currentLobby
end

-- Obtener jugadores
function NetworkManager:getPlayers()
    if self.currentLobby then
        return self.currentLobby.players
    end
    return {}
end

-- Limpiar
function NetworkManager:cleanup()
    self:disconnect()
    self.lobbies = {}
    self.players = {}
end

return NetworkManager