--[[
    RITMINITY - Chart Editor
    Editor de mapas integrado para crear y editar charts
]]

local Editor = {}
Editor.__index = Editor

-- Estado del editor
Editor.state = {
    mode = "select", -- select, draw, erase, select, zoom
    tool = "tap", -- tap, hold, mine
    snap = 1/4, -- Snap de grid (1, 1/2, 1/4, 1/8, 1/16)
    zoom = 1.0,
    scrollX = 0,
    scrollY = 0,
    playhead = 0,
    isPlaying = false,
    isRecording = false
}

-- Chart actual
Editor.chart = {
    metadata = {
        title = "",
        artist = "",
        bpm = 120,
        offset = 0,
        difficulty = "Normal",
        columnCount = 4
    },
    notes = {},
    timingPoints = {},
    difficultySettings = {}
}

-- Notas seleccionadas
Editor.selectedNotes = {}

-- Historial para undo/redo
Editor.history = {
    undoStack = {},
    redoStack = {},
    maxSize = 50
}

-- Configuración de visualización
Editor.viewConfig = {
    columnWidth = 80,
    receptorHeight = 60,
    noteHeight = 20,
    hitLineY = 0,
    visibleTime = 5, -- Segundos visibles
    gridLines = true,
    showTiming = true,
    showJudgment = true
}

-- Audio
Editor.audioSource = nil
Editor.audioPath = ""

-- Notas temporales para preview
Editor.previewNotes = {}

-- Callbacks
Editor.callbacks = {
    onChartChange = nil,
    onCursorChange = nil,
    onSelectionChange = nil,
    onToolChange = nil
}

function Editor:new()
    local self = setmetatable({}, Editor)
    self:reset()
    return self
end

-- Resetear editor
function Editor:reset()
    self.state = {
        mode = "select",
        tool = "tap",
        snap = 1/4,
        zoom = 1.0,
        scrollX = 0,
        scrollY = 0,
        playhead = 0,
        isPlaying = false,
        isRecording = false
    }
    
    self.chart = {
        metadata = {
            title = "",
            artist = "",
            bpm = 120,
            offset = 0,
            difficulty = "Normal",
            columnCount = 4
        },
        notes = {},
        timingPoints = {},
        difficultySettings = {}
    }
    
    self.selectedNotes = {}
    self.history = {
        undoStack = {},
        redoStack = {},
        maxSize = 50
    }
    
    self.previewNotes = {}
end

-- Inicializar editor con chart existente
function Editor:initialize(chartData)
    if chartData then
        self.chart = chartData
    end
    
    self.viewConfig.hitLineY = love.graphics.getHeight() - 100
end

-- Cargar audio
function Editor:loadAudio(path)
    self.audioPath = path
    self.audioSource = love.audio.newSource(path, "stream")
    return self.audioSource ~= nil
end

-- Cargar chart desde archivo
function Editor:loadChart(path)
    local chartParser = require("src.chart.parser")
    local chartData = chartParser:load(path)
    
    if chartData then
        self.chart = chartData
        return true
    end
    
    return false
end

-- Guardar chart a archivo
function Editor:saveChart(path)
    local chartParser = require("src.chart.parser")
    return chartParser:save(self.chart, path)
end

-- Establecer modo del editor
function Editor:setMode(mode)
    self.state.mode = mode
    
    if mode == "draw" then
        self.state.tool = "tap"
    elseif mode == "erase" then
        -- No change
    end
    
    if self.callbacks.onToolChange then
        self.callbacks.onToolChange(mode, self.state.tool)
    end
end

-- Establecer herramienta
function Editor:setTool(tool)
    self.state.tool = tool
    
    if self.callbacks.onToolChange then
        self.callbacks.onToolChange(self.state.mode, tool)
    end
end

-- Establecer snap de grid
function Editor:setSnap(snap)
    self.state.snap = snap
end

