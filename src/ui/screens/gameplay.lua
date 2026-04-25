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
<<<<<<< HEAD
    -- Efectos AAA
    self.columnGlow = {}
    self.particles = {}
    self.receptorScales = {}
    
    for i = 1, 8 do -- Soporte hasta 8K
        self.columnGlow[i] = 0
        self.receptorScales[i] = 1.0
        
        -- Sistema de partículas por columna
        local ps = love.graphics.newParticleSystem(self:createParticleTexture(), 100)
        ps:setParticleLifetime(0.2, 0.4)
        ps:setLinearAcceleration(-200, -200, 200, 200)
        ps:setColors(1, 1, 1, 1, 1, 1, 1, 0)
        ps:setSizes(1, 0.5)
        ps:setSpread(math.pi * 2)
        ps:setSpeed(100, 300)
        self.particles[i] = ps
    end
    
    self.screenShake = 0
    self.backgroundFlash = 0
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    -- Inicializar engine
    self.engine = require("src.gameplay.engine.engine"):new()
    -- Inicializar sistema de replay
    self.replay = require("src.replay.system"):new()
end

<<<<<<< HEAD
function Gameplay:createParticleTexture()
    local canvas = love.graphics.newCanvas(16, 16)
    love.graphics.setCanvas(canvas)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", 8, 8, 8)
    love.graphics.setCanvas()
    return canvas
end

Gameplay.source = "songselect"

function Gameplay:enter(params)
    self.song = params and params.song or {title = "Test Song", bpm = 120}
    self.chart = params and params.chart or self:generateTestChart()
    self.source = params and params.from or "songselect"
    self.gameEnded = false
    
    -- Detectar conteo de columnas (Prioridad: Params > Chart > Default 4)
    self.columnCount = params and params.columnCount or (self.chart and self.chart.columnCount) or 4
    self.columnKeys = self:getKeysForColumns(self.columnCount)
    
    -- Manejar audio de la canción
    local audioFile = self.chart.audioFile or (self.chart.metadata and self.chart.metadata.audioFile) or (self.song and self.song.audioFile)
    
    if audioFile then
        local music = AudioManager:loadMusic(audioFile)
        AudioManager:playMusic(music)
        
        -- Inicializar SampleManager para hitsounds dinámicos
        local SampleManager = require("src.managers.sample_manager")
        SampleManager:setSongPath(audioFile)
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    else
        AudioManager:stopMusic()
    end
    
<<<<<<< HEAD
    -- Configurar UI layout dinámico
    local maxTotalWidth = 1000
    local columnWidth = math.min(120, maxTotalWidth / self.columnCount)
    
    self.uiConfig = {
        columnWidth = columnWidth,
        hitPosition = 580,
        totalWidth = self.columnCount * columnWidth,
        hitEffects = {}
    }
    self.uiConfig.startX = (1280 - self.uiConfig.totalWidth) / 2

    -- Inicialización única y limpia del motor
    self.engine:initialize({
        columnCount = self.columnCount,
        scrollSpeed = RITMINITY.settings.scrollSpeed or 600,
        globalOffset = RITMINITY.settings.globalOffset or 0
    })
    self.engine:loadChart(self.chart)
    
    -- Emergency Fallback: Si el chart está vacío tras cargar, generar uno de prueba
    if #self.engine.notes == 0 then
        print("[Gameplay] WARNING: Chart was empty! Falling back to generated test chart.")
        self.chart = self:generateTestChart()
        self.engine:loadChart(self.chart)
    end
    
    self.engine:start()
    
    self.startTime = love.timer.getTime()
    self.paused = false
    self.gameEnded = false
    
    -- Callbacks del engine
    self.engine.callbacks.onNoteHit = function(note, judgment, msOffset)
        self:onNoteHit(note, judgment, msOffset)
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
    
    self.engine.callbacks.onNoteMiss = function(note)
        self:onNoteMiss(note)
    end
    
    self.engine.callbacks.onComboBreak = function(maxCombo)
        self:onComboBreak(maxCombo)
    end
<<<<<<< HEAD
end

