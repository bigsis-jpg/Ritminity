--[[
    RITMINITY - Multiplayer Screen
    Pantalla de multiplayer
]]

local StateManager = require("src.core.state")

local Multiplayer = {}
Multiplayer.__index = Multiplayer

-- Estado
Multiplayer.mode = "menu" -- menu, lobby, connecting
Multiplayer.selectedIndex = 1
Multiplayer.lobbies = {}
Multiplayer.currentLobby = nil

-- Opciones
Multiplayer.options = {
    {id = "create", label = "Create Lobby", description = "Create a new game room"},
    {id = "join", label = "Join Lobby", description = "Join an existing game room"},
    {id = "direct", label = "Direct Connect", description = "Connect to IP address"}
}

function Multiplayer:init()
end

function Multiplayer:enter(params)
    self.mode = "menu"
    self.selectedIndex = 1
    self.currentLobby = nil
    
    -- Cargar lobbies disponibles (simulado)
    self.lobbies = {
        {
            id = 1, 
            name = "Test Room 1", 
            players = {
                {name = "User123", ready = true},
                {name = "Player2", ready = false}
            }, 
            maxPlayers = 8, 
            ping = 50
        },
        {
            id = 2, 
            name = "Practice Room", 
            players = {
                {name = "Newbie", ready = false}
            }, 
            maxPlayers = 4, 
            ping = 30
        }
    }
end

function Multiplayer:exit()
end

function Multiplayer:update(dt)
end

function Multiplayer:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(30))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Multijugador", 0, 50, 1280, "center")
    
    if self.mode == "menu" then
        self:drawMenu()
    elseif self.mode == "lobby" then
        self:drawLobby()
    elseif self.mode == "browse" then
        self:drawBrowser()
    end
end

function Multiplayer:drawMenu()
    local startY = 200
    
    for i, option in ipairs(self.options) do
        local y = startY + (i - 1) * 80
        local selected = (i == self.selectedIndex)
        
        if selected then
            love.graphics.setColor(0.2, 0.6, 1, 0.3)
            love.graphics.rectangle("fill", 340, y, 600, 70)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", 340, y, 600, 70)
        else
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 350, y + 5, 580, 60)
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("line", 350, y + 5, 580, 60)
        end
        
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(option.label, 0, y + 20, 1280, "center")
        
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.printf(option.description, 0, y + 45, 1280, "center")
    end
    
    -- Info
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.printf("↑↓/Mouse: Navegar  |  Enter/Clic: Seleccionar  |  Esc: Volver", 0, 680, 1280, "center")
end