-- Establecer BPM
function Editor:setBPM(bpm)
    self.chart.metadata.bpm = bpm
    
    -- Añadir timing point
    table.insert(self.chart.timingPoints, {
        time = 0,
        bpm = bpm,
        meter = 4
    })
end

-- Añadir nota en posición
function Editor:addNote(time, column, noteType, holdTime)
    -- Ajustar tiempo según snap
    time = self:snapTime(time)
    
    -- Verificar si ya existe una nota en este tiempo y columna
    if self:hasNoteAt(time, column) then
        return nil
    end
    
    local note = {
        time = time,
        column = column,
        type = noteType or self.state.tool,
        holdTime = holdTime or 0,
        hit = false,
        missed = false
    }
    
    -- Guardar estado para undo
    self:pushHistory("add", note)
    
    table.insert(self.chart.notes, note)
    
    -- Ordenar notas por tiempo
    table.sort(self.chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    if self.callbacks.onChartChange then
        self.callbacks.onChartChange(self.chart)
    end
    
    return note
end

-- Remover nota
function Editor:removeNote(note)
    for i, n in ipairs(self.chart.notes) do
        if n == note then
            self:pushHistory("remove", note)
            table.remove(self.chart.notes, i)
            
            if self.callbacks.onChartChange then
                self.callbacks.onChartChange(self.chart)
            end
            
            return true
        end
    end
    
    return false
end

-- Remover notas seleccionadas
function Editor:removeSelectedNotes()
    if #self.selectedNotes == 0 then
        return
    end
    
    self:pushHistory("batch_remove", self.selectedNotes)
    
    for _, note in ipairs(self.selectedNotes) do
        self:removeNote(note)
    end
    
    self.selectedNotes = {}
    
    if self.callbacks.onSelectionChange then
        self.callbacks.onSelectionChange(self.selectedNotes)
    end
end

-- Verificar si hay nota en posición
function Editor:hasNoteAt(time, column)
    for _, note in ipairs(self.chart.notes) do
        if math.abs(note.time - time) < 0.01 and note.column == column then
            return true
        end
    end
    return false
end

-- Ajustar tiempo según snap
function Editor:snapTime(time)
    return math.floor(time / self.state.snap + 0.5) * self.state.snap
end

-- Obtener nota en posición de pantalla
function Editor:getNoteAtPosition(x, y, currentTime)
    local hitLineY = self.viewConfig.hitLineY
    local visibleTime = self.viewConfig.visibleTime
    
    for _, note in ipairs(self.chart.notes) do
        local noteY = hitLineY - (note.time - currentTime) * self.state.zoom * 100
        
        if y >= noteY and y <= noteY + self.viewConfig.noteHeight then
            local columnWidth = self.viewConfig.columnWidth
            local column = math.floor(x / columnWidth) + 1
            
            if note.column == column then
                return note
            end
        end
    end
    
    return nil
end

-- Seleccionar nota
function Editor:selectNote(note)
    for _, n in ipairs(self.selectedNotes) do
        if n == note then
            return
        end
    end
    
    table.insert(self.selectedNotes, note)
    
    if self.callbacks onSelectionChange then
        self.callbacks:onSelectionChange(self.selectedNotes)
    end
end

-- Deseleccionar nota
function Editor:deselectNote(note)
    for i, n in ipairs(self.selectedNotes) do
        if n == note then
            table.remove(self.selectedNotes, i)
            break
        end
    end
end

-- Seleccionar todas las notas
function Editor:selectAll()
    self.selectedNotes = {}
    
    for _, note in ipairs(self.chart.notes) do
        table.insert(self.selectedNotes, note)
    end
end

-- Deseleccionar todo
function Editor:deselectAll()
    self.selectedNotes = {}
    
    if self.callbacks onSelectionChange then
        self.callbacks:onSelectionChange(self.selectedNotes)
    end
end

-- Mover notas seleccionadas
function Editor:moveSelectedNotes(deltaTime, deltaColumn)
    if #self.selectedNotes == 0 then
        return
    end
    
    self:pushHistory("move", self.selectedNotes)
    
    for _, note in ipairs(self.selectedNotes) do
        note.time = self:snapTime(note.time + deltaTime)
        note.column = math.max(1, math.min(self.chart.metadata.columnCount, note.column + deltaColumn))
    end
    
    -- Ordenar notas
    table.sort(self.chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    if self.callbacks onChartChange then
        self.callbacks:onChartChange(self.chart)
    end
end

-- Copiar notas seleccionadas
function Editor:copySelectedNotes()
    local copied = {}
    
    for _, note in ipairs(self.selectedNotes) do
        table.insert(copied, {
            time = note.time,
            column = note.column,
            type = note.type,
            holdTime = note.holdTime
        })
    end
    
    return copied
end

-- Pegar notas
function Editor:pasteNotes(copiedNotes, pasteTime)
    if not copiedNotes or #copiedNotes == 0 then
        return
    end
    
    local offset = 0
    if #copiedNotes > 0 then
        offset = pasteTime - copiedNotes[1].time
    end
    
    self:pushHistory("paste", copiedNotes)
    
    for _, noteData in ipairs(copiedNotes) do
        local newNote = {
            time = self:snapTime(noteData.time + offset),
            column = noteData.column,
            type = noteData.type,
            holdTime = noteData.holdTime,
            hit = false,
            missed = false
        }
        
        if not self:hasNoteAt(newNote.time, newNote.column) then
            table.insert(self.chart.notes, newNote)
        end
    end
    
    table.sort(self.chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    if self.callbacks onChartChange then
        self.callbacks:onChartChange(self.chart)
    end
end

-- Undo
function Editor:undo()
    if #self.history.undoStack == 0 then
        return false
    end
    
    local action = table.remove(self.history.undoStack)
    
    if action.type == "add" then
        -- Remover nota añadida
        for i, note in ipairs(self.chart.notes) do
            if note == action.data then
                table.remove(self.chart.notes, i)
                break
            end
        end
    elseif action.type == "remove" then
        -- Restaurar nota removida
        table.insert(self.chart.notes, action.data)
    elseif action.type == "move" then
        -- Revertir movimiento
        for _, note in ipairs(action.data) do
            note.time = note.time - action.deltaTime
            note.column = note.column - action.deltaColumn
        end
    elseif action.type == "batch_remove" then
        -- Restaurar notas removidas
        for _, noteData in ipairs(action.data) do
            table.insert(self.chart.notes, noteData)
        end
    end
    
    table.sort(self.chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    table.insert(self.history.redoStack, action)
    
    return true
end

-- Redo
function Editor:redo()
    if #self.history.redoStack == 0 then
        return false
    end
    
    local action = table.remove(self.history.redoStack)
    
    if action.type == "add" then
        table.insert(self.chart.notes, action.data)
    elseif action.type == "remove" then
        for i, note in ipairs(self.chart.notes) do
            if note == action.data then
                table.remove(self.chart.notes, i)
                break
            end
        end
    elseif action.type == "move" then
        for _, note in ipairs(action.data) do
            note.time = note.time + action.deltaTime
            note.column = note.column + action.deltaColumn
        end
    elseif action.type == "batch_remove" then
        -- Remover notas restauradas
        for _, noteData in ipairs(action.data) do
            for i, note in ipairs(self.chart.notes) do
                if note == noteData then
                    table.remove(self.chart.notes, i)
                    break
                end
            end
        end
    end
    
    table.sort(self.chart.notes, function(a, b)
        return a.time < b.time
    end)
    
    table.insert(self.history.undoStack, action)
    
    return true
end

-- Push history
function Editor:pushHistory(actionType, data)
    local action = {
        type = actionType,
        data = data,
        deltaTime = 0,
        deltaColumn = 0
    }
    
    table.insert(self.history.undoStack, action)
    
    -- Limitar tamaño del historial
    while #self.history.undoStack > self.history.maxSize do
        table.remove(self.history.undoStack, 1)
    end
    
    -- Limpiar redo stack
    self.history.redoStack = {}
end

-- Reproducir chart
function Editor:play()
    if self.audioSource then
        self.audioSource:play()
    end
    
    self.state.isPlaying = true
    self.state.playhead = 0
end

-- Pausar reproducción
function Editor:pause()
    if self.audioSource then
        self.audioSource:pause()
    end
    
    self.state.isPlaying = false
end

-- Detener reproducción
function Editor:stop()
    if self.audioSource then
        self.audioSource:stop()
    end
    
    self.state.isPlaying = false
    self.state.playhead = 0
end

-- Ir a posición específica
function Editor:seek(time)
    self.state.playhead = time
    
    if self.audioSource then
        self.audioSource:seek(time)
    end
end

-- Zoom in
function Editor:zoomIn()
    self.state.zoom = math.min(self.state.zoom * 1.2, 5.0)
end

-- Zoom out
function Editor:zoomOut()
    self.state.zoom = math.max(self.state.zoom / 1.2, 0.2)
end

-- Scroll horizontal
function Editor:scrollX(delta)
    self.state.scrollX = self.state.scrollX + delta
end

-- Scroll vertical
function Editor:scrollY(delta)
    self.state.scrollY = self.state.scrollY + delta
end

-- Actualizar
function Editor:update(dt)
    if self.state.isPlaying then
        self.state.playhead = self.state.playhead + dt
        
        if self.audioSource then
            self.state.playhead = self.audioSource:tell()
        end
    end
end

-- Renderizar editor
function Editor:draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    
    -- Dibujar columnas
    self:drawColumns()
    
    -- Dibujar grid
    if self.viewConfig.gridLines then
        self:drawGrid()
    end
    
    -- Dibujar línea de hit
    self:drawHitLine()
    
    -- Dibujar notas
    self:drawNotes()
    
    -- Dibujar receptor
    self:drawReceptors()
    
    -- Dibujar playhead
    self:drawPlayhead()
    
    -- Dibujar UI del editor
    self:drawUI()
end

-- Dibujar columnas
function Editor:drawColumns()
    local columnCount = self.chart.metadata.columnCount
    local columnWidth = self.viewConfig.columnWidth
    
    for i = 1, columnCount do
        local x = (i - 1) * columnWidth
        
        -- Color de columna alternado
        if i % 2 == 1 then
            love.graphics.setColor(0.1, 0.1, 0.15, 1)
        else
            love.graphics.setColor(0.08, 0.08, 0.12, 1)
        end
        
        love.graphics.rectangle("fill", x, 0, columnWidth, love.graphics.getHeight())
        
        -- Línea separadora
        love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.line(x, 0, x, love.graphics.getHeight())
    end
end

-- Dibujar grid
function Editor:drawGrid()
    local bpm = self.chart.metadata.bpm
    local beatDuration = 60 / bpm
    local columnWidth = self.viewConfig.columnWidth
    local columnCount = self.chart.metadata.columnCount
    
    love.graphics.setColor(0.3, 0.3, 0.4, 0.3)
    love.graphics.setLineWidth(1)
    
    -- Líneas de beat
    local startTime = self.state.playhead - 2
    local endTime = self.state.playhead + self.viewConfig.visibleTime
    
    for t = startTime, endTime, beatDuration do
        local y = self.viewConfig.hitLineY - (t - self.state.playhead) * self.state.zoom * 100
        
        if y > 0 and y < love.graphics.getHeight() then
            love.graphics.line(0, y, columnCount * columnWidth, y)
        end
    end
    
    -- Líneas de compás
    for t = startTime, endTime, beatDuration * 4 do
        local y = self.viewConfig.hitLineY - (t - self.state.playhead) * self.state.zoom * 100
        
        if y > 0 and y < love.graphics.getHeight() then
            love.graphics.setColor(0.4, 0.4, 0.5, 0.5)
            love.graphics.line(0, y, columnCount * columnWidth, y)
        end
    end
end

-- Dibujar línea de hit
function Editor:drawHitLine()
    local y = self.viewConfig.hitLineY
    local columnCount = self.chart.metadata.columnCount
    local columnWidth = self.viewConfig.columnWidth
    
    love.graphics.setColor(1, 0.3, 0.3, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, y, columnCount * columnWidth, y)
end

-- Dibujar notas
function Editor:drawNotes()
    local currentTime = self.state.playhead
    local hitLineY = self.viewConfig.hitLineY
    local columnWidth = self.viewConfig.columnWidth
    local noteHeight = self.viewConfig.noteHeight
    
    for _, note in ipairs(self.chart.notes) do
        local noteY = hitLineY - (note.time - currentTime) * self.state.zoom * 100
        
        -- Verificar si está visible
        if noteY > -noteHeight and noteY < love.graphics.getHeight() then
            local x = (note.column - 1) * columnWidth
            
            -- Color según tipo de nota
            local color = {1, 1, 1, 1}
            if note.type == "hold" then
                color = {0.3, 0.7, 1, 1}
            elseif note.type == "mine" then
                color = {1, 0.3, 0.3, 1}
            end
            
            -- Verificar si está seleccionada
            for _, selected in ipairs(self.selectedNotes) do
                if selected == note then
                    color = {1, 1, 0, 1}
                    break
                end
            end
            
            love.graphics.setColor(color)
            
            if note.type == "hold" and note.holdTime > 0 then
                -- Dibujar hold
                local holdLength = note.holdTime * self.state.zoom * 100
                love.graphics.rectangle("fill", x + 5, noteY - holdLength, columnWidth - 10, holdLength)
            else
                -- Dibujar tap
                love.graphics.rectangle("fill", x + 5, noteY, columnWidth - 10, noteHeight)
            end
        end
    end
end

-- Dibujar receptores
function Editor:drawReceptors()
    local hitLineY = self.viewConfig.hitLineY
    local columnWidth = self.viewConfig.columnWidth
    local receptorHeight = self.viewConfig.receptorHeight
    local columnCount = self.chart.metadata.columnCount
    
    for i = 1, columnCount do
        local x = (i - 1) * columnWidth + columnWidth / 2
        
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", x, hitLineY, receptorHeight / 2)
    end
end

-- Dibujar playhead
function Editor:drawPlayhead()
    local y = self.viewConfig.hitLineY
    
    love.graphics.setColor(1, 0.3, 0.3, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, y, love.graphics.getWidth(), y)
end

-- Dibujar UI del editor
function Editor:drawUI()
    -- Toolbar
    self:drawToolbar()
    
    -- Info bar
    self:drawInfoBar()
end

-- Dibujar toolbar
function Editor:drawToolbar()
    local width = love.graphics.getWidth()
    local toolbarY = 10
    local buttonWidth = 60
    local buttonHeight = 30
    local spacing = 5
    
    local tools = {"Select", "Draw", "Erase", "Zoom"}
    local toolModes = {"select", "draw", "erase", "zoom"}
    
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", 10, toolbarY, #tools * (buttonWidth + spacing), buttonHeight + 10)
    
    for i, tool in ipairs(tools) do
        local x = 15 + (i - 1) * (buttonWidth + spacing)
        local y = toolbarY + 5
        
        -- Resaltar herramienta actual
        if self.state.mode == toolModes[i] then
            love.graphics.setColor(0.3, 0.5, 0.8, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.35, 1)
        end
        
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight)
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(tool, x, y + 8, buttonWidth, "center")
    end
end

-- Dibujar info bar
function Editor:drawInfoBar()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", 0, height - 40, width, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    
    local info = string.format(
        "Time: %.2f | BPM: %d | Notes: %d | Zoom: %.1fx",
        self.state.playhead,
        self.chart.metadata.bpm,
        #self.chart.notes,
        self.state.zoom
    )
    
    love.graphics.printf(info, 20, height - 30, width - 40, "left")
end

-- Manejar click del mouse
function Editor:mousePressed(x, y, button)
    if button == "l" then
        if self.state.mode == "draw" then
            -- Añadir nota
            local time = self:getTimeFromY(y)
            local column = self:getColumnFromX(x)
            
            self:addNote(time, column, self.state.tool)
        elseif self.state.mode == "erase" then
            -- Remover nota
            local note = self:getNoteAtPosition(x, y, self.state.playhead)
            if note then
                self:removeNote(note)
            end
        elseif self.state.mode == "select" then
            -- Seleccionar nota
            local note = self:getNoteAtPosition(x, y, self.state.playhead)
            if note then
                self:selectNote(note)
            else
                self:deselectAll()
            end
        end
    end
end

-- Manejar liberación de mouse
function Editor:mouseReleased(x, y, button)
    -- Por implementar
end

-- Manejar movimiento de mouse
function Editor:mouseMoved(x, y, dx, dy)
    if self.state.mode == "draw" and love.mouse.isDown("l") then
        -- Añadir nota en movimiento
        local time = self:getTimeFromY(y)
        local column = self:getColumnFromX(x)
        
        self:addNote(time, column, self.state.tool)
    end
end

-- Manejar scroll del mouse
function Editor:wheelMoved(x, y)
    if y > 0 then
        self:zoomIn()
    elseif y < 0 then
        self:zoomOut()
    end
end

-- Obtener tiempo desde posición Y
function Editor:getTimeFromY(y)
    local hitLineY = self.viewConfig.hitLineY
    local deltaY = hitLineY - y
    local time = self.state.playhead + (deltaY / (self.state.zoom * 100))
    
    return self:snapTime(time)
end

-- Obtener columna desde posición X
function Editor:getColumnFromX(x)
    local columnWidth = self.viewConfig.columnWidth
    local column = math.floor(x / columnWidth) + 1
    
    return math.max(1, math.min(self.chart.metadata.columnCount, column))
end

-- Manejar teclado
function Editor:keyPressed(key)
    if key == "space" then
        if self.state.isPlaying then
            self:pause()
        else
            self:play()
        end
    elseif key == "escape" then
        self:stop()
    elseif key == "z" and love.keyboard.isDown("lctrl") then
        self:undo()
    elseif key == "y" and love.keyboard.isDown("lctrl") then
        self:redo()
    elseif key == "a" and love.keyboard.isDown("lctrl") then
        self:selectAll()
    elseif key == "delete" or key == "backspace2" then
        self:removeSelectedNotes()
    elseif key == "1" then
        self:setTool("tap")
    elseif key == "2" then
        self:setTool("hold")
    elseif key == "3" then
        self:setTool("mine")
    elseif key == "q" then
        self:setSnap(1)
    elseif key == "w" then
        self:setSnap(1/2)
    elseif key == "e" then
        self:setSnap(1/4)
    elseif key == "r" then
        self:setSnap(1/8)
    elseif key == "t" then
        self:setSnap(1/16)
    end
end

-- Obtener chart
function Editor:getChart()
    return self.chart
end

-- Obtener estado
function Editor:getState()
    return self.state
end

-- Obtener notas
function Editor:getNotes()
    return self.chart.notes
end

-- Obtener metadata
function Editor:getMetadata()
    return self.chart.metadata
end

-- Establecer metadata
function Editor:setMetadata(key, value)
    self.chart.metadata[key] = value
end

-- Obtener configuración de vista
function Editor:getViewConfig()
    return self.viewConfig
end

-- Establecer configuración de vista
function Editor:setViewConfig(config)
    for k, v in pairs(config) do
        self.viewConfig[k] = v
    end
end

return Editor