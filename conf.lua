-- RITMINITY - Videojuego de Ritmo Profesional
-- Motor: Love2D (Lua)
-- Versión: 1.0.0
-- Licencia: MIT

local config = {}

config.name = "RITMINITY"
config.version = "1.0.0"
config.author = "Ritminity Team"
config.license = "MIT"

-- Configuración de pantalla
config.screen = {
    width = 1280,
    height = 720,
    fullscreen = false,
    vsync = true,
    msaa = 0
}

-- Configuración de audio
config.audio = {
    mixerChannels = 16,
    sampleRate = 44100,
    bitDepth = 16,
    bufferSize = 1024
}

-- Configuración de rendimiento
config.performance = {
    targetFPS = 60,
    maxDeltaTime = 0.1,
    objectPooling = true,
    garbageCollectionInterval = 2.0
}

-- Configuración de red
config.network = {
    enableUPnP = true,
    maxConnections = 8,
    timeout = 30,
    retryAttempts = 3
}

-- Rutas de archivos
config.paths = {
    songs = "assets/songs/",
    charts = "assets/charts/",
    skins = "assets/skins/",
    replays = "assets/replays/",
    cache = "cache/",
    logs = "logs/"
}

-- Configuración de debug
config.debug = {
    enabled = true,
    showFPS = true,
    showMemory = true,
    logLevel = "info" -- trace, debug, info, warn, error
}

return config