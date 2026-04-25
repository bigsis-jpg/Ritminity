--[[
    RITMINITY - Gameplay Screen
    Pantalla principal de gameplay
]]

local Gameplay = {}
Gameplay.__index = Gameplay

-- Motor de gameplay
Gameplay.engine = nil

-- Sistema de replay
Gameplay.replay = nil

-- Managers
local AudioManager = require("src.managers.audio_manager")
local InputManager = require("src.managers.input_manager")
local StateManager = require("src.core.state")

-- Estado
Gameplay.song = nil
Gameplay.chart = nil
Gameplay.startTime = 0
Gameplay.paused = false
Gameplay.gameEnded = false

-- UI
Gameplay.judgmentDisplay = {
    text = "",
    alpha = 0,
    scale = 1
}
Gameplay.comboDisplay = {
    value = 0,
    scale = 1
}
Gameplay.scoreDisplay = "00000000"

-- Columnas
Gameplay.columnCount = 4
Gameplay.columnKeys = {"d", "f", "j", "k"}

function Gameplay:init()
    -- Inicializar engine
    self.engine = require("src.gameplay.engine.engine"):new()
    -- Inicializar sistema de replay
    self.replay = require("src.replay.system"):new()
end

function Gameplay:enter(params)
    self.song = params and params.song or {title = "Test Song", bpm = 120}
    self.chart = params and params.chart or self:generateTestChart()
    
    -- Configurar engine
    self.engine:initialize({
        columnCount = self.columnCount,
        noteSpeed = 1.0,
        scrollSpeed = 600,
        judgeWindow = {
            perfect = 20,
            great = 40,
            good = 60,
            miss = 80
        }
    })
    
    -- Cargar chart
    self.engine:loadChart(self.chart)
    
    -- Manejar audio de la canción
    if self.chart.audioFile then
        local music = AudioManager:loadMusic(self.chart.audioFile)
        AudioManager:playMusic(music)
    else
        AudioManager:stopMusic()
    end
    
    -- Iniciar juego
    self.engine:start()
    self.startTime = love.timer.getTime()
    self.paused = false
    
    -- Iniciar grabación de replay
    self.replay:startRecording(
        self.chart.hash or "test_chart", 
        "Player", 
        ""
    )
    
    -- Callbacks del engine
    self.engine.callbacks.onNoteHit = function(note, judgment)
        self:onNoteHit(note, judgment)
    end
    
    self.engine.callbacks.onNoteMiss = function(note)
        self:onNoteMiss(note)
    end
    
    self.engine.callbacks.onComboBreak = function(maxCombo)
        self:onComboBreak(maxCombo)
    end
    
    self.engine.callbacks.onScoreUpdate = function(score, combo)
        self.scoreDisplay = string.format("%08d", score)
        self.comboDisplay.value = combo
        self.comboDisplay.scale = 1.2
    end
    
    self.engine.callbacks.onGradeChange = function(grade)
        self.judgmentDisplay.text = grade
        self.judgmentDisplay.alpha = 1
        self.judgmentDisplay.scale = 1.2
    end
end

function Gameplay:exit()
    AudioManager:stopMusic()
    self.engine:reset()
end

-- Generar chart de prueba
function Gameplay:generateTestChart()
    local chart = {
        notes = {}
    }
    
    local bpm = self.song.bpm or 120
    local beatDuration = 60 / bpm
    
    -- Generar notas por 60 segundos
    for t = 2, 60, beatDuration do
        local column = math.random(1, self.columnCount)
        table.insert(chart.notes, {
            time = t,
            column = column,
            type = "tap",
            holdTime = 0
        })
        
        -- Ocasionalmente agregar doble
        if math.random() < 0.2 then
            local col2 = (column % self.columnCount) + 1
            table.insert(chart.notes, {
                time = t,
                column = col2,
                type = "tap",
                holdTime = 0
            })
        end
    end
    
    return chart
end

