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

<<<<<<< HEAD
-- Configuración (Estilo Etterna Judge 4 - Standard)
=======
-- Configuración
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
GameplayEngine.config = {
    columnCount = 4,
    noteSpeed = 1.0,
    scrollSpeed = 600,
    judgeWindow = {
<<<<<<< HEAD
        marvelous = 22.5, -- ms
        perfect = 45.0,   -- ms
        great = 90.0,    -- ms
        good = 135.0,    -- ms
        bad = 180.0,     -- ms
        miss = 180.0     -- ms
=======
        perfect = 40,  -- ms (más realista, osu!mania OD8 es +/- 40ms)
        good = 70,     -- ms
        bad = 100,     -- ms
        miss = 120     -- ms
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
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
<<<<<<< HEAD
    totalNotes = 0,
    hitNotes = 0,
    missedNotes = 0,
    marvelousHits = 0,
=======
    maxAccuracy = 100,
    totalNotes = 0,
    hitNotes = 0,
    missedNotes = 0,
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    perfectHits = 0,
    greatHits = 0,
    goodHits = 0,
    badHits = 0,
    grade = "F",
<<<<<<< HEAD
    health = 100, -- Usamos escala 0-100 para vida
    maxHealth = 100,
    dead = false,
    lastMsOffset = 0
=======
    health = 4,
    maxHealth = 4,
    dead = false
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
}

-- Sistema de puntuación
GameplayEngine.scoring = nil

-- Callbacks
GameplayEngine.callbacks = {
<<<<<<< HEAD
    onNoteHit = nil, -- (note, judgment, msOffset)
=======
    onNoteHit = nil,
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    onNoteMiss = nil,
    onComboBreak = nil,
    onScoreUpdate = nil,
    onGradeChange = nil
}

function GameplayEngine:new()
    local self = setmetatable({}, GameplayEngine)
<<<<<<< HEAD
    self:initialize()
=======
    -- Los valores por defecto se inicializan en initialize()
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    return self
end

function GameplayEngine:initialize(config)
<<<<<<< HEAD
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
=======
    self.config = config or self.config
    self.notes = {}
    self.columns = {}
    self.state = {
        playing = false,
        paused = false,
        finished = false,
        currentTime = 0,
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        songTime = 0,
        combo = 0,
        maxCombo = 0,
        score = 0,
        accuracy = 0,
<<<<<<< HEAD
        totalNotes = 0,
        hitNotes = 0,
        missedNotes = 0,
        marvelousHits = 0,
=======
        maxAccuracy = 100,
        totalNotes = 0,
        hitNotes = 0,
        missedNotes = 0,
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        perfectHits = 0,
        greatHits = 0,
        goodHits = 0,
        badHits = 0,
        grade = "F",
<<<<<<< HEAD
        health = 100,
        maxHealth = 100,
        dead = false,
        lastMsOffset = 0
=======
        health = 4,
        maxHealth = 4,
        dead = false
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    }
    
    -- Inicializar sistema de puntuación
    self.scoring = require("src.gameplay.engine.scoring"):new()
    
    -- Inicializar columnas
    self:initColumns()
end

<<<<<<< HEAD
-- Reiniciar motor
function GameplayEngine:reset()
    self:initialize()
end

=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
-- Inicializar columnas
function GameplayEngine:initColumns()
    self.columns = {}
    for i = 1, self.config.columnCount do
        self.columns[i] = {
            index = i,
<<<<<<< HEAD
            keyPressed = false,
            lastHitTime = 0
=======
            notes = {},
            keyPressed = false,
            lastHitTime = 0,
            heldNotes = {}
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
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
<<<<<<< HEAD
            active = false
        }
        
        -- Validación de datos crítica (Senior AAA check)
        if type(note.time) == "number" and note.time == note.time then
            table.insert(self.notes, note)
        else
            print("[Engine] WARNING: Skipping corrupted note at index " .. _)
        end
=======
            active = false -- Para Hold Notes
        }
        table.insert(self.notes, note)
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
    
    -- Ordenar por tiempo
    table.sort(self.notes, function(a, b)
        return a.time < b.time
    end)
    
    self.state.totalNotes = #self.notes
