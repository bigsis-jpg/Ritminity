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

-- Parsear formato osu!mania
function ChartParser:parseOsu(content, path)
    local chart = {
        format = "osu",
        metadata = {},
        difficulty = {},
        notes = {}
    }
    
    local currentSection = nil
    local bpmChanges = {}
    local timingPoints = {}
    
    -- Parsear línea por línea
    for line in content:gmatch("[^\r\n]+") do
        line = line:trim()
        
        if line == "" or line:sub(1, 1) == "#" then
            -- Comentario o línea vacía
        elseif line:sub(1, 1) == "[" then
            currentSection = line:match("%[(.+)%]")
        elseif currentSection == "General" then
            local key, value = line:match("([^:]+):%s*(.+)")
            if key and value then
                chart.metadata[key:trim()] = value:trim()
            end
        elseif currentSection == "Difficulty" then
            local key, value = line:match("([^:]+):%s*(.+)")
            if key and value then
                chart.difficulty[key:trim()] = tonumber(value) or value
            end
        elseif currentSection == "TimingPoints" then
            local tp = self:parseOsuTimingPoint(line)
            if tp then
                table.insert(timingPoints, tp)
            end
        elseif currentSection == "HitObjects" then
            local note = self:parseOsuHitObject(line)
            if note then
                table.insert(chart.notes, note)
            end
        end
    end
    
    -- Ordenar notas por tiempo
    table.sort(chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    chart.timingPoints = timingPoints
    
    return chart
end

-- Parsear timing point de osu!
function ChartParser:parseOsuTimingPoint(line)
    local parts = {}
    for part in line:gmatch("([^,]+)") do
        table.insert(parts, tonumber(part) or 0)
    end
    
    if #parts >= 2 then
        return {
            time = parts[1] / 1000, -- Convertir a segundos
            beatLength = parts[2],
            meter = parts[3] or 4,
            sampleSet = parts[4] or 0,
            sampleIndex = parts[5] or 0,
            volume = parts[6] or 100,
            uninherited = parts[7] or 1,
            effects = parts[8] or 0
        }
    end
    
    return nil
end

-- Parsear hit object de osu!
function ChartParser:parseOsuHitObject(line)
    local parts = {}
    for part in line:gmatch("([^,]+)") do
        table.insert(parts, part)
    end
    
    if #parts >= 3 then
        local x = tonumber(parts[1]) or 0
        local y = tonumber(parts[2]) or 0
        local time = (tonumber(parts[3]) or 0) / 1000
        local type = tonumber(parts[4]) or 0
        
        -- Determinar columna basada en X (para osu!mania)
        local columnCount = 4
        local column = math.floor(x / 512 * columnCount) + 1
        column = math.min(math.max(column, 1), columnCount)
        
        -- Determinar tipo de nota
        local noteType = "tap"
        if bit.band(type, 128) > 0 then
            noteType = "hold"
        end
        
        -- Extraer duración para hold notes (osu! format: x,y,time,type,hitSound,endTime:hitSample)
        local holdTime = 0
        if noteType == "hold" and parts[6] then
            local holdEnd = tonumber(parts[6]:match("^(%d+)")) or 0
            if holdEnd > 0 then
                holdTime = (holdEnd - tonumber(parts[3])) / 1000
            end
        end
        
        return {
            time = time,
            column = column,
            type = noteType,
            holdTime = holdTime
        }
    end
    
    return nil
end

-- Parsear formato StepMania (.sm)
function ChartParser:parseSM(content, path)
    local chart = {
        format = "sm",
        metadata = {},
        notes = {}
    }
    
    -- Extraer metadata
    for key in content:gmatch("#([^:]+):") do
        local value = content:match("#" .. key .. ":(.-);")
        if value then
            chart.metadata[key:lower()] = value:trim()
        end
    end
    
    -- Extraer notas
    local tracks = {"tap", "hold", "lift", "fake"}
    for _, track in ipairs(tracks) do
        local trackNotes = content:match("#" .. track .. ".*:(.-);")
        if trackNotes then
            self:parseSMNotes(trackNotes, chart.notes, track)
        end
    end
    
    -- Ordenar notas
    table.sort(chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    return chart
end

-- Parsear notas de StepMania
function ChartParser:parseSMNotes(trackNotes, notes, noteType)
    -- Convertir a filas (beat)
    local measure = 0
    local beat = 0
    
    for measureStr in trackNotes:gmatch("(%d+)") do
        local measureNum = tonumber(measureStr) or 0
        -- Convertir medida a tiempo
        local bpm = 120 -- BPM por defecto
        local time = (measure * 4 + beat) * (60 / bpm)
        
        table.insert(notes, {
            time = time,
            column = beat % 4 + 1,
            type = noteType,
            holdTime = 0
        })
        
        beat = beat + 1
        if beat >= 4 then
            beat = 0
            measure = measure + 1
        end
    end
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
        audioFile = chart.metadata.AudioFilename or chart.metadata.music or nil,
        title = chart.metadata.Title or chart.metadata.title or "Unknown",
        artist = chart.metadata.Artist or chart.metadata.artist or "Unknown"
    }
    
    for _, note in ipairs(chart.notes) do
        local column = note.column
        if columnCount then
            column = math.min(column, columnCount)
        end
        
        table.insert(internal.notes, {
            time = note.time + internal.offset,
            column = column,
            type = note.type,
            holdTime = note.holdTime
        })
    end
    
    return internal
end

-- Exportar a formato JSON
function ChartParser:exportToJSON(chart)
    return self.parsers.json(chart, "export")
end

return ChartParser