--[[
    RITMINITY - Gameplay Engine
    Motor de gameplay para juegos de ritmo tipo mania
]]

local GameplayEngine = {}
GameplayEngine.__index = GameplayEngine

-- Notas del chart
GameplayEngine.notes = {}

-- Columnas del juego
GameplayEngine.columns = {}

-- Configuración
GameplayEngine.config = {
    columnCount = 4,
    noteSpeed = 1.0,
    scrollSpeed = 600,
    judgeWindow = {
        perfect = 20,
        great = 40,
        good = 60,
        miss = 80
    }
}

-- Estado del juego
GameplayEngine.state = {
    playing = false,
    paused = false,
    finished = false,
    currentTime = 0,
    songTime = 0,
    combo = 0,
    maxCombo = 0,
    score = 0,
    accuracy = 0,
    maxAccuracy = 100,
    totalNotes = 0,
    hitNotes = 0,
    missedNotes = 0,
    perfectHits = 0,
    greatHits = 0,
    goodHits = 0,
    badHits = 0,
    grade = "F"
}

-- Sistema de puntuación
GameplayEngine.scoring = nil

-- Callbacks
GameplayEngine.callbacks = {
    onNoteHit = nil,
    onNoteMiss = nil,
    onComboBreak = nil,
    onScoreUpdate = nil,
    onGradeChange = nil
}

function GameplayEngine:new()
    local self = setmetatable({}, GameplayEngine)
    -- Los valores por defecto se inicializan en initialize()
    return self
end

function GameplayEngine:initialize(config)
    self.config = config or self.config
    self.notes = {}
    self.columns = {}
    self.state = {
        playing = false,
        paused = false,
        finished = false,
        currentTime = 0,
        songTime = 0,
        combo = 0,
        maxCombo = 0,
        score = 0,
        accuracy = 0,
        maxAccuracy = 100,
        totalNotes = 0,
        hitNotes = 0,
        missedNotes = 0,
        perfectHits = 0,
        greatHits = 0,
        goodHits = 0,
        badHits = 0,
        grade = "F"
    }
    
    -- Inicializar sistema de puntuación
    self.scoring = require("src.gameplay.scoring"):new()
    
    -- Inicializar columnas
    self:initColumns()
end

-- Inicializar columnas
function GameplayEngine:initColumns()
    self.columns = {}
    for i = 1, self.config.columnCount do
        self.columns[i] = {
            index = i,
            notes = {},
            keyPressed = false,
            lastHitTime = 0,
            heldNotes = {}
        }
    end
end

-- Cargar chart
function GameplayEngine:loadChart(chartData)
    self.notes = {}
    
    if not chartData or not chartData.notes then
        return false
    end
    
    -- Procesar notas
    for _, noteData in ipairs(chartData.notes) do
        local note = {
            time = noteData.time,
            column = noteData.column,
            type = noteData.type or "tap",
            holdTime = noteData.holdTime or 0,
            hit = false,
            missed = false,
            processed = false,
            active = false -- Para Hold Notes
        }
        table.insert(self.notes, note)
    end
    
    -- Ordenar por tiempo
    table.sort(self.notes, function(a, b)
        return a.time < b.time
    end)
    
    self.state.totalNotes = #self.notes
    
    return true
end

-- Iniciar juego
function GameplayEngine:start()
    self.state.playing = true
    self.state.paused = false
    self.state.finished = false
    self.state.currentTime = 0
    self.state.songTime = 0
end

-- Pausar juego
function GameplayEngine:pause()
    self.state.paused = true
end

-- Reanudar juego
function GameplayEngine:resume()
    self.state.paused = false
end

-- Finalizar juego
function GameplayEngine:finish()
    self.state.playing = false
    self.state.finished = true
    self:calculateGrade()
end