function Gameplay:update(dt)
    if self.paused then
        return
    end
    
    -- Obtener tiempo de audio exacto (Audio-driven time)
    local audioTime = nil
    if AudioManager:isMusicPlaying() then
        audioTime = AudioManager:getAudioTime()
    end
    
    -- Actualizar engine con sincronización de audio
    self.engine:update(dt, audioTime)
    
    -- Actualizar replay
    if self.replay:isRecording() then
        local state = self.engine:getState()
        local keys = {}
        
        -- Obtener teclas presionadas
        for i, key in ipairs(self.columnKeys) do
            if InputManager:isDown(key) then
                keys[i] = true
            end
        end
        
        -- Agregar frame al replay
        self.replay:addFrame(
            state.currentTime,
            keys,
            InputManager:getMousePosition()
        )
    end
    
    -- Verificar si el juego terminó
    local engineState = self.engine:getState()
    if engineState.finished and not self.gameEnded then
        self.gameEnded = true
        self:onGameEnd()
    end
    
    -- Actualizar displays
    self:updateUI(dt)
end

function Gameplay:updateUI(dt)
    -- Judgment fade
    if self.judgmentDisplay.alpha > 0 then
        self.judgmentDisplay.alpha = self.judgmentDisplay.alpha - dt * 2
        self.judgmentDisplay.scale = self.judgmentDisplay.scale + dt * 2
    end
    
    -- Combo pulse
    if self.comboDisplay.scale > 1 then
        self.comboDisplay.scale = self.comboDisplay.scale - dt * 3
    end
    
    -- Score display
    local state = self.engine:getState()
    self.scoreDisplay = string.format("%08d", state.score)
end

function Gameplay:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Columnas
    self:drawColumns()
    
    -- Notas
    self:drawNotes()
    
    -- Receptores
    self:drawReceptors()
    
    -- UI
    self:drawUI()
end

function Gameplay:drawColumns()
    local columnWidth = 200
    local totalWidth = self.columnCount * columnWidth
    local startX = (1280 - totalWidth) / 2
    
    for i = 1, self.columnCount do
        local x = startX + (i - 1) * columnWidth
        
        -- Línea de columna
        love.graphics.setColor(0.15, 0.15, 0.2, 1)
        love.graphics.rectangle("fill", x, 0, columnWidth, 720)
        
        -- Línea divisoria
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(x, 0, x, 720)
    end
    
    -- Línea de hit
    love.graphics.setColor(1, 0.5, 0, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.line(startX, 650, startX + totalWidth, 650)
end

function Gameplay:drawNotes()
    if not self.engine then
        return
    end
    
    local state = self.engine:getState()
    local columnWidth = 200
    local totalWidth = self.columnCount * columnWidth
    local startX = (1280 - totalWidth) / 2
    local hitPosition = 650
    local scrollSpeed = 600
    
    -- Obtener notas visibles
    local visibleNotes = self.engine:getVisibleNotes(state.currentTime)
    
    for _, note in ipairs(visibleNotes) do
        local x = startX + (note.column - 1) * columnWidth + columnWidth / 2
        local y = hitPosition - (note.time - state.currentTime) * scrollSpeed
        
        -- Nota
        if note.hit then
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        elseif note.missed then
            love.graphics.setColor(0.5, 0.2, 0.2, 0.5)
        else
            love.graphics.setColor(0.2, 0.6, 1, 1)
        end
        
        love.graphics.rectangle("fill", x - 80, y - 15, 160, 30)
        
        -- Borde
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - 80, y - 15, 160, 30)
    end
end

function Gameplay:drawReceptors()
    local columnWidth = 200
    local totalWidth = self.columnCount * columnWidth
    local startX = (1280 - totalWidth) / 2
    local hitPosition = 650
    
    for i = 1, self.columnCount do
        local x = startX + (i - 1) * columnWidth + columnWidth / 2
        
        -- Receptor
        local keyDown = InputManager:isDown(self.columnKeys[i])
        
        if keyDown then
            love.graphics.setColor(1, 0.5, 0, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
        end
        
        love.graphics.rectangle("fill", x - 80, hitPosition - 15, 160, 30)
        
        -- Borde
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x - 80, hitPosition - 15, 160, 30)
        
        -- Etiqueta de tecla
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.columnKeys[i]:upper(), x - 10, hitPosition + 20, 0, "center")
    end
end