<<<<<<< HEAD
    self.scoring.totalNotes = #self.notes
    
    -- Senior Debug: Verificación de Pipeline
    print(string.format("[Engine] Chart Loaded: %d notes", #self.notes))
    if #self.notes > 0 then
        print(string.format("[Engine] First Note Time: %.3fs, Last: %.3fs", self.notes[1].time, self.notes[#self.notes].time))
    else
        print("[Engine] WARNING: Chart has NO notes!")
    end
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    
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
<<<<<<< HEAD
=======
    self:calculateGrade()
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

-- Finalizar juego
function GameplayEngine:finish()
    self.state.playing = false
    self.state.finished = true
<<<<<<< HEAD
=======
    self:calculateGrade()
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

-- Actualizar
function GameplayEngine:update(dt, audioTime)
<<<<<<< HEAD
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
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    if self.state.currentTime > self:getChartEndTime() then
        self:finish()
    end
end

-- Procesar notas
function GameplayEngine:processNotes()
    local currentTime = self.state.currentTime
<<<<<<< HEAD
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
=======
    
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

-- Manejar presión de tecla
function GameplayEngine:keyPressed(column)
<<<<<<< HEAD
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
=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
            end
        end
    end
    
<<<<<<< HEAD
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
=======
    -- Verificar si está dentro de la ventana de juicio
    if closestNote then
        local diffMs = closestDiff * 1000
        
        if diffMs <= self.config.judgeWindow.miss then
            local judgment = "bad"
            if diffMs <= self.config.judgeWindow.perfect then
                judgment = "perfect"
            elseif diffMs <= self.config.judgeWindow.good then
                judgment = "good"
            elseif diffMs <= self.config.judgeWindow.bad then
                judgment = "bad"
            else
                judgment = "miss"
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
    elseif judgment == "good" then
        self.state.goodHits = self.scoring.judgments.good
    elseif judgment == "bad" then
        self.state.badHits = self.scoring.judgments.bad
        self:takeDamage()
    elseif judgment == "miss" then
        self.state.missedNotes = self.scoring.judgments.miss
        self:takeDamage()
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
function GameplayEngine:handleMiss(note)
    note.missed = true
    note.processed = true
    
<<<<<<< HEAD
    self.scoring:addJudgment("miss", nil, self.state.currentTime)
    
    local info = self.scoring:getScoreInfo()
    self.state.combo = 0
    self.state.missedNotes = info.judgments.miss
    self.state.accuracy = info.accuracy
    self.state.grade = info.grade
    
    -- Daño por miss
    self:applyHealthChange(-15)
    
    -- Callbacks
=======
    -- Usar sistema de puntuación
    self.scoring:addJudgment("miss")
    
    -- Actualizar estado del engine para compatibilidad
    self.state.missedNotes = self.scoring.judgments.miss
    self.state.combo = self.scoring.combo
    self.state.maxCombo = self.scoring.maxCombo
    self.state.score = self.scoring.score
    self.state.accuracy = self.scoring:calculateAccuracy()
    
    self:takeDamage()
    
    -- Callback
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    if self.callbacks.onNoteMiss then
        self.callbacks.onNoteMiss(note)
    end
    
    if self.callbacks.onComboBreak then
        self.callbacks.onComboBreak(self.state.maxCombo)
    end
<<<<<<< HEAD
end

-- Cambiar vida
function GameplayEngine:applyHealthChange(amount)
    self.state.health = math.min(self.state.maxHealth, math.max(0, self.state.health + amount))
=======
    
    if self.callbacks.onGradeChange then
        self.callbacks.onGradeChange(self.scoring:calculateGrade())
    end
end

-- Sistema de Daño
function GameplayEngine:takeDamage()
    self.state.health = self.state.health - 1
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    if self.state.health <= 0 and not self.state.dead then
        self:die()
    end
end

<<<<<<< HEAD
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

=======
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
function GameplayEngine:getState()
    return self.state
end

<<<<<<< HEAD
function GameplayEngine:reset()
    self:initialize()
=======
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
        grade = "F",
        health = 4,
        maxHealth = 4,
        dead = false
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
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

return GameplayEngine