function Gameplay:getKeysForColumns(count)
    if count == 4 then
        return {"d", "f", "j", "k"}
    elseif count == 7 then
        return {"s", "d", "f", "space", "j", "k", "l"}
    elseif count == 6 then
        return {"s", "d", "f", "j", "k", "l"}
    else
        -- Fallback genérico para otros conteos
        local keys = {"d", "f", "j", "k", "l", "s", "a"}
        local result = {}
        for i = 1, count do table.insert(result, keys[i] or "space") end
        return result
=======
    
    self.engine.callbacks.onScoreUpdate = function(score, combo)
        self.scoreDisplay = string.format("%08d", score)
        self.comboDisplay.value = combo
        self.comboDisplay.scale = 1.2
    end
    
    self.engine.callbacks.onGradeChange = function(grade)
        self.judgmentDisplay.text = grade
        self.judgmentDisplay.alpha = 1
        self.judgmentDisplay.scale = 1.2
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

function Gameplay:exit()
    AudioManager:stopMusic()
    self.engine:reset()
end

<<<<<<< HEAD
-- Generar chart de prueba (con Hold Notes)
function Gameplay:generateTestChart()
    local chart = {
        metadata = {
            title = "Test Level",
            artist = "RITMINITY",
            bpm = self.song.bpm or 120
        },
        notes = {}
    }
    
    local bpm = chart.metadata.bpm
    local beatDuration = 60 / bpm
    
    -- Generar secuencia de notas de prueba empezando pronto (1.0s)
    for i = 1, 80 do
        local time = 1.0 + (i - 1) * (beatDuration * 1)
        local column = math.random(1, self.columnCount)
        
        -- Intercalar Hold Notes cada 5 notas
        if i % 5 == 0 then
            table.insert(chart.notes, {
                time = time,
                column = column,
                type = "hold",
                holdTime = beatDuration * 2
            })
        else
            table.insert(chart.notes, {
                time = time,
                column = column,
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
                type = "tap",
                holdTime = 0
            })
        end
    end
    
    return chart
end

function Gameplay:update(dt)
<<<<<<< HEAD
    if self.paused or self.gameEnded then
        return
    end
    
    -- Obtener tiempo de audio con fallback a tiempo de sistema para evitar congelamientos
=======
    if self.paused then
        return
    end
    
    -- Obtener tiempo de audio exacto (Audio-driven time)
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    local audioTime = nil
    if AudioManager:isMusicPlaying() then
        audioTime = AudioManager:getAudioTime()
    end
    