function Gameplay:drawUI()
    local state = self.engine:getState()
    
    -- Score
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.scoreDisplay, 640, 30, 0, "center")
    
    -- Combo
    if state.combo > 0 then
        local comboScale = self.comboDisplay.scale
        love.graphics.setFont(love.graphics.newFont(48 * comboScale))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(state.combo .. "x", 640, 550, 0, "center")
    end
    
    -- Judgment
    if self.judgmentDisplay.alpha > 0 then
        love.graphics.setFont(love.graphics.newFont(32 * self.judgmentDisplay.scale))
        local color = self:getJudgmentColor(self.judgmentDisplay.text)
        love.graphics.setColor(color[1], color[2], color[3], self.judgmentDisplay.alpha)
        love.graphics.printf(self.judgmentDisplay.text, 640, 200, 0, "center")
    end
    
    -- Accuracy
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf(string.format("%.2f%%", state.accuracy), 1100, 30, 0, "right")
    
    -- Tiempo
    local currentTime = state.currentTime
    local minutes = math.floor(currentTime / 60)
    local seconds = math.floor(currentTime % 60)
    love.graphics.printf(string.format("%d:%02d", minutes, seconds), 1100, 55, 0, "right")
    
    -- Barra de Progreso
    local endTime = self.engine:getChartEndTime()
    local progress = math.min(1, math.max(0, currentTime / endTime))
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", 440, 10, 400, 10)
    love.graphics.setColor(0.2, 0.6, 1, 1)
    love.graphics.rectangle("fill", 440, 10, 400 * progress, 10)
    
    -- Barra de Vida (Health)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("HP", 30, 30)
    
    for i = 1, state.maxHealth do
        if i <= state.health then
            love.graphics.setColor(1, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", 70 + (i - 1) * 30, 32, 20, 20)
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("fill", 70 + (i - 1) * 30, 32, 20, 20)
        end
    end
end

function Gameplay:getJudgmentColor(judgment)
    if judgment == "PERFECT" then
        return {1, 0.8, 0, 1}
    elseif judgment == "GOOD" then
        return {0.2, 1, 0.2, 1}
    elseif judgment == "BAD" then
        return {0.2, 0.6, 1, 1}
    elseif judgment == "MISS" then
        return {1, 0.3, 0.3, 1}
    else
        return {0.5, 0.5, 0.5, 1}
    end
end

function Gameplay:onNoteHit(note, judgment)
    self.judgmentDisplay.text = judgment:upper()
    self.judgmentDisplay.alpha = 1
    self.judgmentDisplay.scale = 1
    
    self.comboDisplay.scale = 1.2
end

function Gameplay:onNoteMiss(note)
    self.judgmentDisplay.text = "MISS"
    self.judgmentDisplay.alpha = 1
    self.judgmentDisplay.scale = 1
end

function Gameplay:onComboBreak(maxCombo)
    -- Por implementar: efectos de combo break
end

function Gameplay:onEscape()
    self.paused = not self.paused
    
    if self.paused then
        self.engine:pause()
        AudioManager:pauseMusic()
        -- Detener grabación de replay cuando se pausa
        if self.replay:isRecording() then
            self.replay:stopRecording()
        end
    else
        self.engine:resume()
        AudioManager:resumeMusic()
        -- Reanudar grabación de replay cuando se despausa
        if not self.replay:isRecording() then
            self.replay:startRecording(
                self.chart.hash or "test_chart", 
                "Player", 
                ""
            )
        end
    end
end

function Gameplay:onGameEnd()
    local engineState = self.engine:getState()
    
    -- Actualizar metadatos del replay con resultados finales
    self.replay:setMetadata("score", engineState.score)
    self.replay:setMetadata("maxCombo", engineState.maxCombo)
    self.replay:setMetadata("accuracy", engineState.accuracy)
    self.replay:setMetadata("grade", engineState.grade)
    self.replay:setMetadata("mods", "")  
    
    -- Detener grabación
    self.replay:stopRecording()
    
    -- Guardar replay
    local replayPath = "assets/replays/replay_" .. os.time() .. ".json"
    self.replay:save(replayPath)
    
    -- Transicionar a pantalla de resultados
    StateManager:change("results", {
        score = engineState.score,
        maxCombo = engineState.maxCombo,
        accuracy = engineState.accuracy,
        grade = engineState.dead and "FAILED" or self.engine.scoring:calculateGrade(),
        replayPath = replayPath
    })
end

function Gameplay:handleInput(key)
    -- Mapear teclas a columnas (Solo Press)
    for i, keyName in ipairs(self.columnKeys) do
        if key == keyName then
            self.engine:keyPressed(i)
            return
        end
    end
end

function Gameplay:keyreleased(key, scancode)
    -- Mapear teclas a columnas (Solo Release)
    for i, keyName in ipairs(self.columnKeys) do
        if key == keyName then
            self.engine:keyReleased(i)
            return
        end
    end
end

return Gameplay