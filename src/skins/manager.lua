--[[
    RITMINITY - Skin System
    Sistema de skins totalmente personalizable
]]

local SkinManager = {}
SkinManager.__index = SkinManager

-- Skin por defecto
SkinManager.defaultSkin = {
    name = "Default",
    version = "1.0",
    
    -- Colores
    colors = {
        background = {0.05, 0.05, 0.1, 1},
        primary = {0.2, 0.6, 1, 1},
        secondary = {0.1, 0.4, 0.8, 1},
        accent = {1, 0.5, 0, 1},
        judgmentPerfect = {1, 0.8, 0, 1},
        judgmentGreat = {0.2, 1, 0.2, 1},
        judgmentGood = {0.2, 0.6, 1, 1},
        judgmentBad = {1, 0.3, 0.3, 1},
        judgmentMiss = {0.5, 0.5, 0.5, 1},
        combo = {1, 1, 1, 1},
        score = {1, 1, 1, 1},
        gradeSS = {1, 0.8, 0, 1},
        gradeS = {1, 0.5, 0, 1},
        gradeA = {0.2, 1, 0.2, 1},
        gradeB = {0.2, 0.8, 1, 1},
        gradeC = {0.6, 0.6, 1, 1},
        gradeD = {0.8, 0.4, 0.4, 1},
        gradeF = {0.5, 0.5, 0.5, 1}
    },
    
    -- Dimensiones
    dimensions = {
        columnWidth = 80,
        columnSpacing = 5,
        noteHeight = 20,
        receptorHeight = 30,
        judgmentHeight = 50,
        comboHeight = 40,
        scoreHeight = 30,
        hitPosition = 650,
        judgmentPosition = 100
    },
    
    -- Fuentes
    fonts = {
        combo = "default",
        score = "default",
        judgment = "default",
        grade = "default"
    },
    
    -- Animaciones
    animations = {
        noteHitScale = 1.2,
        noteHitDuration = 0.1,
        comboPulseScale = 1.1,
        comboPulseDuration = 0.2,
        judgmentFadeDuration = 0.5,
        receptorGlow = true
    },
    
    -- Elementos visuales
    elements = {
        showReceptor = true,
        showColumnLines = true,
        showJudgment = true,
        showCombo = true,
        showScore = true,
        showAccuracy = true,
        showProgress = true,
        showHealthBar = true,
        showTimer = true
    },
    
    -- Sonidos
    sounds = {
        hitSound = true,
        missSound = true,
        comboSound = true,
        backgroundMusic = true
    }
}

function SkinManager:new()
    local self = setmetatable({}, SkinManager)
    self.currentSkin = self.defaultSkin
    self.customSkins = {}
    return self
end

-- Cargar skin desde archivo
function SkinManager:loadSkin(skinPath)
    -- Por implementar: cargar desde archivo JSON
    local success, skin = pcall(love.filesystem.load, skinPath)
    if success and skin then
        self.currentSkin = skin
        return true
    end
    return false
end

-- Cargar skin por nombre
function SkinManager:loadSkinByName(name)
    if name == "Default" then
        self.currentSkin = self.defaultSkin
        return true
    end
    
    if self.customSkins[name] then
        self.currentSkin = self.customSkins[name]
        return true
    end
    
    return false
end

-- Guardar skin actual
function SkinManager:saveSkin(name, path)
    self.customSkins[name] = self.currentSkin
    -- Por implementar: guardar a archivo
end

-- Obtener color
function SkinManager:getColor(colorName)
    return self.currentSkin.colors[colorName] or {1, 1, 1, 1}
end

-- Obtener dimensión
function SkinManager:getDimension(dimName)
    return self.currentSkin.dimensions[dimName] or 0
end

-- Obtener animación
function SkinManager:getAnimation(animName)
    return self.currentSkin.animations[animName]
end

-- Obtener elemento
function SkinManager:getElement(elemName)
    return self.currentSkin.elements[elemName]
end

-- Modificar color
function SkinManager:setColor(colorName, r, g, b, a)
    self.currentSkin.colors[colorName] = {r, g, b, a or 1}
end

-- Modificar dimensión
function SkinManager:setDimension(dimName, value)
    self.currentSkin.dimensions[dimName] = value
end

-- Modificar elemento
function SkinManager:setElement(elemName, value)
    self.currentSkin.elements[elemName] = value
end

-- Reiniciar a skin por defecto
function SkinManager:resetToDefault()
    self.currentSkin = self.defaultSkin
end

-- Obtener skin actual
function SkinManager:getCurrentSkin()
    return self.currentSkin
end

-- Obtener lista de skins disponibles
function SkinManager:getAvailableSkins()
    local skins = {"Default"}
    for name, _ in pairs(self.customSkins) do
        table.insert(skins, name)
    end
    return skins
end

return SkinManager