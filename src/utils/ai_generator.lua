--[[
    RITMINITY - AI Chart Generator
    Sistema de IA para generación automática de charts
]]

local AIChartGenerator = {}
AIChartGenerator.__index = AIChartGenerator

-- Configuración por defecto
AIChartGenerator.defaultConfig = {
    bpmDetection = true,
    beatDetection = true,
    patternRecognition = true,
    difficulty = "normal",
    columnCount = 4,
    minInterval = 0.125, -- Intervalo mínimo entre notas (8th)
    maxInterval = 2.0,   -- Intervalo máximo
    density = 0.5,       -- Densidad de notas (0-1)
    complexity = 0.5      -- Complejidad de patrones (0-1)
}

-- Patrones de rhythm game
AIChartGenerator.patterns = {
    -- Patrones básicos
    single = {1},
    double = {1, 1},
    triple = {1, 1, 1},
    quad = {1, 1, 1, 1},
    
    -- Patrones rítmicos
    eighth = {1, 0, 1, 0},
    sixteenth = {1, 0, 1, 0, 1, 0, 1, 0},
    triplet = {1, 0, 1, 0, 1},
    
    -- Patrones especiales
    stair = {1, 2, 3, 4},
    reverseStair = {4, 3, 2, 1},
    jack = {1, 1, 1},
    split = {1, 3},
    alternating = {1, 2, 1, 2}
}

function AIChartGenerator:new()
    local self = setmetatable({}, AIChartGenerator)
    self.config = self.defaultConfig
    return self
end

-- Establecer configuración
function AIChartGenerator:setConfig(config)
    self.config = config or self.defaultConfig
end

-- Generar chart desde archivo de audio real
function AIChartGenerator:generateFromAudio(audioPath)
    -- Cargar datos PCM crudos para analizar picos
    local success, soundData = pcall(love.sound.newSoundData, audioPath)
    if not success or not soundData then
        return nil, "No se pudo leer el archivo de audio: " .. tostring(soundData)
    end
    
    -- El nombre de la canción puede ser el nombre del archivo
    local songTitle = audioPath:match("([^/\\]+)%.%w+$") or "Auto Generada"
    
    local chart = {
        metadata = {
            title = songTitle,
            artist = "RITMINITY AI",
            bpm = 120,
            offset = 0,
            difficulty = self.config.difficulty,
            audioFile = audioPath
        },
        notes = {}
    }
    
    -- Detectar beats reales analizando las frecuencias de energía
    local beats = self:detectBeats(soundData)
