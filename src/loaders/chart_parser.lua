--[[
    RITMINITY - Chart Parser
    Sistema de importación de charts en múltiples formatos
]]

local ChartParser = {}
ChartParser.__index = ChartParser

-- Formatos soportados
ChartParser.supportedFormats = {
    "osu",
    "sm",
    "bms",
    "chart",
    "mid",
    "json"
}

-- Parser para cada formato
ChartParser.parsers = {}

function ChartParser:new()
    local self = setmetatable({}, ChartParser)
    self:registerParsers()
    return self
end

-- Registrar parsers
function ChartParser:registerParsers()
    -- Parser para formato osu!mania
    self.parsers.osu = function(content, path)
        return self:parseOsu(content, path)
    end
    
    -- Parser para formato StepMania (.sm)
    self.parsers.sm = function(content, path)
        return self:parseSM(content, path)
    end
    
    -- Parser para formato BMS
    self.parsers.bms = function(content, path)
        return self:parseBMS(content, path)
    end
    
    -- Parser para formato Chart (Guitar Hero)
    self.parsers.chart = function(content, path)
        return self:parseChart(content, path)
    end
    
    -- Parser para formato JSON
    self.parsers.json = function(content, path)
        return self:parseJSON(content, path)
    end
end

-- Detectar formato desde extensión
function ChartParser:detectFormat(path)
    local ext = path:match("%.([^%.]+)$")
    if ext then
        ext = ext:lower()
        for _, format in ipairs(self.supportedFormats) do
            if ext == format then
                return format
            end
        end
    end
    return nil
end

-- Parsear archivo de chart
function ChartParser:parseFile(path)
    local format = self:detectFormat(path)
    if not format then
        return nil, "Formato no soportado"
    end
    
    local file = love.filesystem.newFile(path)
    if not file then
        return nil, "No se pudo abrir el archivo"
    end
    
    file:open("r")
    local content = file:read()
    file:close()
    
    local parser = self.parsers[format]
    if parser then
        return parser(content, path)
    end
    
    return nil, "Parser no encontrado"
end

-- Parsear formato osu!mania (.osu)
function ChartParser:parseOsu(content, path)
    local chart = {
        format = "osu",
        metadata = {
            title = "Unknown",
            artist = "Unknown",
            creator = "Unknown",
            version = "Normal",
            audioFile = nil
        },
        difficulty = {
            columnCount = 4,
            hpDrain = 5,
            overallDifficulty = 5
        },
        notes = {},
        timingPoints = {}
    }
    
    local currentSection = nil
    
    -- Parsear línea por línea
    for line in content:gmatch("[^\r\n]+") do
        -- Ignorar espacios extra al inicio y final
        line = line:gsub("^%s*(.-)%s*$", "%1")
        
        if line == "" or line:sub(1, 2) == "//" then
            -- Ignorar
        elseif line:sub(1, 1) == "[" then
            currentSection = line:match("%[(.+)%]")
        else
            -- Metadatos y dificultad
            if currentSection == "General" or currentSection == "Metadata" or currentSection == "Difficulty" then
                local key, value = line:match("([^:]+):%s*(.+)")
                if key and value then
                    key = key:gsub("%s+", "")
                    if key == "Title" then chart.metadata.title = value
                    elseif key == "Artist" then chart.metadata.artist = value
                    elseif key == "Creator" then chart.metadata.creator = value
                    elseif key == "Version" then chart.metadata.version = value
                    elseif key == "AudioFilename" then chart.metadata.audioFile = value
                    elseif key == "CircleSize" then chart.difficulty.columnCount = tonumber(value) or 4
                    elseif key == "HPDrainRate" then chart.difficulty.hpDrain = tonumber(value) or 5
                    elseif key == "OverallDifficulty" then chart.difficulty.overallDifficulty = tonumber(value) or 5
                    elseif key == "Mode" then
                        if tonumber(value) ~= 3 then
                            return nil, "Solo se soporta formato osu!mania (Mode: 3)"
                        end
                    end
                end
            elseif currentSection == "TimingPoints" then
                local parts = {}
                for p in line:gmatch("([^,]+)") do table.insert(parts, p) end
                if #parts >= 2 then
                    table.insert(chart.timingPoints, {
                        time = tonumber(parts[1]) / 1000,
                        beatLength = tonumber(parts[2]),
                        meter = tonumber(parts[3]) or 4,
                        sampleSet = tonumber(parts[4]) or 0,
                        sampleIndex = tonumber(parts[5]) or 0,
                        volume = tonumber(parts[6]) or 100,
                        uninherited = tonumber(parts[7]) == 1,
                        effects = tonumber(parts[8]) or 0
                    })
                end
            elseif currentSection == "HitObjects" then
                local parts = {}
                for p in line:gmatch("([^,]+)") do table.insert(parts, p) end
                
                if #parts >= 5 then
                    local x = tonumber(parts[1]) or 0
                    local time = tonumber(parts[3]) or 0
                    local typeBit = tonumber(parts[4]) or 0
                    
                    -- Columna en mania se calcula por X: (x * columns) / 512
                    local col = math.floor(x * chart.difficulty.columnCount / 512) + 1
                    col = math.max(1, math.min(col, chart.difficulty.columnCount))
                    
                    local note = {
                        time = time,
                        column = col,
                        lane = col, -- Alias solicitado
                        type = "tap",
                        holdTime = 0,
                        hitSound = tonumber(parts[5]) or 0,
                        samples = parts[6] or "" -- sampleset:additions:index:volume:filename
                    }
                    
                    -- Es un Hold Note? (Bit 7 es 128)
                    if bit.band(typeBit, 128) > 0 then
                        note.type = "hold"
                        -- Formato Hold: x,y,time,type,hitSound,endTime:hitSample
                        local extra = parts[6] or ""
                        local endTimeMs = tonumber(extra:match("^(%d+)"))
                        if endTimeMs then
                            note.holdTime = endTimeMs - time
                            -- Para holds, los samples están en el 7mo campo si existe, o parsear el 6to
                            note.samples = parts[6]:match("^%d+:(.*)") or ""
                        end
                    end
                    
                    table.insert(chart.notes, note)
                end
            end
        end
    end
    
    -- Extraer BPM real del primer timing point heredado
    for _, tp in ipairs(chart.timingPoints) do
        if tp.uninherited and tp.beatLength > 0 then
            chart.metadata.bpm = math.floor((60000 / tp.beatLength) + 0.5)
            break
        end
    end
    
    return chart
