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

-- Configuración (Estilo Etterna Judge 4 - Standard)
GameplayEngine.config = {
    columnCount = 4,
    noteSpeed = 1.0,
    scrollSpeed = 600,
    judgeWindow = {
        marvelous = 22.5, -- ms
        perfect = 45.0,   -- ms
        great = 90.0,    -- ms
        good = 135.0,    -- ms
        bad = 180.0,     -- ms
        miss = 180.0     -- ms
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
    totalNotes = 0,
    hitNotes = 0,
    missedNotes = 0,
    marvelousHits = 0,
    perfectHits = 0,
    greatHits = 0,
    goodHits = 0,
    badHits = 0,
    grade = "F",
    health = 100, -- Usamos escala 0-100 para vida
    maxHealth = 100,
    dead = false,
    lastMsOffset = 0
}

-- Sistema de puntuación
GameplayEngine.scoring = nil

-- Callbacks
GameplayEngine.callbacks = {
    onNoteHit = nil, -- (note, judgment, msOffset)
    onNoteMiss = nil,
    onComboBreak = nil,
    onScoreUpdate = nil,
    onGradeChange = nil
}

function GameplayEngine:new()
    local self = setmetatable({}, GameplayEngine)
    self:initialize()
    return self
end

function GameplayEngine:initialize(config)
    -- Configuración base (Evitar compartir tabla entre instancias)
    self.config = {
        columnCount = 4,
        noteSpeed = 1.0,
        scrollSpeed = 600,
        globalOffset = 0, -- ms
        songOffset = 0,   -- ms
        judgeWindow = {
            marvelous = 30,
            perfect = 60,
            great = 120,
            good = 180,
            bad = 250,
            miss = 400
        },
    }

    if config then
        for k, v in pairs(config) do
            if type(v) == "table" then
                for k2, v2 in pairs(v) do self.config[k][k2] = v2 end
            else
                self.config[k] = v
            end
        end
    end
    
    self.notes = {}
    self.state = {
        currentTime = 0,
        currentTimingPoint = nil,
        playing = false,
        paused = false,
        finished = false,
        songTime = 0,
        combo = 0,
        maxCombo = 0,
        score = 0,
        accuracy = 0,
        totalNotes = 0,
        hitNotes = 0,
        missedNotes = 0,
        marvelousHits = 0,
        perfectHits = 0,
        greatHits = 0,
        goodHits = 0,
        badHits = 0,
        grade = "F",
        health = 100,
        maxHealth = 100,
        dead = false,
        lastMsOffset = 0
    }
    
    -- Inicializar sistema de puntuación
    self.scoring = require("src.gameplay.engine.scoring"):new()
    
    -- Inicializar columnas
    self:initColumns()
end

-- Reiniciar motor
function GameplayEngine:reset()
    self:initialize()
end

-- Inicializar columnas
function GameplayEngine:initColumns()
    self.columns = {}
    for i = 1, self.config.columnCount do
        self.columns[i] = {
            index = i,
            keyPressed = false,
            lastHitTime = 0
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
            active = false
        }
        
        -- Validación de datos crítica (Senior AAA check)
        if type(note.time) == "number" and note.time == note.time then
            table.insert(self.notes, note)
        else
            print("[Engine] WARNING: Skipping corrupted note at index " .. _)
        end
    end
    
    -- Ordenar por tiempo
    table.sort(self.notes, function(a, b)
        return a.time < b.time
    end)
    
    self.state.totalNotes = #self.notes
    self.scoring.totalNotes = #self.notes
    
    -- Senior Debug: Verificación de Pipeline
    print(string.format("[Engine] Chart Loaded: %d notes", #self.notes))
    if #self.notes > 0 then
        print(string.format("[Engine] First Note Time: %.3fs, Last: %.3fs", self.notes[1].time, self.notes[#self.notes].time))
    else
        print("[Engine] WARNING: Chart has NO notes!")
    end
    
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

-- Morir
function GameplayEngine:die()
    self.state.playing = false
    self.state.dead = true
    self.state.finished = true
end

-- Finalizar juego
function GameplayEngine:finish()
    self.state.playing = false
    self.state.finished = true
end

-- Actualizar
function GameplayEngine:update(dt, audioTime)
    if not self.chart or not self.state.playing or self.state.paused then
        return
    end
    
    local totalOffset = (self.config.globalOffset or 0) + (self.config.songOffset or 0)
    
    if audioTime then
        -- Normalizar: audioTime (s) -> ms
        self.state.currentTime = (audioTime * 1000) - totalOffset
    else
        self.state.currentTime = self.state.currentTime + (dt * 1000)
    end
    
    -- Actualizar Timing Point actual (Wife3 / Hitsounds)
    if self.chart.timingPoints then
        for i = #self.chart.timingPoints, 1, -1 do
            local tp = self.chart.timingPoints[i]
            if self.state.currentTime >= tp.time then
                self.state.currentTimingPoint = tp
                break
            end
        end
    end
    
    -- Procesar notas (incluye misses y holds activos)
    self:processNotes()
    
    -- Verificar fin
    if self.state.currentTime > self:getChartEndTime() then
        self:finish()
    end
end

-- Procesar notas
function GameplayEngine:processNotes()
    local currentTime = self.state.currentTime
    local missWindow = self.config.judgeWindow.miss -- YA ESTÁ EN MS
    
    for _, note in ipairs(self.notes) do
        if not note.processed then
            -- Caso 1: Nota activa (Hold Note siendo presionada)
            if note.active then
                local endTime = note.time + note.holdTime
                
                -- Si llegamos al final del hold
                if currentTime >= endTime then
                    self:handleHit(note, "marvelous", 0, true) -- Tail hit
                elseif not self.columns[note.column].keyPressed then
                    -- Si se soltó prematuramente
                    note.active = false
                    self:handleMiss(note)
                end
            
            -- Caso 2: Nota normal (o Head de Hold) que se pasó del tiempo
            elseif currentTime > note.time + missWindow then
                -- Safety: No procesar como miss si el tiempo es muy bajo (evita bugs de carga)
                if currentTime > 100 then
                    self:handleMiss(note)
                end
            end
        end
    end
end

-- Manejar presión de tecla
function GameplayEngine:keyPressed(column)
    if not self.state.playing or self.state.paused then return end
    
    self.columns[column].keyPressed = true
    local currentTime = self.state.currentTime
    
    -- Buscar nota más cercana en la columna
    local closestNote = nil
    local minDiff = math.huge
    
    for _, note in ipairs(self.notes) do
        if note.column == column and not note.processed and not note.active then
            local diff = currentTime - note.time
            local absDiff = math.abs(diff)
            
            if absDiff < self.config.judgeWindow.miss then
                if absDiff < minDiff then
                    minDiff = absDiff
                    closestNote = note
                end
            end
        end
    end
    
    if closestNote then
        local diff = currentTime - closestNote.time
        local msOffset = diff * 1000
        local absMs = math.abs(msOffset)
        
        local judgment = "miss"
        if absMs <= self.config.judgeWindow.marvelous then judgment = "marvelous"
        elseif absMs <= self.config.judgeWindow.perfect then judgment = "perfect"
        elseif absMs <= self.config.judgeWindow.great then judgment = "great"
        elseif absMs <= self.config.judgeWindow.good then judgment = "good"
        elseif absMs <= self.config.judgeWindow.bad then judgment = "bad" end
        
        if judgment == "miss" then
            self:handleMiss(closestNote)
        else
            if closestNote.type == "hold" then
                closestNote.active = true
                self:handleHit(closestNote, judgment, msOffset, false) -- Head hit
            else
                self:handleHit(closestNote, judgment, msOffset)
            end
        end
    end
end

function GameplayEngine:keyReleased(column)
    self.columns[column].keyPressed = false
end

-- Manejar acierto
function GameplayEngine:handleHit(note, judgment, msOffset, isTail)
    if note.type == "tap" then
        note.hit = true
        note.processed = true
    elseif note.type == "hold" then
        if isTail then
            note.hit = true
            note.processed = true
            note.active = false
        else
            -- Head hit: note.active ya es true
        end
    end
    
    self.state.lastMsOffset = msOffset
    
    -- Actualizar puntuación
    self.scoring:addJudgment(judgment, msOffset, self.state.currentTime)
    
    -- Sincronizar estado
    local info = self.scoring:getScoreInfo()
    self.state.score = info.score
    self.state.combo = info.combo
    self.state.maxCombo = info.maxCombo
    self.state.accuracy = info.accuracy
    self.state.grade = info.grade
    
    -- Contadores
    if judgment == "marvelous" then self.state.marvelousHits = info.judgments.marvelous
    elseif judgment == "perfect" then self.state.perfectHits = info.judgments.perfect
    elseif judgment == "great" then self.state.greatHits = info.judgments.great
    elseif judgment == "good" then self.state.goodHits = info.judgments.good
    elseif judgment == "bad" then 
        self.state.badHits = info.judgments.bad
        self:applyHealthChange(-5)
    end
    
    self:applyHealthChange(2)
    
    if self.callbacks.onNoteHit then
        self.callbacks.onNoteHit(note, judgment, msOffset, note.hitSound, note.samples)
    end
end

-- Manejar fallo
function GameplayEngine:handleMiss(note)
    note.missed = true
    note.processed = true
    
    self.scoring:addJudgment("miss", nil, self.state.currentTime)
    
    local info = self.scoring:getScoreInfo()
    self.state.combo = 0
    self.state.missedNotes = info.judgments.miss
    self.state.accuracy = info.accuracy
    self.state.grade = info.grade
    
    -- Daño por miss
    self:applyHealthChange(-15)
    
    -- Callbacks
    if self.callbacks.onNoteMiss then
        self.callbacks.onNoteMiss(note)
    end
    
    if self.callbacks.onComboBreak then
        self.callbacks.onComboBreak(self.state.maxCombo)
    end
end

-- Cambiar vida
function GameplayEngine:applyHealthChange(amount)
    self.state.health = math.min(self.state.maxHealth, math.max(0, self.state.health + amount))
    if self.state.health <= 0 and not self.state.dead then
        self:die()
    end
end

-- Finalizar chart
function GameplayEngine:getChartEndTime()
    if #self.notes == 0 then return 0 end
    local lastNote = self.notes[#self.notes]
    return lastNote.time + (lastNote.holdTime or 0) + 2.0
end

-- Notas visibles
function GameplayEngine:getVisibleNotes(screenTime, anticipation)
    local visible = {}
    local maxTime = screenTime + (anticipation or 2.0)
    
    for _, note in ipairs(self.notes) do
        if not note.processed and note.time < maxTime then
            table.insert(visible, note)
        end
    end
    return visible
end

-- Obtener nota más cercana en una columna (Para Hitsounds)
function GameplayEngine:getClosestNote(column)
    local currentTime = self.state.currentTime
    for _, note in ipairs(self.notes) do
        if not note.processed and note.column == column then
            -- Solo considerar si está en un rango razonable de "intención" (ej. 200ms)
            if note.time >= currentTime - 0.2 and note.time <= currentTime + 0.2 then
                return note
            end
            -- Si ya pasamos la nota procesada, cortamos para eficiencia
            if note.time > currentTime + 0.2 then break end
        end
    end
    return nil
end

function GameplayEngine:getState()
    return self.state
end

function GameplayEngine:reset()
    self:initialize()
end

return GameplayEngine