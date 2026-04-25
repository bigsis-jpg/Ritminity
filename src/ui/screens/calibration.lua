--[[
    RITMINITY - Offset Calibration Screen
    Pantalla para calibrar la latencia de audio
]]

local StateManager = require("src.core.state")
local AudioManager = require("src.managers.audio_manager")

local Calibration = {}
Calibration.__index = Calibration

function Calibration:init()
    self.beats = {}
    self.offsets = {}
    self.avgOffset = 0
    self.lastHit = 0
    self.bpm = 120
    self.beatInterval = 60 / self.bpm
    self.currentTime = 0
    self.totalBeats = 16
    self.currentBeatCount = 0
    
    self.font = love.graphics.newFont(24)
    self.bigFont = love.graphics.newFont(48)
end

function Calibration:enter(params)
    self.currentTime = -1 -- Pre-roll de 1 segundo
    self.currentBeatCount = 0
    self.offsets = {}
    self.avgOffset = 0
    
    -- Cargar sonido de metrónomo
    self.metronome = AudioManager:loadSound("assets/sounds/hitsound.wav")
end

function Calibration:update(dt)
    self.currentTime = self.currentTime + dt
    
    -- Disparar metrónomo
    local nextBeatTime = self.currentBeatCount * self.beatInterval
    if self.currentTime >= nextBeatTime then
        local SampleManager = require("src.managers.sample_manager")
        SampleManager:playSample("soft-hitnormal")
        self.currentBeatCount = self.currentBeatCount + 1
    end
    
    -- Si ya pasamos los beats, calcular promedio
    if self.currentBeatCount > self.totalBeats + 1 then
        -- Finalizado
    end
end

function Calibration:draw()
    love.graphics.clear(0.05, 0.05, 0.1)
    
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("CALIBRACIÓN DE OFFSET", 0, 100, 1280, "center")
    love.graphics.printf("Presiona ESPACIO siguiendo el ritmo del metrónomo", 0, 150, 1280, "center")
    
    -- Círculo de ritmo
    local beatProgress = (self.currentTime % self.beatInterval) / self.beatInterval
    local size = 100 + (1 - beatProgress) * 50
    love.graphics.setColor(0.3, 0.6, 1, 0.5)
    love.graphics.circle("line", 640, 360, size)
    love.graphics.circle("fill", 640, 360, 50)
    
    -- Resultados
    love.graphics.setFont(self.font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Offset Recomendado: " .. math.floor(self.avgOffset) .. " ms", 0, 500, 1280, "center")
    love.graphics.printf("Intentos: " .. #self.offsets .. " / " .. self.totalBeats, 0, 550, 1280, "center")
    
    -- Historial de offsets
    for i, off in ipairs(self.offsets) do
        local x = 640 + off * 2
        love.graphics.setColor(off > 0 and {1,0.5,0.5} or {0.5,1,0.5})
        love.graphics.line(x, 420, x, 440)
    end
    
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.line(640, 410, 640, 450) -- Centro
    
    love.graphics.printf("ESC para volver y aplicar", 0, 650, 1280, "center")
end

function Calibration:handleInput(key)
    if key == "space" then
        -- Calcular diferencia con el beat más cercano
        local targetBeat = math.floor(self.currentTime / self.beatInterval + 0.5)
        local targetTime = targetBeat * self.beatInterval
        local diff = (self.currentTime - targetTime) * 1000 -- ms
        
        table.insert(self.offsets, diff)
        
        -- Recalcular promedio
        local sum = 0
        for _, off in ipairs(self.offsets) do sum = sum + off end
        self.avgOffset = sum / #self.offsets
        
    elseif key == "escape" then
        -- Aplicar offset global (podría guardarse en config)
        StateManager:change("settings", {newOffset = self.avgOffset})
    end
end

return Calibration
