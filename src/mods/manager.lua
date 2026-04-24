--[[
    RITMINITY - Mods System
    Sistema completo de mods de juego
]]

local Mods = {}
Mods.__index = Mods

-- Definición de mods
Mods.modList = {
    -- Mods de dificultad
    easy = {
        name = "Easy",
        shortName = "EZ",
        description = "Reduce la dificultad del mapa",
        scoreMultiplier = 0.5,
        arMultiplier = 0.5,
        csMultiplier = 0.8,
        hpMultiplier = 0.5
    },
    normal = {
        name = "Normal",
        shortName = "NR",
        description = "Dificultad estándar",
        scoreMultiplier = 1.0,
        arMultiplier = 1.0,
        csMultiplier = 1.0,
        hpMultiplier = 1.0
    },
    hard = {
        name = "Hard",
        shortName = "HR",
        description = "Aumenta la dificultad del mapa",
        scoreMultiplier = 1.0,
        arMultiplier = 1.2,
        csMultiplier = 1.1,
        hpMultiplier = 1.2
    },
    insane = {
        name = "Insane",
        shortName = "IN",
        description = "Dificultad extrema",
        scoreMultiplier = 1.0,
        arMultiplier = 1.4,
        csMultiplier = 1.3,
        hpMultiplier = 1.5
    },
    
    -- Mods de velocidad
    dt = {
        name = "Double Time",
        shortName = "DT",
        description = "Aumenta la velocidad 1.5x",
        scoreMultiplier = 1.0,
        speedMultiplier = 1.5,
        arMultiplier = 1.0,
        noteSpeed = 1.5
    },
    ht = {
        name = "Half Time",
        shortName = "HT",
        description = "Reduce la velocidad 0.75x",
        scoreMultiplier = 0.5,
        speedMultiplier = 0.75,
        arMultiplier = 0.75,
        noteSpeed = 0.75
    },
    nc = {
        name = "Nightcore",
        shortName = "NC",
        description = "Como DT pero con música más rápida",
        scoreMultiplier = 1.0,
        speedMultiplier = 1.5,
        arMultiplier = 1.0,
        noteSpeed = 1.5,
        musicPitch = 1.5
    },
    
    -- Mods de visibilidad
    hd = {
        name = "Hidden",
        shortName = "HD",
        description = "Las notas desaparecen cerca del receptor",
        scoreMultiplier = 1.0,
        fadeOut = true
    },
    hdfl = {
        name = "Hidden + Fade Out",
        shortName = "HF",
        description = "Notas desaparecen con desvanecimiento",
        scoreMultiplier = 1.0,
        fadeOut = true,
        fadeOutTime = 0.3
    },
    fi = {
        name = "Fade In",
        shortName = "FI",
        description = "Las notas aparecen gradualmente",
        scoreMultiplier = 1.0,
        fadeIn = true
    },
    
    -- Mods de jugabilidad
    fl = {
        name = "Flashlight",
        shortName = "FL",
        description = "Solo ilumina el área alrededor del receptor",
        scoreMultiplier = 1.0,
        flashlight = true
    },
    at = {
        name = "Autoplay",
        shortName = "AT",
        description = "El juego juega automáticamente",
        scoreMultiplier = 1.0,
        autoplay = true
    },
    sc = {
        name = "Score Competition",
        shortName = "SC",
        description = "Competencia de puntuación",
        scoreMultiplier = 1.0,
        scoreMode = "score"
    },
    
    -- Mods de visualización
    mirror = {
        name = "Mirror",
        shortName = "MR",
        description = "Invierte las columnas",
        scoreMultiplier = 1.0,
        mirror = true
    },
    random = {
        name = "Random",
        shortName = "RN",
        description = "Aleatoriza el orden de las notas",
        scoreMultiplier = 1.0,
        random = true
    },
    shuffle = {
        name = "Shuffle",
        shortName = "SF",
        description = "Mezcla las columnas",
        scoreMultiplier = 1.0,
        shuffle = true
    },
    
    -- Mods especiales
    ez = {
        name = "Easy",
        shortName = "EZ",
        description = "Versión alternativa de Easy",
        scoreMultiplier = 0.5,
        arMultiplier = 0.5
    },
    nf = {
        name = "No Fail",
        shortName = "NF",
        description = "No puedes perder",
        scoreMultiplier = 0.5,
        noFail = true
    },
    sp = {
        name = "Sudden Death",
        shortName = "SD",
        description = "Un miss termina el juego",
        scoreMultiplier = 1.0,
        suddenDeath = true
    },
    ap = {
        name = "Auto Pilot",
        shortName = "AP",
        description = "El cursor se mueve automáticamente",
        scoreMultiplier = 1.0,
        autoPilot = true
    },
    pf = {
        name = "Perfect",
        shortName = "PF",
        description = "Un miss menor termina el juego",
        scoreMultiplier = 1.0,
        perfect = true
    },
    so = {
        name = "Spin Out",
        shortName = "SO",
        description = "El cursor gira automáticamente",
        scoreMultiplier = 1.0,
        spinOut = true
    },
    v2 = {
        name = "v2",
        shortName = "V2",
        description = "Usa el sistema de puntuación v2",
        scoreMultiplier = 1.0,
        v2 = true
    }
}

