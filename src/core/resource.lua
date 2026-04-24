--[[
    RITMINITY - Core Resource Manager
    Sistema de gestión de recursos (imágenes, audio, fuentes, etc.)
]]

local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager:initialize()
    self.images = {}
    self.sounds = {}
    self.music = {}
    self.fonts = {}
    self.shaders = {}
    self.quads = {}
    
    self.loadQueue = {}
    self.loading = false
    self.currentProgress = 0
    self.totalResources = 0
    
    -- Rutas de recursos
    self.paths = {
        images = "assets/images/",
        sounds = "assets/sounds/",
        music = "assets/music/",
        fonts = "assets/fonts/",
        charts = "assets/charts/",
        skins = "assets/skins/"
    }
end

-- Cargar una imagen
function ResourceManager:loadImage(name, path)
    if self.images[name] then
        return self.images[name]
    end
    
    local fullPath = self.paths.images .. path
    local image = love.graphics.newImage(fullPath)
    
    if image then
        self.images[name] = image
        return image
    end
    
    return nil
end

-- Cargar múltiples imágenes
function ResourceManager:loadImages(mappings)
    for name, path in pairs(mappings) do
        self:loadImage(name, path)
    end
end

-- Cargar un sonido
function ResourceManager:loadSound(name, path)
    if self.sounds[name] then
        return self.sounds[name]
    end
    
    local fullPath = self.paths.sounds .. path
    local sound = love.audio.newSource(fullPath, "static")
    
    if sound then
        self.sounds[name] = sound
        return sound
    end
    
    return nil
end

-- Cargar música
function ResourceManager:loadMusic(name, path)
    if self.music[name] then
        return self.music[name]
    end
    
    local fullPath = self.paths.music .. path
    local music = love.audio.newSource(fullPath, "stream")
    
    if music then
        self.music[name] = music
        return music
    end
    
    return nil
end

-- Cargar una fuente
function ResourceManager:loadFont(name, path, size)
    if self.fonts[name] then
        return self.fonts[name]
    end
    
    local fullPath = self.paths.fonts .. path
    local font = love.graphics.newFont(fullPath, size)
    
    if font then
        self.fonts[name] = font
        return font
    end
    
    -- Fallback a fuente del sistema
    font = love.graphics.newFont(size)
    self.fonts[name] = font
    return font
end

-- Obtener una imagen
function ResourceManager:getImage(name)
    return self.images[name]
end

-- Obtener un sonido
function ResourceManager:getSound(name)
    return self.sounds[name]
end

-- Obtener música
function ResourceManager:getMusic(name)
    return self.music[name]
end

-- Obtener una fuente
function ResourceManager:getFont(name)
    return self.fonts[name]
end

-- Reproducir un sonido
function ResourceManager:playSound(name, volume, pitch)
    local sound = self.sounds[name]
    if sound then
        local clone = sound:clone()
        clone:setVolume(volume or 1.0)
        clone:setPitch(pitch or 1.0)
        clone:play()
        return clone
    end
    return nil
end

-- Reproducir música
function ResourceManager:playMusic(name, volume)
    -- Detener música actual
    self:stopMusic()
    
    local music = self.music[name]
    if music then
        music:setVolume(volume or 0.5)
        music:setLooping(true)
        music:play()
        return music
    end
    return nil
end

-- Detener música
function ResourceManager:stopMusic()
    for _, music in pairs(self.music) do
        music:stop()
    end
end

-- Pausar música
function ResourceManager:pauseMusic()
    for _, music in pairs(self.music) do
        if music:isPlaying() then
            music:pause()
        end
    end
end

-- Reanudar música
function ResourceManager:resumeMusic()
    for _, music in pairs(self.music) do
        music:resume()
    end
end

-- Crear un quad
function ResourceManager:createQuad(name, image, x, y, w, h)
    local quad = love.graphics.newQuad(x, y, w, h, image:getDimensions())
    self.quads[name] = {
        quad = quad,
        image = image
    }
    return quad
end

-- Obtener un quad
function ResourceManager:getQuad(name)
    return self.quads[name]
end

-- Cargar un shader
function ResourceManager:loadShader(name, vertexPath, fragmentPath)
    local success, shader = pcall(love.graphics.newShader, vertexPath, fragmentPath)
    
    if success then
        self.shaders[name] = shader
        return shader
    end
    
    return nil
end

-- Obtener un shader
function ResourceManager:getShader(name)
    return self.shaders[name]
end

-- Verificar si un recurso está cargado
function ResourceManager:isLoaded(resourceType, name)
    if resourceType == "image" then
        return self.images[name] ~= nil
    elseif resourceType == "sound" then
        return self.sounds[name] ~= nil
    elseif resourceType == "music" then
        return self.music[name] ~= nil
    elseif resourceType == "font" then
        return self.fonts[name] ~= nil
    elseif resourceType == "shader" then
        return self.shaders[name] ~= nil
    end
    return false
end

-- Descargar un recurso
function ResourceManager:unload(resourceType, name)
    if resourceType == "image" then
        self.images[name] = nil
    elseif resourceType == "sound" then
        self.sounds[name] = nil
    elseif resourceType == "music" then
        self.music[name] = nil
    elseif resourceType == "font" then
        self.fonts[name] = nil
    elseif resourceType == "shader" then
        self.shaders[name] = nil
    elseif resourceType == "quad" then
        self.quads[name] = nil
    end
end

-- Descargar todos los recursos de un tipo
function ResourceManager:unloadAll(resourceType)
    if resourceType == "image" then
        self.images = {}
    elseif resourceType == "sound" then
        self.sounds = {}
    elseif resourceType == "music" then
        self.music = {}
    elseif resourceType == "font" then
        self.fonts = {}
    elseif resourceType == "shader" then
        self.shaders = {}
    elseif resourceType == "quad" then
        self.quads = {}
    end
end

-- Obtener memoria estimada usada
function ResourceManager:getMemoryUsage()
    local total = 0
    
    for _, img in pairs(self.images) do
        total = total + (img:getWidth() * img:getHeight() * 4)
    end
    
    return total
end

-- Actualizar (para recursos que necesitan actualización)
function ResourceManager:update(dt)
    -- Por ahora vacío, se puede expandir para streaming de audio
end

-- Limpiar todos los recursos
function ResourceManager:cleanup()
    self:unloadAll("image")
    self:unloadAll("sound")
    self:unloadAll("music")
    self:unloadAll("font")
    self:unloadAll("shader")
    self:unloadAll("quad")
end

return ResourceManager