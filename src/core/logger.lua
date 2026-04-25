--[[
    RITMINITY - Core Logger System
    Sistema de logging profesional con múltiples niveles
]]

local Logger = {}
Logger.__index = Logger

-- Niveles de log
local LOG_LEVELS = {
    trace = 0,
    debug = 1,
    info = 2,
    warn = 3,
    error = 4
}

-- Colores para cada nivel
local LOG_COLORS = {
    trace = {0.5, 0.5, 0.5},
    debug = {0.5, 0.5, 1},
    info = {0.5, 1, 0.5},
    warn = {1, 1, 0.5},
    error = {1, 0.5, 0.5}
}

function Logger.new()
    local self = setmetatable({}, Logger)
    self.level = LOG_LEVELS.info
    self.logs = {}
    self.maxLogs = 1000
    self.fileEnabled = true
    self.consoleEnabled = true
    self.currentLevel = "info"
    return self
end

function Logger:setLevel(level)
    self.level = LOG_LEVELS[level] or LOG_LEVELS.info
    self.currentLevel = level
end

function Logger:shouldLog(level)
    return LOG_LEVELS[level] >= self.level
end

function Logger:formatMessage(level, message, ...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local formatted = string.format(message, ...)
    return string.format("[%s] [%s] %s", timestamp:upper(), level:upper(), formatted)
end

function Logger:log(level, message, ...)
    if not self:shouldLog(level) then
        return
    end
    
    local formatted = self:formatMessage(level, message, ...)
    
    -- Agregar a memoria
    table.insert(self.logs, {
        level = level,
        message = formatted,
        timestamp = os.time()
    })
    
    -- Limitar logs en memoria
    while #self.logs > self.maxLogs do
        table.remove(self.logs, 1)
    end
    
    -- Imprimir a consola
    if self.consoleEnabled then
        print(formatted)
    end
    
    -- Escribir a archivo
    if self.fileEnabled then
        self:writeToFile(formatted)
    end
end

function Logger:writeToFile(message)
    -- Implementación diferida para evitar bloqueos
    -- En producción, usarías love.thread o escritura asíncrona
end

-- Métodos de conveniencia para cada nivel
function Logger:trace(message, ...)
    self:log("trace", message, ...)
end

function Logger:debug(message, ...)
    self:log("debug", message, ...)
end

function Logger:info(message, ...)
    self:log("info", message, ...)
end

function Logger:warn(message, ...)
    self:log("warn", message, ...)
end

function Logger:error(message, ...)
    self:log("error", message, ...)
end

-- Obtener logs recientes
function Logger:getRecentLogs(count)
    count = count or 100
    local start = math.max(1, #self.logs - count + 1)
    local result = {}
    for i = start, #self.logs do
        table.insert(result, self.logs[i])
    end
    return result
end

-- Obtener logs por nivel
function Logger:getLogsByLevel(level)
    local result = {}
    for _, log in ipairs(self.logs) do
        if log.level == level then
            table.insert(result, log)
        end
    end
    return result
end

-- Limpiar logs
function Logger:clear()
    self.logs = {}
end

-- Exportar
return Logger