function Mods:new()
    local self = setmetatable({}, Mods)
    self.activeMods = {}
    return self
end

-- Activar un mod
function Mods:activate(modName)
    local mod = self.modList[modName]
    if mod then
        self.activeMods[modName] = mod
    end
end

-- Desactivar un mod
function Mods:deactivate(modName)
    self.activeMods[modName] = nil
end

-- Verificar si un mod está activo
function Mods:isActive(modName)
    return self.activeMods[modName] ~= nil
end

-- Obtener todos los mods activos
function Mods:getActiveMods()
    return self.activeMods
end

-- Obtener multiplicador de puntuación total
function Mods:getScoreMultiplier()
    local multiplier = 1.0
    for _, mod in pairs(self.activeMods) do
        multiplier = multiplier * (mod.scoreMultiplier or 1.0)
    end
    return multiplier
end

-- Obtener velocidad de notas
function Mods:getNoteSpeed()
    local speed = 1.0
    for _, mod in pairs(self.activeMods) do
        if mod.noteSpeed then
            speed = speed * mod.noteSpeed
        end
    end
    return speed
end

-- Obtener velocidad de música
function Mods:getMusicPitch()
    local pitch = 1.0
    for _, mod in pairs(self.activeMods) do
        if mod.musicPitch then
            pitch = mod.musicPitch
        end
    end
    return pitch
end

-- Obtener AR multiplier
function Mods:getARMultiplier()
    local ar = 1.0
    for _, mod in pairs(self.activeMods) do
        if mod.arMultiplier then
            ar = ar * mod.arMultiplier
        end
    end
    return ar
end

-- Obtener CS multiplier
function Mods:getCSMultiplier()
    local cs = 1.0
    for _, mod in pairs(self.activeMods) do
        if mod.csMultiplier then
            cs = cs * mod.csMultiplier
        end
    end
    return cs
end

-- Obtener HP multiplier
function Mods:getHPMultiplier()
    local hp = 1.0
    for _, mod in pairs(self.activeMods) do
        if mod.hpMultiplier then
            hp = hp * mod.hpMultiplier
        end
    end
    return hp
end

-- Verificar si hay mod de autoplay
function Mods:hasAutoplay()
    return self.activeMods["at"] ~= nil
end

-- Verificar si hay mod de mirror
function Mods:hasMirror()
    return self.activeMods["mirror"] ~= nil
end

-- Verificar si hay mod de random
function Mods:hasRandom()
    return self.activeMods["random"] ~= nil
end

-- Verificar si hay mod de no-fail
function Mods:hasNoFail()
    return self.activeMods["nf"] ~= nil
end

-- Obtener string de mods activos
function Mods:getModString()
    local modStrings = {}
    for name, _ in pairs(self.activeMods) do
        table.insert(modStrings, self.modList[name].shortName)
    end
    table.sort(modStrings)
    return table.concat(modStrings, "")
end

-- Limpiar todos los mods
function Mods:clear()
    self.activeMods = {}
end

-- Obtener lista de mods
function Mods:getModList()
    return self.modList
end

return Mods