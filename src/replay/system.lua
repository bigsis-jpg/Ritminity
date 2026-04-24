--[[
    RITMINITY - Replay System
    Sistema completo de grabación y reproducción de partidas
]]

local ReplaySystem = {}
ReplaySystem.__index = ReplaySystem

-- Formato de replay
ReplaySystem.format = {
    version = "1.0",
    game = "RITMINITY"
}

function ReplaySystem:new()
    local self = setmetatable({}, ReplaySystem)
    self:reset()
    return self
end

function ReplaySystem:reset()
    self.frames = {}
    self.currentFrame = 0
    self.playing = false
    self.recording = false
    self.startTime = 0
    
    -- Metadatos del replay
    self.metadata = {
        mapHash = "",
        playerName = "",
        score = 0,
        maxCombo = 0,
        accuracy = 0,
        grade = "F",
        mods = "",
        timestamp = 0,
        replayVersion = self.format.version
    }
end

-- Iniciar grabación
function ReplaySystem:startRecording(mapHash, playerName, mods)
    self:reset()
    self.recording = true
    self.startTime = love.timer.getTime()
    
    self.metadata.mapHash = mapHash or ""
    self.metadata.playerName = playerName or "Player"
    self.metadata.mods = mods or ""
    self.metadata.timestamp = os.time()
end

-- Detener grabación
function ReplaySystem:stopRecording()
    self.recording = false
end

-- Agregar frame
function ReplaySystem:addFrame(time, keys, mouseX, mouseY)
    if not self.recording then
        return
    end
    
    local frame = {
        time = time,
        keys = keys or {},
        mouseX = mouseX or 0,
        mouseY = mouseY or 0
    }
    
    table.insert(self.frames, frame)
end

-- Guardar replay a archivo
function ReplaySystem:save(path)
    local data = {
        format = self.format,
        metadata = self.metadata,
        frames = self.frames
    }
    
    -- Serializar a formato Lua (más seguro y directo que JSON falso)
    local luaCode = self:serialize(data)
    
    local file = love.filesystem.newFile(path)
    file:open("w")
    file:write(luaCode)
    file:close()
    
    return true
end

-- Cargar replay desde archivo
function ReplaySystem:load(path)
    local file = love.filesystem.newFile(path)
    if not file then
        return false
    end
    
    file:open("r")
    local content = file:read()
    file:close()
    
    local data = self:deserialize(content)
    if type(data) ~= "table" then
        return false
    end
    
    self.format = data.format
    self.metadata = data.metadata
    self.frames = data.frames
    
    return true
end

-- Serializar a Lua Table String
function ReplaySystem:serialize(data)
    local function serializeValue(value, indent)
        indent = indent or 0
        local indentStr = string.rep("  ", indent)
        
        if type(value) == "nil" then
            return "nil"
        elseif type(value) == "boolean" or type(value) == "number" then
            return tostring(value)
        elseif type(value) == "string" then
            return string.format("%q", value)
        elseif type(value) == "table" then
            local parts = {}
            local isArray = true
            local maxIndex = 0
            for k, _ in pairs(value) do
                if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
                    isArray = false
                    break
                end
                maxIndex = math.max(maxIndex, k)
            end
            
            if isArray and maxIndex > 0 then
                for i = 1, maxIndex do
                    table.insert(parts, serializeValue(value[i], indent + 1))
                end
                return "{" .. table.concat(parts, ", ") .. "}"
            else
                for k, v in pairs(value) do
                    local keyStr
                    if type(k) == "string" and k:match("^[%a_][%w_]*$") then
                        keyStr = k
                    else
                        keyStr = "[" .. serializeValue(k) .. "]"
                    end
                    table.insert(parts, indentStr .. "  " .. keyStr .. " = " .. serializeValue(v, indent + 1))
                end
                return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indentStr .. "}"
            end
        else
            return "nil"
        end
    end
    
    return serializeValue(data)
end

-- Deserializar desde Lua Table String (Seguro)
function ReplaySystem:deserialize(dataStr)
    -- Usar función load de Lua, pero con sandbox para evitar código malicioso
    local func, err = load("return " .. dataStr)
    if func then
        -- Sandbox en Lua 5.1/Love2D
        if setfenv then setfenv(func, {}) end 
        local success, result = pcall(func)
        if success then
            return result
        end
    end
    return nil
end

-- Iniciar reproducción
function ReplaySystem:startPlayback()
    self.currentFrame = 1
    self.playing = true
end

-- Detener reproducción
function ReplaySystem:stopPlayback()
    self.playing = false
end

-- Obtener frame actual
function ReplaySystem:getCurrentFrame()
    if self.currentFrame > #self.frames then
        return nil
    end
    return self.frames[self.currentFrame]
end

-- Avanzar al siguiente frame
function ReplaySystem:nextFrame()
    if self.currentFrame < #self.frames then
        self.currentFrame = self.currentFrame + 1
        return self:getCurrentFrame()
    end
    return nil
end

-- Ir a un tiempo específico
function ReplaySystem:seekToTime(time)
    for i, frame in ipairs(self.frames) do
        if frame.time >= time then
            self.currentFrame = i
            return frame
        end
    end
    return nil
end

-- Obtener duración del replay
function ReplaySystem:getDuration()
    if #self.frames == 0 then
        return 0
    end
    return self.frames[#self.frames].time
end

-- Verificar si está reproduciendo
function ReplaySystem:isPlaying()
    return self.playing
end

-- Verificar si está grabando
function ReplaySystem:isRecording()
    return self.recording
end

-- Obtener metadatos
function ReplaySystem:getMetadata()
    return self.metadata
end

-- Establecer metadatos
function ReplaySystem:setMetadata(key, value)
    self.metadata[key] = value
end

-- Obtener número de frames
function ReplaySystem:getFrameCount()
    return #self.frames
end

-- Comprimir replay (reducir frames redundantes)
function ReplaySystem:compress()
    if #self.frames <= 1 then
        return
    end
    
    local compressed = {}
    local lastKeys = {}
    
    for _, frame in ipairs(self.frames) do
        local keysChanged = false
        
        -- Verificar si hay nuevas teclas presionadas
        for k, v in pairs(frame.keys) do
            if lastKeys[k] ~= v then
                keysChanged = true
                break
            end
        end
        
        -- Verificar si alguna tecla fue soltada (CRÍTICO)
        if not keysChanged then
            for k, v in pairs(lastKeys) do
                if frame.keys[k] ~= v then
                    keysChanged = true
                    break
                end
            end
        end
        
        if keysChanged or frame.mouseX ~= 0 or frame.mouseY ~= 0 then
            table.insert(compressed, frame)
            -- Hacer copia profunda para el próximo frame
            local copy = {}
            for k,v in pairs(frame.keys) do copy[k] = v end
            lastKeys = copy
        end
    end
    
    self.frames = compressed
end

return ReplaySystem