--[[
    RITMINITY - Profile Screen
    Visualización de estadísticas globales y rango competitivo
]]

local StateManager = require("src.core.state")
local ProfileManager = require("src.managers.profile_manager")

local Profile = {}
Profile.__index = Profile

function Profile:init()
    self.font = love.graphics.newFont(24)
    self.bigFont = love.graphics.newFont(48)
end

function Profile:enter(params)
end

function Profile:draw()
    local data = ProfileManager.data
    
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(self.bigFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("PERFIL DE JUGADOR", 0, 50, 1280, "center")
    
    -- Skill Rating (Grandioso)
    love.graphics.setColor(0.3, 0.6, 1, 1)
    love.graphics.printf(string.format("%.2f SR", data.skillRating), 0, 120, 1280, "center")
    
    -- Stats Generales
    local stats = {
        { "Playtime", string.format("%dh %dm", math.floor(data.playtime / 3600), math.floor((data.playtime % 3600) / 60)) },
        { "Total Plays", tostring(data.totalPlays) },
        { "Average Acc", string.format("%.2f%%", data.averageAccuracy) },
        { "Clears / Fails", string.format("%d / %d", data.clearCount, data.failCount) }
    }
    
    love.graphics.setFont(self.font)
    for i, stat in ipairs(stats) do
        local y = 250 + (i - 1) * 40
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf(stat[1], 400, y, 200, "right")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(stat[2], 620, y, 200, "left")
    end
    
    -- Top Scores
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf("TOP SCORES", 0, 450, 1280, "center")
    
    love.graphics.setFont(love.graphics.newFont(16))
    for i = 1, math.min(10, #data.topScores) do
        local score = data.topScores[i]
        local y = 490 + (i - 1) * 22
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf(string.format("#%d  %s", i, score.songTitle), 400, y, 400, "left")
        love.graphics.setColor(0.3, 0.8, 1, 1)
        love.graphics.printf(string.format("%.2f%% (%.2f SR)", score.accuracy, score.sr), 680, y, 200, "right")
    end
    
    -- Instrucciones
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Presiona ESC para volver", 0, 680, 1280, "center")
end

function Profile:handleInput(key)
    if key == "escape" then
        StateManager:change("mainmenu")
    end
end

return Profile
