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
    self.scoreData = params and params.scoreData or {
        score = 1234567,
        maxCombo = 500,
        accuracy = 95.5,
        grade = "S",
        perfect = 800,
        great = 100,
        good = 20,
        bad = 5,
        miss = 10
    }
end

function Results:exit()
end

function Results:update(dt)
end

function Results:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(40))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Results", 640, 80, 0, "center")
    
    -- Grade
    local gradeColor = self:getGradeColor(self.scoreData.grade)
    love.graphics.setFont(love.graphics.newFont(120))
    love.graphics.setColor(gradeColor[1], gradeColor[2], gradeColor[3], 1)
    love.graphics.printf(self.scoreData.grade, 640, 150, 0, "center")
    
    -- Score
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("%d", self.scoreData.score), 640, 280, 0, "center")
    
    -- Stats
    local statsY = 380
    local stats = {
        {"Max Combo", self.scoreData.maxCombo .. "x"},
        {"Accuracy", string.format("%.2f%%", self.scoreData.accuracy)},
        {"Perfect", self.scoreData.perfect},
        {"Great", self.scoreData.great},
        {"Good", self.scoreData.good},
        {"Bad", self.scoreData.bad},
        {"Miss", self.scoreData.miss}
    }
    
    love.graphics.setFont(love.graphics.newFont(20))
    
    for i, stat in ipairs(stats) do
        local y = statsY + (i - 1) * 35
        
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf(stat[1], 440, y, 0, "right")
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(stat[2], 460, y, 0, "left")
    end
    
    -- Mensaje
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Press Enter to continue", 640, 650, 0, "center")
end

function Results:getGradeColor(grade)
    if grade == "SS" then
        return {1, 0.8, 0, 1}
    elseif grade == "S" then
        return {1, 0.5, 0, 1}
    elseif grade == "A" then
        return {0.2, 1, 0.2, 1}
    elseif grade == "B" then
        return {0.2, 0.8, 1, 1}
    elseif grade == "C" then
        return {0.6, 0.6, 1, 1}
    else
        return {0.5, 0.5, 0.5, 1}
    end
end

function Results:onEscape()
    StateManager:change("mainmenu")
end

function Results:handleInput(key)
    if key == "return" or key == "enter" then
        StateManager:change("songselect")
    end
end

return Results