function Multiplayer:drawBrowser()
    -- Lista de lobbies
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Salas Disponibles", 0, 150, 1280, "center")
    
    local startY = 200
    
    for i, lobby in ipairs(self.lobbies) do
        local y = startY + (i - 1) * 60
        local selected = (i == self.selectedIndex)
        
        if selected then
            love.graphics.setColor(0.2, 0.6, 1, 0.3)
            love.graphics.rectangle("fill", 200, y, 880, 50)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", 200, y, 880, 50)
        else
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 210, y + 5, 860, 40)
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("line", 210, y + 5, 860, 40)
        end
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(lobby.name, 250, y + 15)
        
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print(#lobby.players .. "/" .. lobby.maxPlayers, 900, y + 15)
        love.graphics.print(lobby.ping .. "ms", 1000, y + 15)
    end
    
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.printf("Enter/Clic: Unirse  |  Esc: Volver", 0, 680, 1280, "center")
end

function Multiplayer:drawLobby()
    if not self.currentLobby then
        return
    end
    
    -- Info del lobby
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Lobby: " .. self.currentLobby.name, 640, 150, 0, "center")
    
    -- Jugadores
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("Players (" .. #self.currentLobby.players .. "/" .. self.currentLobby.maxPlayers .. ")", 640, 200, 0, "center")
    
    for i, player in ipairs(self.currentLobby.players) do
        local y = 250 + (i - 1) * 40
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(player.name, 640, y, 0, "center")
        
        if player.ready then
            love.graphics.setColor(0.2, 1, 0.2, 1)
            love.graphics.printf("Ready", 640, y + 20, 0, "center")
        else
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.printf("Not Ready", 640, y + 20, 0, "center")
        end
    end
    
    -- Opciones
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Space: Toggle Ready  |  Enter: Start  |  Esc: Leave", 640, 650, 0, "center")
end

function Multiplayer:onEscape()
    if self.mode == "lobby" then
        self.currentLobby = nil
        self.mode = "menu"
    else
        StateManager:change("mainmenu")
    end
end

function Multiplayer:handleInput(key)
    if self.mode == "menu" then
        if key == "up" or key == "w" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then
                self.selectedIndex = #self.options
            end
        elseif key == "down" or key == "s" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.options then
                self.selectedIndex = 1
            end
        elseif key == "return" or key == "enter" then
            self:selectOption(self.options[self.selectedIndex].id)
        end
    elseif self.mode == "browse" then
        if key == "up" or key == "w" then
            self.selectedIndex = self.selectedIndex - 1
            if self.selectedIndex < 1 then
                self.selectedIndex = #self.lobbies
            end
        elseif key == "down" or key == "s" then
            self.selectedIndex = self.selectedIndex + 1
            if self.selectedIndex > #self.lobbies then
                self.selectedIndex = 1
            end
        elseif key == "return" or key == "enter" then
            self:joinLobby(self.lobbies[self.selectedIndex])
        end
    elseif self.mode == "lobby" then
        if key == "space" then
            -- Toggle ready
        elseif key == "return" or key == "enter" then
            -- Start game
            if self.currentLobby then
                StateManager:change("gameplay", {
                    song = {title = "Multiplayer Match", artist = "Mixed", bpm = 128},
                    chart = nil, -- Esto activará el generador de chart de prueba en gameplay.lua
                    from = "multiplayer"
                })
            end
        end
    end
end

function Multiplayer:selectOption(optionId)
    if optionId == "create" then
        -- Crear lobby
        self.currentLobby = {
            id = os.time(),
            name = "Room " .. os.time(),
            players = {{name = "You", ready = false}},
            maxPlayers = 8
        }
        self.mode = "lobby"
    elseif optionId == "join" then
        self.mode = "browse"
        self.selectedIndex = 1
    elseif optionId == "direct" then
        -- Direct connect
    end
end

function Multiplayer:joinLobby(lobby)
    self.currentLobby = lobby
    self.mode = "lobby"
end

function Multiplayer:mousemoved(x, y, dx, dy)
    if self.mode == "menu" then
        local startY = 200
        for i, option in ipairs(self.options) do
            local optY = startY + (i - 1) * 80
            if x >= 340 and x <= 940 and y >= optY and y <= (optY + 70) then
                self.selectedIndex = i
                break
            end
        end
    elseif self.mode == "browse" then
        local startY = 200
        for i, lobby in ipairs(self.lobbies) do
            local optY = startY + (i - 1) * 60
            if x >= 200 and x <= 1080 and y >= optY and y <= (optY + 50) then
                self.selectedIndex = i
                break
            end
        end
    end
end

function Multiplayer:mousepressed(x, y, button)
    if button == 1 then
        if self.mode == "menu" then
            local startY = 200
            for i, option in ipairs(self.options) do
                local optY = startY + (i - 1) * 80
                if x >= 340 and x <= 940 and y >= optY and y <= (optY + 70) then
                    self:selectOption(option.id)
                    break
                end
            end
        elseif self.mode == "browse" then
            local startY = 200
            for i, lobby in ipairs(self.lobbies) do
                local optY = startY + (i - 1) * 60
                if x >= 200 and x <= 1080 and y >= optY and y <= (optY + 50) then
                    self:joinLobby(self.lobbies[i])
                    break
                end
            end
        end
    end
end

return Multiplayer