<<<<<<< HEAD
    -- Si el tiempo de audio está estancado en 0, usamos dt para forzar el avance
    if not audioTime or audioTime <= 0 then
        audioTime = nil -- Forzará al engine a usar dt interno
    end
    
    -- Senior Debug: Per-frame timing (Consola)
    -- print(string.format("T: %.3f | A: %s | Notes: %d", self.engine.state.currentTime, tostring(audioTime), #self.engine.notes))
    
    -- Senior Debug: Timing (Consola)
    if self.engine.state.playing then
        -- print("SongTime:", self.engine.state.currentTime)
    end
    
    -- Actualizar engine
    -- Actualizar efectos AAA
    for i = 1, #self.particles do
        self.particles[i]:update(dt)
        
        -- Decaimiento de luces
        local isDown = self.engine.columns[i] and self.engine.columns[i].keyPressed
        if isDown then
            self.columnGlow[i] = 1.0
        else
            self.columnGlow[i] = math.max(0, self.columnGlow[i] - dt * 5)
        end
        
        -- Decaimiento de escala de receptores
        self.receptorScales[i] = self.receptorScales[i] + (1.0 - self.receptorScales[i]) * 15 * dt
    end
    
    self.screenShake = math.max(0, self.screenShake - dt * 20)
    self.backgroundFlash = math.max(0, self.backgroundFlash - dt * 5)
    
    self.engine:update(dt, audioTime)
    
    -- Verificar fin del juego
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    local engineState = self.engine:getState()
    if engineState.finished and not self.gameEnded then
        self.gameEnded = true
        self:onGameEnd()
    end
    
<<<<<<< HEAD
=======
    -- Actualizar displays
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
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
    
<<<<<<< HEAD
    -- Partículas de Hit
    for i = #self.uiConfig.hitEffects, 1, -1 do
        local fx = self.uiConfig.hitEffects[i]
        fx.life = fx.life - dt
        fx.size = fx.size + dt * 200
        if fx.life <= 0 then
            table.remove(self.uiConfig.hitEffects, i)
        end
    end
end

function Gameplay:draw()
    -- Aplicar Screen Shake (AAA)
    local shakeX = 0
    local shakeY = 0
    if self.screenShake > 0 then
        shakeX = math.random(-self.screenShake, self.screenShake)
        shakeY = math.random(-self.screenShake, self.screenShake)
    end
    
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    
    -- Fondo Profesional con Gradiente
    love.graphics.clear(0.01, 0.01, 0.03)
    
    -- Fondo con Flash (AAA)
    if self.backgroundFlash > 0 then
        love.graphics.setColor(1, 1, 1, self.backgroundFlash)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
    end
    
    -- Líneas de profundidad (Aesthetic)
    love.graphics.setColor(0.3, 0.6, 1, 0.05)
    for i = 1, 10 do
        local y = 720 - (i * 72)
        love.graphics.line(0, y, 1280, y)
    end
    
    self:drawColumns()
    self:drawReceptors()
    self:drawNotes()
    
    -- Partículas (AAA)
    local cfg = self.uiConfig
    for i = 1, self.columnCount do
        local x = cfg.startX + (i - 1) * cfg.columnWidth + cfg.columnWidth / 2
        love.graphics.draw(self.particles[i], x, cfg.hitPosition)
    end
    
    self:drawUI()
    
    -- Overlay de Pausa (AAA)
    if self.paused then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        
        love.graphics.setFont(love.graphics.newFont(64))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("PAUSA", 0, 300, 1280, "center")
        
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf("Presiona ESPACIO para continuar", 0, 380, 1280, "center")
        love.graphics.printf("Presiona ESC para salir", 0, 420, 1280, "center")
    end
    
    love.graphics.pop()
end

function Gameplay:drawHitEffects()
    for _, fx in ipairs(self.uiConfig.hitEffects) do
        local alpha = fx.life / 0.15
        love.graphics.setColor(1, 1, 1, alpha * 0.5)
        love.graphics.circle("line", fx.x, fx.y, fx.size)
        
        love.graphics.setColor(0.3, 0.8, 1, alpha * 0.2)
        love.graphics.circle("fill", fx.x, fx.y, fx.size * 0.7)
    end
end

function Gameplay:drawColumns()
    local cfg = self.uiConfig
    local skin = require("src.managers.skin_manager")
    
    -- Fondo de la pista (Track)
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", cfg.startX, 0, cfg.totalWidth, 720)
    
    -- Líneas laterales de la pista
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.setLineWidth(2)
    love.graphics.line(cfg.startX, 0, cfg.startX, 720)
    love.graphics.line(cfg.startX + cfg.totalWidth, 0, cfg.startX + cfg.totalWidth, 720)
    
    for i = 1, self.columnCount do
        local x = cfg.startX + (i - 1) * cfg.columnWidth
        local colColor = skin:getNoteColor(i, self.columnCount)
        
        -- Línea divisoria suave
        if i < self.columnCount then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.3)
            love.graphics.setLineWidth(1)
            love.graphics.line(x + cfg.columnWidth, 0, x + cfg.columnWidth, 720)
        end
        
        -- Pequeño acento de color en la parte superior (Opcional)
        love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.1)
        love.graphics.rectangle("fill", x, 0, cfg.columnWidth, 10)
    end
    
    -- Línea de hit (Professional Style)
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("fill", cfg.startX, cfg.hitPosition - 2, cfg.totalWidth, 4)
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(1)
    love.graphics.line(cfg.startX, cfg.hitPosition, cfg.startX + cfg.totalWidth, cfg.hitPosition)
end

