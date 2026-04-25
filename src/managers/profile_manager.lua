--[[
    RITMINITY - Profile Manager
    Maneja la persistencia de datos del jugador y estadísticas globales
]]

local ProfileManager = {}
ProfileManager.__index = ProfileManager

function ProfileManager:new()
    local self = setmetatable({}, ProfileManager)
    self.data = {
        username = "Guest",
        playtime = 0,
        totalPlays = 0,
        totalAccuracy = 0,
        averageAccuracy = 0,
        skillRating = 0,
        clearCount = 0,
        failCount = 0,
        totalNotesHit = 0,
        topScores = {}
    }
    self.savePath = "profile.json"
    self:load()
    return self
end

function ProfileManager:load()
    if love.filesystem.getInfo(self.savePath) then
        local content = love.filesystem.read(self.savePath)
        local json = require("src.utils.json") -- Asumimos que existe o usaremos dkjson
        local success, decoded = pcall(function() return json.decode(content) end)
        if success and decoded then
            -- Combinar con valores por defecto para evitar nils en nuevas versiones
            for k, v in pairs(decoded) do
                self.data[k] = v
            end
        end
    end
end

function ProfileManager:save()
    local json = require("src.utils.json")
    local content = json.encode(self.data)
    love.filesystem.write(self.savePath, content)
end

-- Actualizar stats después de una partida
function ProfileManager:addPlay(stats)
    self.data.totalPlays = self.data.totalPlays + 1
    
    if stats.grade == "FAILED" then
        self.data.failCount = self.data.failCount + 1
    else
        self.data.clearCount = self.data.clearCount + 1
        
        -- Calcular Accuracy Promedio
        self.data.totalAccuracy = self.data.totalAccuracy + stats.accuracy
        self.data.averageAccuracy = self.data.totalAccuracy / self.data.clearCount
        
        -- Skill Rating (Aproximación Etterna-style)
        -- SR = Diff * (Acc / 100) ^ 4 * 10
        local diff = stats.difficultyRating or 5 -- Fallback
        local playSR = diff * (stats.accuracy / 100) ^ 4 * 10
        
        -- Promedio ponderado para SR Global
        self.data.skillRating = self.data.skillRating * 0.95 + playSR * 0.05
        
        -- Guardar top score
        table.insert(self.data.topScores, {
            songTitle = stats.songTitle,
            accuracy = stats.accuracy,
            sr = playSR,
            date = os.date("%Y-%m-%d")
        })
        
        -- Ordenar y truncar top 50
        table.sort(self.data.topScores, function(a, b) return a.sr > b.sr end)
        while #self.data.topScores > 50 do table.remove(self.data.topScores) end
    end
    
    self:save()
end

function ProfileManager:addPlaytime(seconds)
    self.data.playtime = self.data.playtime + seconds
    self:save()
end

return ProfileManager:new()
