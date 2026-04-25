--[[
    RITMINITY - Editor Screen
    Editor de mapas integrado
]]

local StateManager = require("src.core.state")

-- Usar pcall para manejar módulos opcionales
local json_ok, json = pcall(require, "src.utils.json")

local Editor = {}
Editor.__index = Editor

-- Estado del editor
Editor.mode = "select" -- select, edit, preview
Editor.selectedTool = "tap"
Editor.selectedColumn = 1
Editor.currentTime = 0
Editor.zoom = 1.0
Editor.snap = 1/4 -- 4th notes
Editor.chartPath = "" -- Ruta del chart guardado
Editor.isModified = false -- Si el chart ha sido modificado desde el último guardado

-- Notas en el editor
Editor.notes = {}
Editor.selectedNotes = {}

-- Canción
Editor.song = nil
Editor.chart = nil

-- UI
Editor.showGrid = true
Editor.showTimeline = true

function Editor:init()
end

function Editor:enter(params)
    self.mode = "select"
    self.selectedTool = "tap"
    self.selectedColumn = 1
    self.currentTime = 0
    self.notes = {}
    self.selectedNotes = {}
    
    -- Cargar canción si se proporciona
    if params and params.song then
        self.song = params.song
    else
        self.song = {title = "New Chart", bpm = 120}
    end
    
    self.chart = {
        metadata = {
            title = self.song.title,
            bpm = self.song.bpm,
            offset = 0
        },
        notes = {}
    }
end

function Editor:exit()
    -- Preguntar si guardar cambios antes de salir
    if self.isModified then
        -- En una implementación real, mostraría un diálogo de confirmación
        -- Por ahora, simplemente guardamos automáticamente
        self:saveChart()
    end
end

function Editor:update(dt)
    if self.mode == "preview" then
        self.currentTime = self.currentTime + dt
    end
end

function Editor:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Chart Editor - " .. (self.song and self.song.title or "New"), 640, 30, 0, "center")
    
    -- Grid de edición
    self:drawGrid()
    
    -- Notas
    self:drawNotes()
    
    -- Timeline
    if self.showTimeline then
        self:drawTimeline()
    end
    
    -- Toolbar
    self:drawToolbar()
    
    -- Info
    self:drawInfo()
end