function Gameplay:drawNotes()
    local state = self.engine:getState()
    local cfg = self.uiConfig
    local scrollSpeed = self.engine.config.scrollSpeed or 600
    local skin = require("src.managers.skin_manager")
    
    -- Senior AAA Diagnostic: Borde de área de juego
    love.graphics.setColor(1, 0, 1, 0.3)
    love.graphics.rectangle("line", cfg.startX, 0, cfg.totalWidth, 720)
    
    -- Si no hay notas cargadas, mostrar aviso crítico
    if #self.engine.notes == 0 then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.printf("PIPELINE ERROR: ENGINE HAS 0 NOTES", 0, 300, 1280, "center")
    end

    -- Anticipación de visibilidad (5000ms = 5s)
    local visibleNotes = self.engine:getVisibleNotes(state.currentTime, 5000.0)
    
    -- Senior Debug Visual & Consola (Muestreo)
    if #visibleNotes > 0 and math.random() < 0.01 then
        print(string.format("Draw: Time=%.3f, y=%.1f", visibleNotes[1].time, cfg.hitPosition - (visibleNotes[1].time - state.currentTime) * scrollSpeed))
    end
    
    -- Senior Debug Visual
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 0, 0, 1)
    if #visibleNotes == 0 and #self.engine.notes > 0 then
        love.graphics.print("DEBUG: 0 visible notes but " .. #self.engine.notes .. " in engine!", 10, 100)
        love.graphics.print("CurrentTime: " .. string.format("%.3f", state.currentTime), 10, 115)
        love.graphics.print("FirstNote: " .. string.format("%.3f", self.engine.notes[1].time), 10, 130)
    end
    
    -- 1. Capa de Cuerpo de Holds (Debajo de las notas)
    love.graphics.setBlendMode("alpha")
    for _, note in ipairs(visibleNotes) do
        if note.type == "hold" then
            local x = cfg.startX + (note.column - 1) * cfg.columnWidth + cfg.columnWidth / 2
            local timeDiff = note.time - state.currentTime
            local y = cfg.hitPosition - (timeDiff * (scrollSpeed / 1000))
            local endY = cfg.hitPosition - (((note.time + note.holdTime) - state.currentTime) * (scrollSpeed / 1000))
            local colColor = skin:getNoteColor(note.column, self.columnCount)
            
            -- Si el hold está activo, el inicio es la línea de hit
            local bodyStartY = note.active and cfg.hitPosition or y
            
            if endY < 720 and bodyStartY > 0 then
                -- Efecto de "Láser" (AAA)
                love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.4)
                love.graphics.rectangle("fill", x - cfg.columnWidth/2 + 8, endY, cfg.columnWidth - 16, bodyStartY - endY)
                
                -- Brillo central del láser
                love.graphics.setColor(1, 1, 1, 0.3)
                love.graphics.rectangle("fill", x - 4, endY, 8, bodyStartY - endY)
                
                -- Bordes brillantes
                love.graphics.setBlendMode("add")
                love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.6)
                love.graphics.rectangle("line", x - cfg.columnWidth/2 + 8, endY, cfg.columnWidth - 16, bodyStartY - endY)
                love.graphics.setBlendMode("alpha")
            end
        end
    end
    
    -- 2. Capa de Notas (Tap / Heads)
    for _, note in ipairs(visibleNotes) do
        local x = cfg.startX + (note.column - 1) * cfg.columnWidth + cfg.columnWidth / 2
        local timeDiff = note.time - state.currentTime
        local y = cfg.hitPosition - (timeDiff * (scrollSpeed / 1000))
        
        -- Ocultar notas que ya pasaron la línea de hit (si no son holds activos)
        if y < 720 and (not note.processed or (note.type == "hold" and note.active)) then
            local colColor = skin:getNoteColor(note.column, self.columnCount)
            
            -- Dibujar nota con textura o rectángulo premium
            local texture = (note.type == "hold") and skin.textures.note_hold or skin.textures.note_tap
            
            if texture then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(texture, x, y, 0, cfg.columnWidth/texture:getWidth(), 24/texture:getHeight(), texture:getWidth()/2, texture:getHeight()/2)
            else
                -- Rectángulo Profesional (Glassmorphism look)
                -- Sombra/Glow exterior
                love.graphics.setBlendMode("add")
                love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.4)
                love.graphics.rectangle("fill", x - cfg.columnWidth/2 + 2, y - 14, cfg.columnWidth - 4, 28, 6, 6)
                
                -- Cuerpo Principal
                love.graphics.setBlendMode("alpha")
                love.graphics.setColor(colColor[1], colColor[2], colColor[3], 1)
                love.graphics.rectangle("fill", x - cfg.columnWidth/2 + 4, y - 12, cfg.columnWidth - 8, 24, 4, 4)
                
                -- Brillo Superior (Highlight)
                love.graphics.setColor(1, 1, 1, 0.4)
                love.graphics.rectangle("fill", x - cfg.columnWidth/2 + 4, y - 12, cfg.columnWidth - 8, 8, 4, 4)
            end
        end
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