end

-- Parsear formato StepMania (.sm)
function ChartParser:parseSM(content, path)
    local chart = {
        format = "sm",
        metadata = {
            title = "Unknown",
            artist = "Unknown",
            bpm = 120,
            offset = 0,
            audioFile = nil
        },
        notes = {}
    }
    
    -- Extraer tags básicos
    chart.metadata.title = content:match("#TITLE:([^;]*);") or "Unknown"
    chart.metadata.artist = content:match("#ARTIST:([^;]*);") or "Unknown"
    chart.metadata.audioFile = content:match("#MUSIC:([^;]*);") or nil
    chart.metadata.offset = tonumber(content:match("#OFFSET:([^;]*);")) or 0
    
    -- BPMs: #BPMS:0.000=120.000,...;
    local bpmsStr = content:match("#BPMS:([^;]*);")
    local bpms = {}
    if bpmsStr then
        for beat, val in bpmsStr:gmatch("([%d%.]+)=([%d%.]+)") do
            table.insert(bpms, {beat = tonumber(beat), bpm = tonumber(val)})
        end
    end
    chart.metadata.bpm = bpms[1] and bpms[1].bpm or 120
    
    -- Parsear Notas (#NOTES)
    -- Buscamos el bloque de dance-single (4K) o similar
    for noteBlock in content:gmatch("#NOTES:([^;]*);") do
        local lines = {}
        for line in noteBlock:gmatch("[^\r\n]+") do table.insert(lines, (line:gsub("^%s*(.-)%s*$", "%1"))) end
        
        local type = lines[1] or ""
        if type:find("dance%-single") or type:find("4k") then
            local noteData = noteBlock:match(".-:.-:.-:.-:.-:(.*)$")
            if noteData then
                self:parseSMNoteData(noteData, chart.notes, bpms, chart.metadata.offset)
                break -- Usamos el primero que encontremos para simplicidad
            end
        end
    end
    
    return chart
end

-- Parsear el bloque de datos de notas de SM (rítmico)
function ChartParser:parseSMNoteData(data, notes, bpms, offset)
    local measures = {}
    for measure in data:gmatch("([^,]+)") do
        table.insert(measures, measure)
    end
    
    local currentBeat = 0
    local bpm = bpms[1] and bpms[1].bpm or 120
    
    -- Un hold pendiente por columna
    local pendingHolds = {}
    
    for mIndex, measure in ipairs(measures) do
        local lines = {}
        for line in measure:gmatch("[01234MLFK]+") do table.insert(lines, line) end
        
        local subdivision = #lines
        if subdivision > 0 then
            for lIndex, line in ipairs(lines) do
                local time = self:beatToTime(currentBeat, bpms) - offset
                
                for col = 1, #line do
                    local char = line:sub(col, col)
                    
                    if char == "1" then -- Tap
                        table.insert(notes, {time = time, column = col, type = "tap", holdTime = 0})
                    elseif char == "2" then -- Hold Head
                        pendingHolds[col] = {time = time, column = col, type = "hold"}
                    elseif char == "3" then -- Hold Tail
                        if pendingHolds[col] then
                            local h = pendingHolds[col]
                            h.holdTime = time - h.time
                            table.insert(notes, h)
                            pendingHolds[col] = nil
                        end
                    elseif char == "M" or char == "4" then -- Mine
                        -- Opcional: implementar minas
                    end
                end
                
                currentBeat = currentBeat + (4 / subdivision)
            end
        end
    end
end

-- Convertir Beat a Tiempo absoluto (considerando cambios de BPM)
function ChartParser:beatToTime(beat, bpms)
    local time = 0
    local currentBeat = 0
    local currentBpm = bpms[1] and bpms[1].bpm or 120
    
    for i = 2, #bpms do
        local b = bpms[i]
        if beat > b.beat then
            local diff = b.beat - currentBeat
            time = time + (diff * 60 / currentBpm)
            currentBeat = b.beat
            currentBpm = b.bpm
        else
            break
        end
    end
    
    time = time + ((beat - currentBeat) * 60 / currentBpm)
    return time
end

-- Parsear formato BMS
function ChartParser:parseBMS(content, path)
    local chart = {
        format = "bms",
        metadata = {},
        notes = {}
    }
    
    local bpm = 120
    local lntype = 0
    
    for line in content:gmatch("[^\r\n]+") do
        line = line:trim()
        
        if line:sub(1, 3) == "#BP" then
            bpm = tonumber(line:match("#BPM%s+(%d+)")) or bpm
        elseif line:sub(1, 2) == "#@" then
            -- Metadata
        elseif line:sub(1, 2) == "# " then
            -- Comentario
        elseif line:sub(1, 1) == "#" and line:match("%d+%s+%d+") then
            local bar, channel, data = line:match("#(%d+):(%d+):(.+)")
            if bar and channel and data then
                self:parseBMSNotes(tonumber(bar), tonumber(channel), data, chart.notes, bpm)
            end
        end
    end
    
    table.sort(chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    return chart
end

-- Parsear notas de BMS
function ChartParser:parseBMSNotes(bar, channel, data, notes, bpm)
    local beatPerBar = 4
    local baseTime = (bar - 1) * beatPerBar * (60 / bpm)
    
    -- Canales de nota (diferentes formatos)
    local isLongNote = (channel >= 50 and channel < 60)
    local column = channel % 10
    
    if column >= 1 and column <= 9 then
        local noteData = data:sub(1, 2)
        if noteData ~= "00" then
            local noteTime = baseTime + (beatPerBar / #data) * (tonumber(noteData, 16) or 0)
            table.insert(notes, {
                time = noteTime,
                column = column,
                type = isLongNote and "hold" or "tap",
                holdTime = 0
            })
        end
    end
end

-- Parsear formato Chart
function ChartParser:parseChart(content, path)
    local chart = {
        format = "chart",
        metadata = {},
        notes = {}
    }
    
    local currentSection = nil
    
    for line in content:gmatch("[^\r\n]+") do
        line = line:trim()
        
        if line == "" or line:sub(1, 2) == "//" then
            -- Comentario
        elseif line:sub(1, 1) == "[" then
            currentSection = line:match("%[(.+)%]")
        elseif currentSection == "Song" then
            local key, value = line:match("([^=]+)=(.+)")
            if key and value then
                chart.metadata[key:trim()] = value:trim()
            end
        elseif currentSection == "ExpertSingle" or currentSection == "HardSingle" or currentSection == "MediumSingle" or currentSection == "EasySingle" then
            local note = self:parseChartNote(line)
            if note then
                table.insert(chart.notes, note)
            end
        end
    end
    
    table.sort(chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    return chart
end

-- Parsear nota de Chart
function ChartParser:parseChartNote(line)
    local time, type, column = line:match("(%d+)%s+(%w+)%s+(%d+)")
    if time and column then
        return {
            time = tonumber(time) / 1000,
            column = tonumber(column),
            type = type or "tap",
            holdTime = 0
        }
    end
    return nil
end

-- Parsear formato JSON
function ChartParser:parseJSON(content, path)
    local func, err = load("return " .. content)
    if func then
        local success, data = pcall(func)
        if success and data then
            return data
        end
    end
    return nil
end

function ChartParser:convertToInternal(chart, columnCount)
    local internal = {
        notes = {},
        bpm = chart.metadata.bpm or 120,
        offset = chart.metadata.offset or 0,
        audioFile = chart.metadata.audioFile or chart.metadata.AudioFilename or nil,
        title = chart.metadata.title or chart.metadata.Title or "Unknown",
        artist = chart.metadata.artist or chart.metadata.Artist or "Unknown",
        difficulty = chart.metadata.version or "Normal",
        columnCount = chart.difficulty and chart.difficulty.columnCount or 4
    }
    
    for _, note in ipairs(chart.notes) do
        local column = note.column
        if columnCount then
            column = math.min(column, columnCount)
        end
        
        table.insert(internal.notes, {
            time = note.time,
            column = column,
            type = note.type,
            holdTime = note.holdTime or 0,
            hitSound = note.hitSound or 0,
            samples = note.samples or ""
        })
    end
    
    -- Ordenar siempre por tiempo para seguridad
    table.sort(internal.notes, function(a, b)
        return a.time < b.time
    end)
    
    return internal
end

-- Exportar a formato JSON
function ChartParser:exportToJSON(chart)
    return self.parsers.json(chart, "export")
end

return ChartParser