-- Actualizar
function GameplayEngine:update(dt, audioTime)
    if not self.state.playing or self.state.paused then
        return
    end
    
    -- Si se provee tiempo de audio (Audio-driven Clock), lo usamos para mayor precisión
    if audioTime then
        self.state.currentTime = audioTime
        self.state.songTime = audioTime
    else
        -- Fallback a delta time si no hay audio
        self.state.currentTime = self.state.currentTime + dt
        self.state.songTime = self.state.songTime + dt
    end
    
    -- Procesar notas
    self:processNotes()
    
    -- Verificar fin del chart o si no hay notas
    if self.state.currentTime > self:getChartEndTime() then
        self:finish()
    end
end

-- Procesar notas
function GameplayEngine:processNotes()
    local currentTime = self.state.currentTime
    
    for i, note in ipairs(self.notes) do
        -- Nota Hold activa, verificando si se completó o se soltó prematuramente
        if note.active then
            local endTime = note.time + note.holdTime
            
            -- Si llegamos al final del hold
            if currentTime >= endTime then
                -- Si sigue presionada al final, es un perfect en la cola
                self:handleHit(note, "perfect", true)
            elseif not self.columns[note.column].keyPressed then
                -- Si se soltó antes de tiempo
                note.active = false
                note.missed = true
                note.processed = true
                self:handleMiss(note)
            end
            goto continue
        end
        
        -- Nota perdida (Tap o inicio de Hold): si pasó el tiempo de juicio máximo sin ser presionada
        if currentTime > note.time + (self.config.judgeWindow.miss / 1000) and not note.hit then
            note.missed = true
            note.processed = true
            self:handleMiss(note)
        end
        
        ::continue::
    end
end

-- Manejar presión de tecla
function GameplayEngine:keyPressed(column)
    if column < 1 or column > #self.columns then
        return
    end
    
    self.columns[column].keyPressed = true
    
    local currentTime = self.state.currentTime
    
    -- Buscar la nota más cercana en esta columna
    local closestNote = nil
    local closestDiff = math.huge
    
    for i, note in ipairs(self.notes) do
        if note.column == column and not note.processed then
            local diff = math.abs(currentTime - note.time)
            if diff < closestDiff then
                closestDiff = diff
                closestNote = note
            end
        end
    end
    
    -- Verificar si está dentro de la ventana de juicio
    if closestNote then
        local diffMs = closestDiff * 1000
        
        if diffMs <= self.config.judgeWindow.miss then
            local judgment = "bad"
            if diffMs <= self.config.judgeWindow.perfect then
                judgment = "perfect"
            elseif diffMs <= self.config.judgeWindow.great then
                judgment = "great"
            elseif diffMs <= self.config.judgeWindow.good then
                judgment = "good"
            end
            
            if closestNote.type == "hold" then
                closestNote.hit = true
                closestNote.active = true
                -- Juzgamos solo el inicio, la nota no está procesada hasta que termina
                self:handleHit(closestNote, judgment, false)
            else
                self:handleHit(closestNote, judgment, false)
            end
        end
    end
    
    -- También verificar si hay notas perdidas por presionar demasiado temprano
    -- (esto se maneja en processNotes)
end

-- Manejar liberación de tecla
function GameplayEngine:keyReleased(column)
    if column < 1 or column > #self.columns then
        return
    end
    
    self.columns[column].keyPressed = false
    
    -- El procesamiento de liberación prematura de Hold Notes
    -- se maneja en processNotes() basándose en keyPressed
end

-- Manejar nota presionada
function GameplayEngine:handleHit(note, judgment, isTail)
    if not isTail and note.type == "tap" then
        note.hit = true
        note.processed = true
    elseif isTail then
        note.processed = true
        note.active = false
    end
    
    -- Usar sistema de puntuación
    self.scoring:addJudgment(judgment)
    
    -- Actualizar estado del engine para compatibilidad
    self.state.hitNotes = self.scoring.hitNotes
    self.state.combo = self.scoring.combo
    self.state.maxCombo = self.scoring.maxCombo
    self.state.score = self.scoring.score
    self.state.accuracy = self.scoring:calculateAccuracy()
    
    -- Actualizar contadores por tipo de juicio
    if judgment == "perfect" then
        self.state.perfectHits = self.scoring.judgments.perfect
    elseif judgment == "great" then
        self.state.greatHits = self.scoring.judgments.great
    elseif judgment == "good" then
        self.state.goodHits = self.scoring.judgments.good
    elseif judgment == "bad" then
        self.state.badHits = self.scoring.judgments.bad
    end
    self.state.missedNotes = self.scoring.judgments.miss
    
    -- Callback
    if self.callbacks.onNoteHit then
        self.callbacks.onNoteHit(note, judgment)
    end
    
    if self.callbacks.onScoreUpdate then
        local scoreInfo = self.scoring:getScoreInfo()
        self.callbacks.onScoreUpdate(scoreInfo.score, scoreInfo.combo)
    end
    
    if self.callbacks.onGradeChange then
        self.callbacks.onGradeChange(self.scoring:calculateGrade())
    end