function Gameplay:drawReceptors()
<<<<<<< HEAD
    local cfg = self.uiConfig
    local skin = require("src.managers.skin_manager")
    
    for i = 1, self.columnCount do
        local x = cfg.startX + (i - 1) * cfg.columnWidth + cfg.columnWidth / 2
        local keyPressed = self.engine.columns[i].keyPressed
        local colColor = skin:getNoteColor(i, self.columnCount)
        local scale = self.receptorScales[i] or 1.0
        
        -- Iluminación de columna (Professional Glow) con decaimiento
        local glow = self.columnGlow[i] or 0
        if glow > 0 then
            love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.15 * glow)
            love.graphics.rectangle("fill", x - cfg.columnWidth/2, 0, cfg.columnWidth, cfg.hitPosition)
            
            -- Flare en la base
            love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.3 * glow)
            love.graphics.rectangle("fill", x - cfg.columnWidth/2, cfg.hitPosition - 100, cfg.columnWidth, 100)
        end
        
        -- Receptor con Animación de Escala (AAA)
        love.graphics.push()
        love.graphics.translate(x, cfg.hitPosition)
        love.graphics.scale(scale, scale)
        love.graphics.translate(-x, -cfg.hitPosition)
        
        if keyPressed then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("fill", x - cfg.columnWidth/2 + 4, cfg.hitPosition - 15, cfg.columnWidth - 8, 30, 6, 6)
        else
            love.graphics.setColor(colColor[1], colColor[2], colColor[3], 0.4)
            love.graphics.rectangle("line", x - cfg.columnWidth/2 + 6, cfg.hitPosition - 12, cfg.columnWidth - 12, 24, 4, 4)
            
            love.graphics.setColor(0.1, 0.1, 0.2, 0.5)
            love.graphics.rectangle("fill", x - cfg.columnWidth/2 + 6, cfg.hitPosition - 12, cfg.columnWidth - 12, 24, 4, 4)
        end
        
        love.graphics.pop()
    end
end

function Gameplay:drawTimingGraph()
    local history = self.engine.scoring.history
    local duration = self.engine:getChartEndTime()
    if duration <= 0 then return end
    
    local w, h = 400, 120
    local x, y = (1280 - w) / 2, 600
    
    -- Fondo del Grafo
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    
    -- Línea Central (0ms)
    love.graphics.setColor(0, 1, 0, 0.3)
    love.graphics.line(x, y + h/2, x + w, y + h/2)
    
    -- Bordes (Windows)
    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)
    
    -- Dibujar Puntos (Hits)
    for _, hit in ipairs(history) do
        local px = x + (hit.time / duration) * w
        -- Escalar offset (-180 a 180ms)
        local py = y + h/2 + (hit.offset / 180) * (h/2)
        
        -- Color por juicio
        local color = {1, 1, 1}
        if hit.judgment == "marvelous" then color = {1, 1, 1}
        elseif hit.judgment == "perfect" then color = {1, 1, 0}
        elseif hit.judgment == "great" then color = {0, 1, 0}
        elseif hit.judgment == "good" then color = {0, 0.5, 1}
        elseif hit.judgment == "bad" then color = {0.5, 0, 1}
        elseif hit.judgment == "miss" then color = {1, 0, 0} end
        
        love.graphics.setColor(color[1], color[2], color[3], 0.8)
        love.graphics.points(px, py)
    end
    
    -- Etiquetas
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.print("EARLY", x + 5, y + 5)
    love.graphics.print("LATE", x + 5, y + h - 15)
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

