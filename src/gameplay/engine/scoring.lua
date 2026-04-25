--[[
    RITMINITY - Scoring System
<<<<<<< HEAD
    Sistema completo de puntuación y ranking (Estilo Etterna/Wife3 EXACT)
=======
    Sistema completo de puntuación y ranking
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
]]

local ScoringSystem = {}
ScoringSystem.__index = ScoringSystem

<<<<<<< HEAD
-- Constantes Wife3 (Professional Etterna Style)
ScoringSystem.WIFE_CONSTANTS = {
    marvelousWindow = 18.0, -- J4 style
    missWeight = -8.0,      -- Castigo real de Wife3
    badWeight = -4.0,       -- Castigo por Bad
    jPoint = 1.5,           -- Factor de suavizado de la curva
    jCurve = 0.95           -- Factor de decaimiento
=======
-- Puntuación por juicio
ScoringSystem.judgmentValues = {
    perfect = 300,
    good = 100,
    bad = 50,
    miss = 0
}

-- Multiplicadores
ScoringSystem.comboMultipliers = {
    {10, 1.1},   -- 10+ combo: 1.1x
    {25, 1.2},   -- 25+ combo: 1.2x
    {50, 1.3},   -- 50+ combo: 1.3x
    {75, 1.4},   -- 75+ combo: 1.4x
    {100, 1.5},  -- 100+ combo: 1.5x
    {200, 1.6},  -- 200+ combo: 1.6x
    {300, 1.7},  -- 300+ combo: 1.7x
    {500, 1.8},  -- 500+ combo: 1.8x
    {1000, 2.0}  -- 1000+ combo: 2.0x
}

-- Pesos para accuracy
ScoringSystem.accuracyWeights = {
    perfect = 1.0,
    good = 0.5,
    bad = 0.2,
    miss = 0
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
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
<<<<<<< HEAD
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
=======
    self.multiplier = 1.0
    self.totalNotes = 0
    self.hitNotes = 0
    self.judgments = {
        perfect = 0,
        good = 0,
        bad = 0,
        miss = 0
    }
end

-- Calcular puntuación para un juicio
function ScoringSystem:addJudgment(judgment)
    local baseScore = self.judgmentValues[judgment] or 0
    
    -- Actualizar multiplicador por combo
    self:updateMultiplier()
    
    -- Calcular puntuación
    local addedScore = math.floor(baseScore * self.multiplier)
    self.score = self.score + addedScore
    
    -- Actualizar contadores
    if judgment ~= "miss" then
        self.combo = self.combo + 1
        self.hitNotes = self.hitNotes + 1
        
        if self.combo > self.maxCombo then
            self.maxCombo = self.combo
        end
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    else
        self.combo = 0
    end
    
    self.judgments[judgment] = self.judgments[judgment] + 1
    
<<<<<<< HEAD
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
=======
    return addedScore
end

-- Actualizar multiplicador por combo
function ScoringSystem:updateMultiplier()
    self.multiplier = 1.0
    
    for _, pair in ipairs(self.comboMultipliers) do
        local requiredCombo = pair[1]
        local mult = pair[2]
        
        if self.combo >= requiredCombo then
            self.multiplier = mult
        end
    end
end

-- Calcular accuracy
function ScoringSystem:calculateAccuracy()
    local totalPossible = self.totalNotes * self.judgmentValues.perfect
    if totalPossible == 0 then
        return 0
    end
    
    local totalHit = 0
    for judgment, count in pairs(self.judgments) do
        totalHit = totalHit + (count * self.judgmentValues[judgment])
    end
    
    return (totalHit / totalPossible) * 100
end

-- Calcular grade
function ScoringSystem:calculateGrade()
    local accuracy = self:calculateAccuracy()
    
    if accuracy >= 95 then
        return "A"
    elseif accuracy >= 85 then
        return "B"
    elseif accuracy >= 75 then
        return "C"
    elseif accuracy >= 65 then
        return "D"
    else
        return "E"
    end
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

-- Obtener información de puntuación
function ScoringSystem:getScoreInfo()
    return {
        score = self.score,
        combo = self.combo,
        maxCombo = self.maxCombo,
<<<<<<< HEAD
=======
        multiplier = self.multiplier,
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        accuracy = self:calculateAccuracy(),
        grade = self:calculateGrade(),
        judgments = self.judgments,
        totalNotes = self.totalNotes,
<<<<<<< HEAD
        hitNotes = self.hitNotes,
        meanDeviation = self.meanDeviation,
        absMeanDeviation = self.absMeanDeviation
    }
end

-- Formatear MS offset
function ScoringSystem:formatMS(ms)
    local sign = ms >= 0 and "+" or ""
    return string.format("%s%.2fms", sign, ms)
=======
        hitNotes = self.hitNotes
    }
end

-- Calcular puntuación máxima teórica
function ScoringSystem:getMaxPossibleScore()
    return self.totalNotes * self.judgmentValues.perfect * 2.0
end

-- Calcular puntuación basada en mods
function ScoringSystem:applyModScore(mod)
    local modMultipliers = {
        ["easy"] = 0.5,
        ["normal"] = 1.0,
        ["hard"] = 1.0,
        ["insane"] = 1.0,
        ["hd"] = 1.0,
        ["hdfl"] = 1.0,
        ["dt"] = 1.0,
        ["ht"] = 0.5,
        ["nc"] = 1.0,
        ["fl"] = 1.0,
        ["at"] = 1.0,
        ["ez"] = 0.5
    }
    
    return modMultipliers[mod] or 1.0
end

-- Formatear puntuación
function ScoringSystem:formatScore(score)
    return string.format("%08d", score)
end

-- Formatear accuracy
function ScoringSystem:formatAccuracy(accuracy)
    return string.format("%.2f%%", accuracy)
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

return ScoringSystem