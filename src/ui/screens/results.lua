--[[
    RITMINITY - Results Screen
    Pantalla de resultados
]]

local StateManager = require("src.core.state")

local Results = {}
Results.__index = Results

-- Datos de resultado
Results.scoreData = nil

function Results:init()
end

function Results:enter(params)
    self.scoreData = params or {
        score = 1234567,
        maxCombo = 500,
        accuracy = 95.5,
        grade = "AA",
        perfect = 800,
        good = 20,
        bad = 5,
        miss = 10,
        meanDeviation = 0,
        absMeanDeviation = 0
    }
    
    -- Registrar en el perfil global
    local ProfileManager = require("src.managers.profile_manager")
    ProfileManager:addPlay({
        songTitle = self.scoreData.songTitle or "Unknown",
        accuracy = self.scoreData.accuracy,
        grade = self.scoreData.grade,
        difficultyRating = self.scoreData.difficultyRating or 5
    })
end

function Results:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(40))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Results", 0, 80, 1280, "center")
    
    -- Grade
    local gradeColor = self:getGradeColor(self.scoreData.grade)
    love.graphics.setFont(love.graphics.newFont(120))
    love.graphics.setColor(gradeColor[1], gradeColor[2], gradeColor[3], 1)
    love.graphics.printf(self.scoreData.grade, 0, 150, 1280, "center")
    
    -- Stats
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("Accuracy: %.2f%%", self.scoreData.accuracy), 0, 320, 1280, "center")
    
    if self.scoreData.meanDeviation then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf(string.format("Mean Deviation: %+.2fms | Abs Mean: %.2fms", 
            self.scoreData.meanDeviation, self.scoreData.absMeanDeviation), 0, 350, 1280, "center")
    end
    
    -- Judgments Table
    local juds = self.scoreData.judgments or {}
    local stats = {
        {"Marvelous", juds.marvelous or 0},
        {"Perfect", juds.perfect or 0},
        {"Great", juds.great or 0},
        {"Good", juds.good or 0},
        {"Bad", juds.bad or 0},
        {"Miss", juds.miss or 0}
    }
    
    love.graphics.setFont(love.graphics.newFont(20))
    for i, stat in ipairs(stats) do
        local y = 400 + (i - 1) * 30
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf(stat[1], 440, y, 0, "right")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(stat[2], 460, y, 0, "left")
    end
    
    -- Mensaje
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Press Enter to continue", 0, 650, 1280, "center")
end

function Results:getGradeColor(grade)
    if grade:find("AAAA") then return {1, 1, 1}
    elseif grade:find("AAA") then return {1, 0.8, 0}
    elseif grade:find("AA") then return {0.2, 1, 0.2}
    elseif grade:find("A") then return {0.2, 0.8, 1}
    elseif grade == "FAILED" then return {1, 0, 0}
    else return {0.5, 0.5, 0.5}
    end
end

function Results:onEscape()
    StateManager:change("mainmenu")
end

function Results:handleInput(key)
    if key == "return" or key == "enter" or key == "kpenter" or key == "space" then
        StateManager:change(self.scoreData.from or "songselect")
    elseif key == "escape" then
        self:onEscape()
    end
end

return Results