<<<<<<< HEAD
    print(string.format("[AI] Detected %d raw energy peaks", #beats))
    
    -- Estimar el BPM de la canción basándose en los beats encontrados
    chart.metadata.bpm = self:estimateBPM(beats)
    print(string.format("[AI] Estimated BPM: %d", chart.metadata.bpm))
=======
    
    -- Estimar el BPM de la canción basándose en los beats encontrados
    chart.metadata.bpm = self:estimateBPM(beats)
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    
    -- Generar notas basadas en los picos reales encontrados
    for _, beat in ipairs(beats) do
        -- Densidad: solo incluir esta nota si pasa la probabilidad configurada
<<<<<<< HEAD
        if math.random() < (self.config.density or 0.5) then
=======
        if math.random() < self.config.density then
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
            local note = self:generateNoteForBeat(beat)
            table.insert(chart.notes, note)
        end
    end
    
<<<<<<< HEAD
    -- FALLBACK: Si la detección falló o dio muy pocas notas, generar rítmicamente
    if #chart.notes < 20 then
        print("[AI] WARNING: Low beat detection count. Applying rhythmic fallback.")
        local fallbackNotes = self:generateRhythmicFallback(soundData:getDuration(), chart.metadata.bpm)
        for _, n in ipairs(fallbackNotes) do
            table.insert(chart.notes, n)
        end
        -- Ordenar para mantener consistencia
        table.sort(chart.notes, function(a, b) return a.time < b.time end)
    end
    
    print(string.format("[AI] Generation complete: %d total notes", #chart.notes))
    
    -- DEBUG OBLIGATORIO (Consola)
    print("Notas generadas:", #chart.notes)
    for i=1, math.min(5, #chart.notes) do
        print(string.format("Nota %d: Time=%.3f, Lane=%d", i, chart.notes[i].time, chart.notes[i].column))
    end
    
    return chart
end

-- Fallback rítmico basado en BPM
function AIChartGenerator:generateRhythmicFallback(duration, bpm)
    local notes = {}
    local beatDuration = 60 / bpm
    local currentTime = 2.0 -- Empezar con 2s de margen
    
    while currentTime < duration - 2.0 do
        -- Crear patrones básicos 4/4
        for i = 1, 4 do
            if math.random() < 0.7 then -- 70% de probabilidad por beat
                table.insert(notes, {
                    time = currentTime,
                    column = math.random(1, self.config.columnCount or 4),
                    type = "tap",
                    holdTime = 0
                })
            end
            currentTime = currentTime + beatDuration
        end
    end
    return notes
end

=======
    return chart
end

>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
-- Estimar BPM en base a los intervalos de notas
function AIChartGenerator:estimateBPM(beats)
    if #beats < 2 then return 120 end
    local intervals = {}
    for i = 2, #beats do
        table.insert(intervals, beats[i].time - beats[i-1].time)
    end
    
    table.sort(intervals)
    local median = intervals[math.floor(#intervals / 2)]
    
    if median and median > 0 then
        local bpm = 60 / median
        -- Normalizar el BPM entre 80 y 240
        while bpm < 80 do bpm = bpm * 2 end
        while bpm > 240 do bpm = bpm / 2 end
        return math.floor(bpm)
    end
    return 120
end

-- Seleccionar patrón basado en complejidad
function AIChartGenerator:selectPattern()
    local availablePatterns = {}
    
    if self.config.complexity < 0.3 then
        availablePatterns = {"single", "eighth"}
    elseif self.config.complexity < 0.6 then
        availablePatterns = {"single", "double", "eighth", "triplet"}
    elseif self.config.complexity < 0.8 then
        availablePatterns = {"single", "double", "triple", "eighth", "sixteenth", "stair", "alternating"}
    else
        availablePatterns = {"single", "double", "triple", "quad", "eighth", "sixteenth", "stair", "reverseStair", "jack", "split", "alternating"}
    end
    
    local index = math.random(1, #availablePatterns)
    return self.patterns[availablePatterns[index]]
end

-- Generar notas para un patrón
function AIChartGenerator:generatePatternNotes(pattern, startTime)
    local notes = {}
    local beatDuration = 60 / (self.config.bpm or 120)
    
    for i, isNote in ipairs(pattern) do
        if isNote == 1 then
            local column = math.random(1, self.config.columnCount)
            table.insert(notes, {
                time = startTime + (i - 1) * beatDuration,
                column = column,
                type = "tap",
                holdTime = 0
            })
        end
    end
    
    return notes
end

-- Aplicar dificultad
function AIChartGenerator:applyDifficulty(chart)
    local density = self.config.density
    local complexity = self.config.complexity
    
    -- Filtrar notas basado en densidad
    if density < 1.0 then
        local filteredNotes = {}
        for i, note in ipairs(chart.notes) do
            if math.random() < density then
                table.insert(filteredNotes, note)
            end
        end
        chart.notes = filteredNotes
    end
    
    -- Ajustar metadata de dificultad
    if self.config.difficulty == "easy" then
        chart.metadata.difficulty = "Easy"
    elseif self.config.difficulty == "hard" then
        chart.metadata.difficulty = "Hard"
    elseif self.config.difficulty == "insane" then
        chart.metadata.difficulty = "Insane"
    else
        chart.metadata.difficulty = "Normal"
    end
end

-- Generar chart con beat detection avanzado
function AIChartGenerator:generateWithBeatDetection(audioData)
    local chart = {
        metadata = {
            title = "AI Generated (Beat Detection)",
            artist = "RITMINITY AI",
            bpm = 120,
            offset = 0
        },
        notes = {}
    }
    
    -- Detectar beats
    local beats = self:detectBeats(audioData)
    
    -- Generar notas en cada beat
    for _, beat in ipairs(beats) do
        local note = self:generateNoteForBeat(beat)
        table.insert(chart.notes, note)
    end
    
    return chart
end

-- Detectar beats en audio (PCM RMS Energy Analysis)
function AIChartGenerator:detectBeats(soundData)
    local beats = {}
    local sampleRate = soundData:getSampleRate()
    local channels = soundData:getChannelCount()
    local sampleCount = soundData:getSampleCount()
    
    -- Usamos una ventana de análisis de ~20ms
    local windowSize = math.floor(sampleRate * 0.02) 
    local energyHistory = {}
    local historySize = 43 -- Historial local de ~1 segundo para sacar promedio dinámico
    local localEnergySum = 0
    
    -- Sensibilidad (Multiplicador de pico de energía por encima de la media)
    local threshold = 1.3 
    if self.config.complexity > 0.7 then threshold = 1.1 end -- Más complejidad = más sensitivo a notas ligeras
    
    local i = 0
    while i < sampleCount - windowSize do
        local windowEnergy = 0
        
        for j = 0, windowSize - 1 do
            -- Tomar muestra (índice 0 a sampleCount - 1)
            -- Si pides solo i+j, Love2D 11.0 asume canal 1.
            local sample = soundData:getSample(i + j)
            if sample then
                windowEnergy = windowEnergy + (sample * sample)
            end
        end
        
        -- Añadir a nuestra historia rodante de volumen local
        table.insert(energyHistory, windowEnergy)
        localEnergySum = localEnergySum + windowEnergy
        
        if #energyHistory > historySize then
            local oldEnergy = table.remove(energyHistory, 1)
            localEnergySum = localEnergySum - oldEnergy
        end
        
        -- Si ya tenemos suficiente historial
        if #energyHistory == historySize then
            local averageEnergy = localEnergySum / historySize
            
            -- Detectar si este bloque de tiempo es un golpe fuerte (Pico de energía)
<<<<<<< HEAD
            -- Umbral reducido de 0.05 a 0.01 para mayor sensibilidad en canciones suaves
            if windowEnergy > (averageEnergy * threshold) and windowEnergy > 0.01 then
                local timeInMs = (i / sampleRate) * 1000
                
                -- Prevenir clustering (notas encimadas) respetando minInterval (en ms)
                local minIntervalMs = (self.config.minInterval or 0.125) * 1000
                if #beats == 0 or (timeInMs - beats[#beats].time >= minIntervalMs) then
                    table.insert(beats, {
                        time = timeInMs,
=======
            if windowEnergy > (averageEnergy * threshold) and windowEnergy > 0.05 then
                local timeInSeconds = i / sampleRate
                
                -- Prevenir clustering (notas encimadas) respetando minInterval
                if #beats == 0 or (timeInSeconds - beats[#beats].time >= self.config.minInterval) then
                    table.insert(beats, {
                        time = timeInSeconds,
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
                        strength = windowEnergy,
                        type = "downbeat"
                    })
                end
            end
        end
        
        -- Avanzar la ventana a la mitad para solapar y ganar precisión
        i = i + math.floor(windowSize / 2)
    end
    
    return beats
end

-- Generar nota para un beat
function AIChartGenerator:generateNoteForBeat(beat)
    local column
    
    -- Usar patrón basado en tipo de beat
    if beat.type == "downbeat" then
        column = math.random(1, self.config.columnCount)
    else
        -- Off-beats tienen más variación
        local patternChoice = math.random()
        if patternChoice < 0.3 then
            column = math.random(1, self.config.columnCount)
        elseif patternChoice < 0.6 then
            column = math.floor((beat.time * 2) % self.config.columnCount) + 1
        else
            column = math.random(1, self.config.columnCount)
        end
    end
    
    return {
        time = beat.time,
        column = column,
<<<<<<< HEAD
        lane = column, -- Alias solicitado
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        type = "tap",
        holdTime = 0
    }
end

-- Generar chart para práctica
function AIChartGenerator:generatePracticeChart(duration, bpm)
    local chart = {
        metadata = {
            title = "Practice Chart",
            artist = "RITMINITY AI",
            bpm = bpm or 120,
            offset = 0,
            difficulty = "Easy"
        },
        notes = {}
    }
    
    local beatDuration = 60 / bpm
    local currentTime = 0
    
    -- Patrón simple: una nota por beat
    while currentTime < duration do
        table.insert(chart.notes, {
            time = currentTime,
            column = 1,
            type = "tap",
            holdTime = 0
        })
        
        currentTime = currentTime + beatDuration
    end
    
    return chart
end

-- Generar chart de calentamiento
function AIChartGenerator:generateWarmupChart(duration)
    local chart = {
        metadata = {
            title = "Warmup Chart",
            artist = "RITMINITY AI",
            bpm = 80,
            offset = 0,
            difficulty = "Easy"
        },
        notes = {}
    }
    
    local beatDuration = 60 / 80
    local columns = {1, 2, 3, 4}
    local currentColumn = 1
    
    for t = 0, duration, beatDuration do
        table.insert(chart.notes, {
            time = t,
            column = columns[currentColumn],
            type = "tap",
            holdTime = 0
        })
        
        currentColumn = currentColumn + 1
        if currentColumn > 4 then
            currentColumn = 1
        end
    end
    
    return chart
end

-- Optimizar chart para jugabilidad
function AIChartGenerator:optimizeChart(chart)
    local optimized = {
        metadata = chart.metadata,
        notes = {}
    }
    
    -- Eliminar notas demasiado cercanas
    local lastNoteTime = -1
    local minInterval = self.config.minInterval
    
    for _, note in ipairs(chart.notes) do
        if note.time - lastNoteTime >= minInterval then
            table.insert(optimized.notes, note)
            lastNoteTime = note.time
        end
    end
    
    -- Balancear entre columnas
    self:balanceColumns(optimized.notes)
    
    return optimized
end

-- Balancear notas entre columnas
function AIChartGenerator:balanceColumns(notes)
    local columnCounts = {}
    for i = 1, self.config.columnCount do
        columnCounts[i] = 0
    end
    
    -- Contar notas por columna
    for _, note in ipairs(notes) do
        columnCounts[note.column] = columnCounts[note.column] + 1
    end
    
    -- Por implementar: redistribución si hay desbalance
end

-- Exportar chart a formato compatible
function AIChartGenerator:exportChart(chart, format)
    if format == "json" then
        return self:exportToJSON(chart)
    elseif format == "osu" then
        return self:exportToOsu(chart)
    elseif format == "sm" then
        return self:exportToSM(chart)
    end
    
    return self:exportToJSON(chart)
end

-- Exportar a JSON
function AIChartGenerator:exportToJSON(chart)
    local json = "{\n"
    json = json .. '  "metadata": {\n'
    json = json .. '    "title": "' .. (chart.metadata.title or "") .. '",\n'
    json = json .. '    "artist": "' .. (chart.metadata.artist or "") .. '",\n'
    json = json .. '    "bpm": ' .. (chart.metadata.bpm or 120) .. ',\n'
    json = json .. '    "difficulty": "' .. (chart.metadata.difficulty or "Normal") .. '"\n'
    json = json .. '  },\n'
    json = json .. '  "notes": [\n'
    
    for i, note in ipairs(chart.notes) do
        json = json .. '    {'
        json = json .. '"time": ' .. note.time .. ', '
        json = json .. '"column": ' .. note.column .. ', '
        json = json .. '"type": "' .. note.type .. '"'
        json = json .. '}'
        if i < #chart.notes then
            json = json .. ","
        end
        json = json .. "\n"
    end
    
    json = json .. "  ]\n"
    json = json .. "}"
    
    return json
end

-- Exportar a formato osu!
function AIChartGenerator:exportToOsu(chart)
    local output = ""
    
    output = output .. "osu file format v14\n\n"
    output = output .. "[General]\n"
    output = output .. "AudioFilename: " .. (chart.metadata.audioFile or "") .. "\n"
    output = output .. "AudioLeadIn: 0\n"
    output = output .. "PreviewTime: -1\n"
    output = output .. "Countdown: 0\n"
    output = output .. "SampleSet: Normal\n"
    output = output .. "StackLeniency: 0.3\n"
    output = output .. "Mode: 3\n"
    output = output .. "LetterboxInBreaks: 0\n"
    output = output .. "SpecialStyle: 0\n"
    output = output .. "WidescreenStoryboard: 0\n\n"
    
    output = output .. "[Metadata]\n"
    output = output .. "Title:" .. (chart.metadata.title or "") .. "\n"
    output = output .. "Artist:" .. (chart.metadata.artist or "") .. "\n"
    output = output .. "Creator:" .. (chart.metadata.creator or "RITMINITY AI") .. "\n"
    output = output .. "Version:" .. (chart.metadata.difficulty or "Normal") .. "\n\n"
    
    output = output .. "[Difficulty]\n"
    output = output .. "HP Drain Rate:5\n"
    output = output .. "Circle Size:4\n"
    output = output .. "Overall Difficulty:5\n"
    output = output .. "Approach Rate:5\n\n"
    
    output = output .. "[TimingPoints]\n"
    output = output .. "0," .. (60000 / chart.metadata.bpm) .. ",4,1,0,100,1,0\n\n"
    
    output = output .. "[HitObjects]\n"
    for _, note in ipairs(chart.notes) do
        local x = (note.column - 1) * 128 + 64
        local y = 192
        local time = math.floor(note.time * 1000)
        output = output .. x .. "," .. y .. "," .. time .. ",1,0,0\n"
    end
    
    return output
end

-- Exportar a formato StepMania
function AIChartGenerator:exportToSM(chart)
    local output = ""
    
    output = output .. "#TITLE:" .. (chart.metadata.title or "") .. ";\n"
    output = output .. "#ARTIST:" .. (chart.metadata.artist or "") .. ";\n"
    output = output .. "#BPM:" .. (chart.metadata.bpm or 120) .. ";\n"
    output = output .. "#OFFSET:" .. (chart.metadata.offset or 0) .. ";\n"
    output = output .. "#DIFFICULTY:" .. (chart.metadata.difficulty or "Normal") .. ";\n"
    output = output .. "#NOTES:\n"
    output = output .. "     dance-single:\n"
    output = output .. "     :\n"
    
    -- Convertir notas a formato de StepMania
    local measure = 0
    local beatStr = ""
    
    for _, note in ipairs(chart.notes) do
        local measureNum = math.floor(note.time / (240 / chart.metadata.bpm))
        local beat = math.floor((note.time % (240 / chart.metadata.bpm)) / (60 / chart.metadata.bpm))
        
        while measure < measureNum do
            output = output .. "0000"
            output = output .. "0000"
            output = output .. "0000"
            output = output .. "0000\n"
            measure = measure + 1
        end
        
        -- Por implementar: formato completo
    end
    
    output = output .. ";\n"
    
    return output
end

return AIChartGenerator