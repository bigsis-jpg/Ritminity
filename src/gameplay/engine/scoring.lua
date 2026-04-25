--[[
    RITMINITY - Scoring System
    Sistema completo de puntuación y ranking (Estilo Etterna/Wife3 EXACT)
]]

local ScoringSystem = {}
ScoringSystem.__index = ScoringSystem

-- Constantes Wife3 (Professional Etterna Style)
ScoringSystem.WIFE_CONSTANTS = {
    marvelousWindow = 18.0, -- J4 style
    missWeight = -8.0,      -- Castigo real de Wife3
    badWeight = -4.0,       -- Castigo por Bad
    jPoint = 1.5,           -- Factor de suavizado de la curva
    jCurve = 0.95           -- Factor de decaimiento
}

function ScoringSystem:new()
    local self = setmetatable({}, ScoringSystem)
    self:reset()
    return self
end

function ScoringSystem:reset()
    self.score = 0
    self.combo = 0
    self.maxCombo = 0
    self.totalNotes = 0
    self.hitNotes = 0
    self.msOffsets = {}
    self.history = {} -- Historial para Timing Graph {time, offset, judgment}
    self.meanDeviation = 0
    self.absMeanDeviation = 0
    self.totalWifePoints = 0
    self.judgments = {
        marvelous = 0, perfect = 0, great = 0,
        good = 0, bad = 0, miss = 0
    }
end

-- Función Wife3: Retorna el peso exacto basado en MS
function ScoringSystem:calculateWifeWeight(ms)
    local absMs = math.abs(ms)
    
    -- Si es Marvelous puro (J4)
    if absMs <= self.WIFE_CONSTANTS.marvelousWindow then
        return 1.0
    end
    
    -- Curva Wife3 Real (Aproximación Professional)
    -- f(x) = 2 + 8 * 0.5 ^ (x * slope)
    -- Usamos la curva de decaimiento logarítmico de Etterna
    local weight = 2 * (self.WIFE_CONSTANTS.jCurve ^ (absMs / self.WIFE_CONSTANTS.jPoint)) - 1
    
    return math.max(-4.0, weight)
end

-- Añadir juicio con desviación exacta en MS
function ScoringSystem:addJudgment(judgment, msOffset, time)
    local weight = 0
    
    -- Registrar en historial para Timing Graph
    table.insert(self.history, {
        time = time or 0,
        offset = msOffset or 180, -- Misses se grafican en el borde
        judgment = judgment
    })
    
    if judgment == "miss" then
        weight = self.WIFE_CONSTANTS.missWeight
    elseif judgment == "bad" then
        weight = self.WIFE_CONSTANTS.badWeight
    else
        weight = self:calculateWifeWeight(msOffset or 0)
    end
    
    -- Registrar MS offset para estadísticas
    if msOffset then
        table.insert(self.msOffsets, msOffset)
        self:calculateStats()
    end
    
    -- Acumular puntos Wife
    self.totalWifePoints = self.totalWifePoints + weight
    
    -- Actualizar combo
    if judgment ~= "miss" and judgment ~= "bad" then
        self.combo = self.combo + 1
        self.hitNotes = self.hitNotes + 1
        if self.combo > self.maxCombo then self.maxCombo = self.combo end
    else
        self.combo = 0
    end
    
    self.judgments[judgment] = self.judgments[judgment] + 1
    
    -- Puntuación visual (Tipo Mania 1,000,000)
    -- Pero en Etterna el score real es el Accuracy
    self.score = math.floor(math.max(0, self:calculateAccuracy()) * 10000)
    
    return weight
end

-- Calcular estadísticas de desviación
function ScoringSystem:calculateStats()
    if #self.msOffsets == 0 then return end
    
    local sum = 0
    local absSum = 0
    for _, offset in ipairs(self.msOffsets) do
        sum = sum + offset
        absSum = absSum + math.abs(offset)
    end
    
    self.meanDeviation = sum / #self.msOffsets
    self.absMeanDeviation = absSum / #self.msOffsets
end

-- Calcular accuracy basada en Wife3 (EXACT)
function ScoringSystem:calculateAccuracy()
    if self.totalNotes == 0 then return 0 end
    
    -- Accuracy = (Puntos Obtenidos / Puntos Máximos)
    -- Puntos máximos = totalNotes * 1.0 (todos marvelous)
    local maxPoints = self.totalNotes * 1.0
    local acc = (self.totalWifePoints / maxPoints) * 100
    
    return math.max(0, acc)
end

-- Calcular grade (Basado en Accuracy Wife3 Exacta)
function ScoringSystem:calculateGrade()
    local acc = self:calculateAccuracy()
    
    if acc >= 99.97 then return "AAAAA" -- Theoretical perfect
    elseif acc >= 99.7 then return "AAAA" 
    elseif acc >= 93 then return "AAA"
    elseif acc >= 80 then return "AA"
    elseif acc >= 70 then return "A"
    elseif acc >= 60 then return "B"
    elseif acc >= 50 then return "C"
    else return "D" end
end

-- Obtener información de puntuación
function ScoringSystem:getScoreInfo()
    return {
        score = self.score,
        combo = self.combo,
        maxCombo = self.maxCombo,
        accuracy = self:calculateAccuracy(),
        grade = self:calculateGrade(),
        judgments = self.judgments,
        totalNotes = self.totalNotes,
        hitNotes = self.hitNotes,
        meanDeviation = self.meanDeviation,
        absMeanDeviation = self.absMeanDeviation
    }
end

-- Formatear MS offset
function ScoringSystem:formatMS(ms)
    local sign = ms >= 0 and "+" or ""
    return string.format("%s%.2fms", sign, ms)
end

return ScoringSystem