function Editor:drawGrid()
    local columnWidth = 200
    local totalWidth = self.columnCount or 4 * columnWidth
    local startX = (1280 - totalWidth) / 2
    local hitPosition = 650
    
    -- Columnas
    for i = 1, (self.columnCount or 4) do
        local x = startX + (i - 1) * columnWidth
        
        love.graphics.setColor(0.15, 0.15, 0.2, 1)
        love.graphics.rectangle("fill", x, 0, columnWidth, 720)
        
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
        love.graphics.setLineWidth(1)
        love.graphics.line(x, 0, x, 720)
    end
    
    -- Línea de hit
    love.graphics.setColor(1, 0.5, 0, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.line(startX, hitPosition, startX + totalWidth, hitPosition)
end

function Editor:drawNotes()
    local columnWidth = 200
    local startX = (1280 - ((self.columnCount or 4) * columnWidth)) / 2
    local hitPosition = 650
    local scrollSpeed = 600
    
    for _, note in ipairs(self.notes) do
        local x = startX + (note.column - 1) * columnWidth + columnWidth / 2
        local y = hitPosition - (note.time - self.currentTime) * scrollSpeed
        
        if y < 0 or y > 720 then
            goto continue
        end
        
        -- Verificar si está seleccionada
        local isSelected = false
        for _, selNote in ipairs(self.selectedNotes) do
            if selNote == note then
                isSelected = true
                break
            end
        end
        
        if isSelected then
            love.graphics.setColor(1, 0.5, 0, 1)
        else
            love.graphics.setColor(0.2, 0.6, 1, 1)
        end
        
        love.graphics.rectangle("fill", x - 80, y - 15, 160, 30)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line", x - 80, y - 15, 160, 30)
        
        ::continue::
    end
end

function Editor:drawTimeline()
    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", 0, 650, 1280, 70)
    
    -- Marcador de tiempo actual
    local timeX = 640
    love.graphics.setColor(1, 0.5, 0, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(timeX, 650, timeX, 720)
    
    -- Tiempo
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(string.format("%.2f", self.currentTime), timeX + 10, 660, 0, "left")
end

function Editor:drawToolbar()
    local tools = {"tap", "hold", "delete", "select"}
    local toolLabels = {tap = "Tap", hold = "Hold", delete = "Del", select = "Sel"}
    
    local startX = 50
    local y = 50
    
    love.graphics.setFont(love.graphics.newFont(16))
    
    for i, tool in ipairs(tools) do
        local x = startX + (i - 1) * 80
        
        if tool == self.selectedTool then
            love.graphics.setColor(0.2, 0.6, 1, 1)
            love.graphics.rectangle("fill", x, y, 70, 30)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", x, y, 70, 30)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(toolLabels[tool], x + 35, y + 8, 0, "center")
    end
    
    -- Snap
    local snaps = {1, 2, 4, 8, 16}
    local snapLabels = {"1/1", "1/2", "1/4", "1/8", "1/16"}
    
    startX = 50
    y = 100
    
    for i, snap in ipairs(snaps) do
        local x = startX + (i - 1) * 60
        
        love.graphics.setColor(0.2, 0.2, 0.2, 1)
        love.graphics.rectangle("fill", x, y, 50, 25)
        
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.printf(snapLabels[i], x + 25, y + 6, 0, "center")
    end
end

function Editor:drawInfo()
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Notes: " .. #self.notes, 50, 680, 0, "left")
    love.graphics.printf("BPM: " .. (self.song and self.song.bpm or 120), 50, 700, 0, "left")
    love.graphics.printf("Path: " .. (self.chartPath ~= "" and self.chartPath or "Sin guardar"), 50, 720, 0, "left")
    
    local status = self.isModified and "[MODIFICADO]" or "[GUARDADO]"
    love.graphics.setColor(self.isModified and {1, 0.5, 0.5} or {0.5, 1, 0.5}, 1)
    love.graphics.printf(status, 1230, 680, 0, "right")
    
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.printf("Space: Play/Pause  |  Enter: Add Note  |  Delete: Remove  |  Ctrl+S: Guardar  |  Ctrl+O: Cargar", 640, 700, 0, "center")
end

function Editor:onEscape()
    StateManager:change("mainmenu")
end

function Editor:handleInput(key)
    if key == "space" then
        self.mode = (self.mode == "preview") and "select" or "preview"
    elseif key == "return" or key == "enter" then
        self:addNote()
    elseif key == "delete" or key == "backspace" then
        self:deleteSelectedNotes()
    elseif key == "s" and love.keyboard.isDown("lctrl", "rctrl") then
        self:saveChart()
    elseif key == "o" and love.keyboard.isDown("lctrl", "rctrl") then
        self:loadChart()
    elseif key == "1" then
        self.selectedColumn = 1
    elseif key == "2" then
        self.selectedColumn = 2
    elseif key == "3" then
        self.selectedColumn = 3
    elseif key == "4" then
        self.selectedColumn = 4
    end
end

function Editor:addNote()
    local note = {
        time = self.currentTime,
        column = self.selectedColumn,
        type = self.selectedTool,
        holdTime = 0
    }
    table.insert(self.notes, note)
end

function Editor:deleteSelectedNotes()
    for _, note in ipairs(self.selectedNotes) do
        for i, n in ipairs(self.notes) do
            if n == note then
                table.remove(self.notes, i)
                break
            end
        end
    end
    self.selectedNotes = {}
end

function Editor:saveChart()
    if not self.song then
        return false, "No song loaded"
    end
    
    -- Generar nombre de archivo si no existe
    if self.chartPath == "" then
        local safeTitle = self.song.title:gsub("[^%w%s]", ""):gsub("%s+", "_")
        local safeArtist = (self.song.artist or "Unknown"):gsub("[^%w%s]", ""):gsub("%s+", "_")
        self.chartPath = string.format("assets/charts/%s_%s_%d.json", safeTitle, safeArtist, os.time())
    end
    
    -- Preparar datos del chart
    local chartData = {
        metadata = {
            title = self.song.title,
            artist = self.song.artist or "",
            bpm = self.song.bpm or 120,
            offset = 0
        },
        notes = {}
    }
    
    -- Convertir notas al formato de exportación
    for _, note in ipairs(self.notes) do
        table.insert(chartData.notes, {
            time = note.time,
            column = note.column,
            type = note.type,
            holdTime = note.holdTime or 0
        })
    end
    
    -- Intentar guardar el archivo
    local success, message = pcall(function()
        local json = require("src.utils.json")
        local jsonData = json.encode(chartData)
        love.filesystem.write(self.chartPath, jsonData)
    end)
    
    if success then
        self.isModified = false
        return true, "Chart saved successfully to " .. self.chartPath
    else
        return false, "Failed to save chart: " .. tostring(message)
    end
end

function Editor:loadChart(path)
    path = path or love.filesystem.openDialog("Select chart file", "json")
    if not path then
        return false, "No file selected"
    end
    
    local file = love.filesystem.newFile(path)
    if not file then
        return false, "Could not open file"
    end
    
    file:open("r")
    local content = file:read()
    file:close()
    
    -- Parsear el chart
    local ChartParser = require("src.loaders.chart_parser")
    local parser = ChartParser:new()
    local chartData, err = parser:parseFile(path)
    
    if not chartData then
        return false, "Failed to parse chart: " .. err
    end
    
    -- Actualizar estado del editor
    self.chartPath = path
    self.isModified = false
    
    -- Actualizar canción
    self.song = {
        title = chartData.metadata.title or "Untitled",
        artist = chartData.metadata.artist or "",
        bpm = chartData.metadata.bpm or 120
    }
    
    -- Limpiar notas existentes
    self.notes = {}
    
    -- Añadir notas del chart
    for _, note in ipairs(chartData.notes) do
        table.insert(self.notes, {
            time = note.time,
            column = note.column,
            type = note.type or "tap",
            holdTime = note.holdTime or 0
        })
    end
    
    -- Ordenar notas por tiempo
    table.sort(self.notes, function(a, b)
        return a.time < b.time
    end)
    
    return true, "Chart loaded successfully from " .. path
end

return Editor