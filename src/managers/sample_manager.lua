--[[
    RITMINITY - Sample Manager
    Maneja la carga y reproducción de hitsounds dinámicos (osu! style)
]]

local SampleManager = {}
SampleManager.__index = SampleManager

function SampleManager:new()
    local self = setmetatable({}, SampleManager)
    self.samples = {}
    self.songPath = ""
    return self
end

function SampleManager:setSongPath(path)
    -- Obtener el directorio de la canción
    self.songPath = path:match("(.*[/\\])") or ""
    self:clear()
end

function SampleManager:clear()
    self.samples = {}
end

function SampleManager:playHitSound(hitSoundBit, sampleInfo, timingPoint)
    local AudioManager = require("src.managers.audio_manager")
    
    -- Parsear sampleInfo: "sampleset:additions:index:volume:filename"
    local sSet, sAdd, sIdx, sVol, sFile = 0, 0, 0, 0, ""
    if sampleInfo and sampleInfo ~= "" then
        sSet, sAdd, sIdx, sVol, sFile = sampleInfo:match("(%d+):(%d+):(%d+):(%d+):(.*)")
        sSet = tonumber(sSet) or 0
        sAdd = tonumber(sAdd) or 0
        sVol = tonumber(sVol) or 0
    end

    -- Herencia de Timing Point (Osu Style)
    if sSet == 0 and timingPoint then
        sSet = timingPoint.sampleSet or 1
    end
    if sVol == 0 and timingPoint then
        sVol = timingPoint.volume or 100
    end
    
    local finalVolume = (sVol / 100) * 0.6

    -- Si hay un sFile personalizado, cargarlo y reproducirlo
    if sFile and sFile ~= "" then
        self:playFile(sFile, sVol)
        return
    end

    -- Mapeo de SampleSets (1: Normal, 2: Soft, 3: Drum)
    local setNames = {"normal", "soft", "drum"}
    local setName = setNames[sSet] or "normal"
    local addName = setNames[sAdd] or setName

    -- 1. Hit Normal (Bitmask 0 o 1)
    self:playSample(setName .. "-hitnormal", finalVolume)

    -- 2. Whistle (Bit 2 = 2)
    if bit.band(hitSoundBit, 2) > 0 then
        self:playSample(addName .. "-hitwhistle", finalVolume)
    end

    -- 3. Finish (Bit 4 = 4)
    if bit.band(hitSoundBit, 4) > 0 then
        self:playSample(addName .. "-hitfinish", finalVolume)
    end

    -- 4. Clap (Bit 8 = 8)
    if bit.band(hitSoundBit, 8) > 0 then
        self:playSample(addName .. "-hitclap", finalVolume)
    end
end

function SampleManager:playSample(name, volume)
    local AudioManager = require("src.managers.audio_manager")
    local path = self.songPath .. name .. ".wav"
    
    -- Si no existe en la carpeta de la canción, usar el default
    if not love.filesystem.getInfo(path) then
        path = "assets/sounds/hitsounds/" .. name .. ".wav"
    end

    if not self.samples[path] then
        if love.filesystem.getInfo(path) then
            self.samples[path] = AudioManager:loadSound(path)
        else
            -- Fallback total
            return
        end
    end

    if self.samples[path] then
        AudioManager:playSound(self.samples[path], volume or 0.6)
    end
end

function SampleManager:playFile(filename, volume)
    local AudioManager = require("src.managers.audio_manager")
    local path = self.songPath .. filename
    
    if not self.samples[path] then
        if love.filesystem.getInfo(path) then
            self.samples[path] = AudioManager:loadSound(path)
        end
    end

    if self.samples[path] then
        local vol = (tonumber(volume) or 100) / 100
        AudioManager:playSound(self.samples[path], vol * 0.6)
    end
end

return SampleManager:new()