end

-- Manejar nota perdida
function GameplayEngine:handleMiss(note)
    note.missed = true
    note.processed = true
    
    -- Usar sistema de puntuación
    self.scoring:addJudgment("miss")
    
    -- Actualizar estado del engine para compatibilidad
    self.state.missedNotes = self.scoring.judgments.miss
    self.state.combo = self.scoring.combo
    self.state.maxCombo = self.scoring.maxCombo
    self.state.score = self.scoring.score
    self.state.accuracy = self.scoring:calculateAccuracy()
    
    -- Callback
    if self.callbacks.onNoteMiss then
        self.callbacks.onNoteMiss(note)
    end
    
    if self.callbacks.onComboBreak then
        self.callbacks.onComboBreak(self.state.maxCombo)
    end
    
    if self.callbacks.onGradeChange then
        self.callbacks.onGradeChange(self.scoring:calculateGrade())
    end
end

-- Estos métodos están mantenidos para compatibilidad pero no se usan internamente
-- El sistema de puntuación delega al ScoringSystem
function GameplayEngine:calculateScore(judgment)
    -- Delegar al sistema de puntuación (no se usa internamente)
    return 0
end

function GameplayEngine:calculateAccuracy()
    -- Delegar al sistema de puntuación
    if self.scoring then
        return self.scoring:calculateAccuracy()
    end
    return 0
end

function GameplayEngine:calculateGrade()
    -- Delegar al sistema de puntuación
    if self.scoring then
        return self.scoring:calculateGrade()
    end
    return "F"
end

-- Obtener tiempo final del chart
function GameplayEngine:getChartEndTime()
    if #self.notes == 0 then
        return 0
    end
    
    local lastNote = self.notes[#self.notes]
    return lastNote.time + 2
end

-- Obtener notas visibles en pantalla
function GameplayEngine:getVisibleNotes(screenTime)
    local visibleNotes = {}
    local visibleTime = screenTime + 2 -- 2 segundos de anticipación
    
    for _, note in ipairs(self.notes) do
        if note.time <= visibleTime and not note.processed then
            table.insert(visibleNotes, note)
        end
    end
    
    return visibleNotes
end

-- Obtener estado actual
function GameplayEngine:getState()
    return self.state
end

-- Obtener configuración
function GameplayEngine:getConfig()
    return self.config
end

-- Establecer velocidad de notas
function GameplayEngine:setNoteSpeed(speed)
    self.config.noteSpeed = speed
end

-- Establecer velocidad de scroll
function GameplayEngine:setScrollSpeed(speed)
    self.config.scrollSpeed = speed
end

-- Reiniciar juego
function GameplayEngine:reset()
    self.state = {
        playing = false,
        paused = false,
        finished = false,
        currentTime = 0,
        songTime = 0,
        combo = 0,
        maxCombo = 0,
        score = 0,
        accuracy = 0,
        maxAccuracy = 100,
        totalNotes = self.state.totalNotes,
        hitNotes = 0,
        missedNotes = 0,
        perfectHits = 0,
        greatHits = 0,
        goodHits = 0,
        badHits = 0,
        grade = "F"
    }
    
    -- Reiniciar notas
    for _, note in ipairs(self.notes) do
        note.hit = false
        note.missed = false
        note.processed = false
    end
    
    -- Reiniciar columnas
    for _, column in ipairs(self.columns) do
        column.keyPressed = false
    end
end

return GameplayEngine