--[[
    RITMINITY - Audio Manager
    Sistema de audio con sincronización precisa para juegos de ritmo
]]

local AudioManager = {}
AudioManager.__index = AudioManager

-- Canales de audio
AudioManager.channels = {}
AudioManager.maxChannels = 16

-- Música actual
AudioManager.currentMusic = nil

-- Timing del sistema
AudioManager.systemTime = 0
AudioManager.audioTime = 0

-- Offset de latencia
AudioManager.offset = 0

-- Volumen global
AudioManager.masterVolume = 1.0
AudioManager.musicVolume = 0.8
AudioManager.effectVolume = 1.0

-- Para sincronización
AudioManager.lastUpdateTime = 0
AudioManager.deltaAccumulator = 0

function AudioManager:initialize()
    self.channels = {}
    self.currentMusic = nil
    self.systemTime = 0
    self.audioTime = 0
    self.offset = 0
    self.deltaAccumulator = 0
    self.lastUpdateTime = love.timer.getTime()
    
    -- Crear canales
    for i = 1, self.maxChannels do
        self.channels[i] = {
            source = nil,
            playing = false,
            volume = 1.0,
            pitch = 1.0
        }
    end
end

-- Cargar música
function AudioManager:loadMusic(path)
    if not path or not love.filesystem.getInfo(path) then
        print("[AudioManager] Warning: Music file not found: " .. tostring(path))
        return nil
    end
    local music = love.audio.newSource(path, "stream")
    if music then
        music:setLooping(false)
    end
    return music
end

-- Cargar sonido
function AudioManager:loadSound(path)
    if not path or not love.filesystem.getInfo(path) then
        print("[AudioManager] Warning: Sound file not found: " .. tostring(path))
        return nil
    end
    local sound = love.audio.newSource(path, "static")
    return sound
end

-- Reproducir música
function AudioManager:playMusic(music, volume)
    if self.currentMusic then
        self.currentMusic:stop()
    end
    
    self.currentMusic = music
    if music then
        music:setVolume((volume or 1.0) * self.musicVolume * self.masterVolume)
        music:play()
        
        -- Resetear relojes para evitar saltos de tiempo
        self.audioTime = 0
        self.systemTime = 0
        self.lastUpdateTime = love.timer.getTime()
        self.deltaAccumulator = 0
    end
end

-- Detener música
function AudioManager:stopMusic()
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentMusic = nil
    end
end

-- Pausar música
function AudioManager:pauseMusic()
    if self.currentMusic then
        self.currentMusic:pause()
    end
end

-- Reanudar música
function AudioManager:resumeMusic()
    if self.currentMusic then
        self.currentMusic:play()
    end
end

-- Obtener tiempo actual de la música (Interpolado)
function AudioManager:getMusicTime()
    return self.audioTime
end

-- Obtener tiempo del sistema
function AudioManager:getSystemTime()
    return self.systemTime
end

-- Obtener tiempo de audio sincronizado
function AudioManager:getAudioTime()
    return self.audioTime - self.offset
end

-- Sincronizar tiempos con interpolación de alta precisión
function AudioManager:sync()
    local currentTime = love.timer.getTime()
    local dt = currentTime - self.lastUpdateTime
    self.lastUpdateTime = currentTime
    
    -- Actualizar tiempo del sistema
    self.systemTime = self.systemTime + dt
    
    -- Sincronizar con tiempo de audio con interpolación
    if self.currentMusic and self.currentMusic:isPlaying() then
        local rawTime = self.currentMusic:tell()
        
        -- Si el tiempo de audio no ha avanzado (pero debería), interpolar
        if rawTime == self.audioTime then
            self.deltaAccumulator = self.deltaAccumulator + dt
            self.audioTime = rawTime + self.deltaAccumulator
        else
            -- El audio avanzó, resincronizar
            self.audioTime = rawTime
            self.deltaAccumulator = 0
        end
    else
        -- No saltar a systemTime, mantener el tiempo actual o esperar al audio
        self.deltaAccumulator = 0
    end
end

-- Reproducir sonido en un canal
function AudioManager:playSound(sound, volume, pitch, pan)
    if not sound then return nil end
    
    -- Si es un string, es un error de uso en este punto o un path
    if type(sound) == "string" then
        -- Intentar cargar si parece un path, o ignorar si es un ID
        if sound:match("%.wav$") or sound:match("%.ogg$") or sound:match("%.mp3$") then
            sound = self:loadSound(sound)
        else
            print("[AudioManager] Error: playSound recibió un string ID '" .. sound .. "' pero no hay registro de sonidos.")
            return nil
        end
    end

    -- Buscar canal libre
    local channelIdx = self:findFreeChannel()
    if not channelIdx then return nil end
    local channel = self.channels[channelIdx]
    
    if sound and type(sound) ~= "string" and sound.clone then
        local clone = sound:clone()
        clone:setVolume((volume or 1.0) * self.effectVolume * self.masterVolume)
        clone:setPitch(pitch or 1.0)
        -- setPan no existe en Sources en Love2D estándar, se usa setRelative o similar 
        -- pero para simplicidad lo omitimos o usamos un wrapper si fuera necesario
        clone:play()
        
        channel.source = clone
        channel.playing = true
        channel.volume = volume or 1.0
        channel.pitch = pitch or 1.0
        
        return channel
    end
    
    return nil
end

-- Encontrar canal libre
function AudioManager:findFreeChannel()
    for i = 1, self.maxChannels do
        if not self.channels[i].playing or 
           (self.channels[i].source and not self.channels[i].source:isPlaying()) then
            return i
        end
    end
    return nil
end

-- Establecer offset de latencia
function AudioManager:setOffset(offset)
    self.offset = offset
end

-- Obtener offset de latencia
function AudioManager:getOffset()
    return self.offset
end

-- Calibrar latencia
function AudioManager:calibrate(audioTime, systemTime)
    self.offset = audioTime - systemTime
end

-- Establecer volumen master
function AudioManager:setMasterVolume(volume)
    self.masterVolume = math.max(0, math.min(1, volume))
    self:updateVolumes()
end

-- Establecer volumen de música
function AudioManager:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    self:updateVolumes()
end

-- Establecer volumen de efectos
function AudioManager:setEffectVolume(volume)
    self.effectVolume = math.max(0, math.min(1, volume))
end

-- Actualizar volúmenes
function AudioManager:updateVolumes()
    if self.currentMusic then
        self.currentMusic:setVolume(self.musicVolume * self.masterVolume)
    end
end



-- Obtener estado de la música
function AudioManager:isMusicPlaying()
    return self.currentMusic ~= nil and self.currentMusic:isPlaying()
end

-- Obtener duración de la música
function AudioManager:getMusicDuration()
    if self.currentMusic then
        return self.currentMusic:getDuration()
    end
    return 0
end

-- Buscar canal por sonido
function AudioManager:findChannelWithSound(sound)
    for i = 1, self.maxChannels do
        if self.channels[i].source == sound then
            return i
        end
    end
    return nil
end

-- Detener todos los sonidos
function AudioManager:stopAllSounds()
    for i = 1, self.maxChannels do
        if self.channels[i].source then
            self.channels[i].source:stop()
            self.channels[i].playing = false
        end
    end
end

-- Actualizar
function AudioManager:update(dt)
    self:sync()
    
    -- Verificar canales activos
    for i = 1, self.maxChannels do
        if self.channels[i].source then
            self.channels[i].playing = self.channels[i].source:isPlaying()
        end
    end
end

-- Limpiar
function AudioManager:cleanup()
    self:stopMusic()
    self:stopAllSounds()
    self.channels = {}
end

return AudioManager