function Gameplay:drawUI()
    local state = self.engine:getState()
    
<<<<<<< HEAD
    -- Debug Info
    if RITMINITY.config.debug.enabled then
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.print("Notes: " .. #self.engine.notes, 10, 50)
        love.graphics.print("Visible: " .. #self.engine:getVisibleNotes(state.currentTime, 2.0), 10, 65)
        love.graphics.print("Time: " .. string.format("%.3f", state.currentTime), 10, 80)
    end
    
    -- Timing Graph (Etterna Style)
    self:drawTimingGraph()
    
    -- Score (Mania Style 1M)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("%07d", state.score), 0, 30, 1280, "center")
    
    -- Accuracy & Grade
    love.graphics.setFont(love.graphics.newFont(24))
    local accColor = state.accuracy >= 95 and {1, 0.8, 0} or {1, 1, 1}
    love.graphics.setColor(accColor[1], accColor[2], accColor[3], 1)
    love.graphics.printf(string.format("%.2f%% [%s]", state.accuracy, state.grade), 0, 90, 1280, "center")
=======
    -- Score
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(self.scoreDisplay, 640, 30, 0, "center")
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    
    -- Combo
    if state.combo > 0 then
        local comboScale = self.comboDisplay.scale
<<<<<<< HEAD
        love.graphics.setFont(love.graphics.newFont(64 * comboScale))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(state.combo, 0, 500, 1280, "center")
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("COMBO", 0, 570, 1280, "center")
=======
        love.graphics.setFont(love.graphics.newFont(48 * comboScale))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(state.combo .. "x", 640, 550, 0, "center")
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
    
    -- Judgment
    if self.judgmentDisplay.alpha > 0 then
<<<<<<< HEAD
        local alpha = self.judgmentDisplay.alpha
        local colors = {
            MARVELOUS = {1, 1, 1},
            PERFECT = {1, 0.8, 0},
            GREAT = {0.2, 1, 0.2},
            GOOD = {0.2, 0.8, 1},
            BAD = {0.6, 0.4, 1},
            MISS = {1, 0.2, 0.2}
        }
        local color = colors[self.judgmentDisplay.text] or {1, 1, 1}
        love.graphics.setColor(color[1], color[2], color[3], alpha)
        
        love.graphics.setFont(love.graphics.newFont(40 * self.judgmentDisplay.scale))
        love.graphics.printf(self.judgmentDisplay.text, 0, 350, 1280, "center")
        
        -- MS Offset (Sombreado para legibilidad)
        if self.judgmentDisplay.text ~= "MISS" then
            love.graphics.setColor(0, 0, 0, alpha * 0.5)
            love.graphics.setFont(love.graphics.newFont(20))
            local msText = string.format("%+.2fms", state.lastMsOffset)
            love.graphics.printf(msText, 2, 412, 1280, "center")
            
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.printf(msText, 0, 410, 1280, "center")
        end
    end
    
    -- HP Bar (Bottom)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", 440, 700, 400, 10)
    love.graphics.setColor(1, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", 440, 700, 400 * (state.health / state.maxHealth), 10)
    
    -- Debug Info (Top Left)
    if true then 
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.print("Time: " .. string.format("%.3f", state.currentTime), 10, 10)
        love.graphics.print("Notes: " .. tostring(#self.engine.notes), 10, 30)
        love.graphics.print("Playing: " .. tostring(state.playing), 10, 50)
        
        -- Input Log
        love.graphics.print("Last Inputs:", 10, 80)
        for i, log in ipairs(self.inputLog or {}) do
            love.graphics.print(log, 20, 80 + i * 20)
        end
    end
end
function Gameplay:onNoteHit(note, judgment, msOffset)
    self.judgmentDisplay.text = judgment:upper()
    self.judgmentDisplay.alpha = 1.0
    self.judgmentDisplay.scale = 1.2
    
    self.comboDisplay.scale = 1.3
    
    -- Trigger AAA Effects
    local col = note.column
    if self.receptorScales[col] then
        self.receptorScales[col] = 1.3
    end
    
    -- Partículas
    if self.particles[col] then
        local skin = require("src.managers.skin_manager")
        local color = skin:getNoteColor(col, self.columnCount)
        self.particles[col]:setColors(color[1], color[2], color[3], 1, color[1], color[2], color[3], 0)
        self.particles[col]:emit(20)
    end
    
    -- Shake y Flash
    if judgment == "marvelous" then
        self.screenShake = 5
        self.backgroundFlash = 0.3
    elseif judgment == "perfect" then
        self.screenShake = 3
    end
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

function Gameplay:onNoteMiss(note)
    self.judgmentDisplay.text = "MISS"
    self.judgmentDisplay.alpha = 1
    self.judgmentDisplay.scale = 1
end

function Gameplay:onComboBreak(maxCombo)
<<<<<<< HEAD
    -- Efecto visual de combo break
end

function Gameplay:onEscape()
    if self.paused then
        -- Segundo Escape: Salir
        AudioManager:stopMusic()
        StateManager:change(self.source or "songselect")
        return
    end

    self.paused = true
    self.engine:pause()
    AudioManager:pauseMusic()
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

function Gameplay:onGameEnd()
    local engineState = self.engine:getState()
<<<<<<< HEAD
    local info = self.engine.scoring:getScoreInfo()
    
    -- Transicionar a pantalla de resultados
    StateManager:change("results", {
        songTitle = self.sourceSong and self.sourceSong.title or "Unknown",
        score = info.score,
        maxCombo = info.maxCombo,
        accuracy = info.accuracy,
        grade = engineState.dead and "FAILED" or info.grade,
        judgments = info.judgments,
        meanDeviation = info.meanDeviation,
        absMeanDeviation = info.absMeanDeviation,
        from = self.source
=======
    
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    })
end

function Gameplay:handleInput(key)
<<<<<<< HEAD
    self.inputLog = self.inputLog or {}
    table.insert(self.inputLog, 1, "Key: " .. tostring(key) .. " at " .. string.format("%.3f", self.engine.state.currentTime))
    if #self.inputLog > 5 then table.remove(self.inputLog) end

    -- Mapear teclas a columnas (Solo Press)
    for i, keyName in ipairs(self.columnKeys) do
        if key == keyName then
            -- Hitsound Inmediato (Ultra-low latency con Beatmap Sounds)
            if self.engine.state.playing and not self.engine.state.paused then
                local SampleManager = require("src.managers.sample_manager")
                
                -- Intentar pre-reproducir el hitsound de la nota más cercana
                local closest = self.engine:getClosestNote(i)
                local tp = self.engine.state.currentTimingPoint
                if closest then
                    SampleManager:playHitSound(closest.hitSound, closest.samples, tp)
                else
                    -- Fallback a hitsound genérico usando el TP actual para volumen
                    local vol = (tp and tp.volume or 100) / 100
                    if self.hitsound then
                        AudioManager:playSound(self.hitsound, vol * 0.5)
                    else
                        AudioManager:playSound("assets/sounds/hitsound.wav", vol * 0.5)
                    end
                end
            end
            
=======
    -- Mapear teclas a columnas (Solo Press)
    for i, keyName in ipairs(self.columnKeys) do
        if key == keyName then
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
            self.engine:keyPressed(i)
            return
        end
    end
<<<<<<< HEAD
    
    if key == "escape" then
        self:onEscape()
    elseif key == "space" and self.paused then
        self.paused = false
        self.engine:resume()
        AudioManager:resumeMusic()
    elseif key == "=" or key == "kp+" then
        self.engine.config.scrollSpeed = (self.engine.config.scrollSpeed or 600) + 50
    elseif key == "-" or key == "kp-" then
        self.engine.config.scrollSpeed = math.max(100, (self.engine.config.scrollSpeed or 600) - 50)
    end
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
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