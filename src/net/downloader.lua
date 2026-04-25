--[[
    RITMINITY - Online Map Downloader (Mock)
    Simula la descarga de mapas online para integración futura
]]

local Downloader = {}
Downloader.__index = Downloader

-- Simulamos un catálogo de mapas
Downloader.mockCatalog = {
    {id = "1001", title = "Beethoven - Virus", artist = "Diana Boncheva", bpm = 160, difficulty = "Hard"},
    {id = "1002", title = "Freedom Dive", artist = "xi", bpm = 222.22, difficulty = "Insane"},
    {id = "1003", title = "Bad Apple!!", artist = "Alstroemeria Records", bpm = 138, difficulty = "Normal"}
}

function Downloader:new()
    local self = setmetatable({}, Downloader)
    self.downloads = {}
    return self
end

function Downloader:getOnlineMaps()
    return self.mockCatalog
end

function Downloader:downloadMap(mapId, onComplete, onError)
    -- Simulación asíncrona de descarga
    -- En el mundo real usaríamos un thread de love o una librería async HTTP
    
    local map = nil
    for _, m in ipairs(self.mockCatalog) do
        if m.id == mapId then
            map = m
            break
        end
    end
    
    if not map then
        if onError then onError("Map not found") end
        return
    end
    
    table.insert(self.downloads, {
        map = map,
        progress = 0,
        onComplete = onComplete,
        onError = onError
    })
end

function Downloader:update(dt)
    for i = #self.downloads, 1, -1 do
        local dl = self.downloads[i]
        -- Simular descarga de 2 segundos
        dl.progress = dl.progress + (dt * 0.5)
        
        if dl.progress >= 1.0 then
            -- Guardar mapa simulado en local
            local savePath = "assets/songs/" .. dl.map.title .. ".json"
            
            -- Crear un chart de prueba
            local chartData = {
                metadata = {
                    title = dl.map.title,
                    artist = dl.map.artist,
                    bpm = dl.map.bpm,
                    difficulty = dl.map.difficulty
                },
                notes = {
                    {time = 1.0, column = 1, type = "tap"},
                    {time = 1.5, column = 2, type = "tap"},
                    {time = 2.0, column = 3, type = "tap"},
                    {time = 2.5, column = 4, type = "tap"}
                }
            }
            
            local json = require("src.utils.json")
            if json then
                -- love.filesystem.write(savePath, json.encode(chartData))
                -- Para el mock, solo simulamos éxito
            end
            
            if dl.onComplete then
                dl.onComplete(savePath)
            end
            
            table.remove(self.downloads, i)
        end
    end
end

return Downloader
