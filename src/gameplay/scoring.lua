--[[
    RITMINITY - Scoring System
    Sistema completo de puntuación y ranking
]]

local ScoringSystem = {}
ScoringSystem.__index = ScoringSystem

-- Puntuación por juicio
ScoringSystem.judgmentValues = {
    perfect = 300,
    great = 200,
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
    great = 0.8,
    good = 0.5,
    bad = 0.2,
    miss = 0
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
    self.multiplier = 1.0
    self.totalNotes = 0
    self.hitNotes = 0
    self.judgments = {
        perfect = 0,
        great = 0,
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
    else
        self.combo = 0
    end
    
    self.judgments[judgment] = self.judgments[judgment] + 1
    
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
    
    if accuracy >= 98 then
        return "SS"
    elseif accuracy >= 95 then
        return "S"
    elseif accuracy >= 90 then
        return "A"
    elseif accuracy >= 85 then
        return "B"
    elseif accuracy >= 80 then
        return "C"
    elseif accuracy >= 70 then
        return "D"
    else
        return "F"
    end
end

-- Obtener información de puntuación
function ScoringSystem:getScoreInfo()
    return {
        score = self.score,
        combo = self.combo,
        maxCombo = self.maxCombo,
        multiplier = self.multiplier,
        accuracy = self:calculateAccuracy(),
        grade = self:calculateGrade(),
        judgments = self.judgments,
        totalNotes = self.totalNotes,
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
end

return ScoringSystem