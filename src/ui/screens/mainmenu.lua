--[[
    RITMINITY - Main Menu
    Menú principal del juego
]]

local StateManager = require("src.core.state")
local Button = require("src.ui.core.button")
<<<<<<< HEAD
local AudioManager = require("src.managers.audio_manager")
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5

local MainMenu = {}
MainMenu.__index = MainMenu

function MainMenu:init()
    self.backgroundParticles = {}
    self.animationTime = 0
    self.selectedIndex = 1
<<<<<<< HEAD
    self.menuMusic = nil
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    
    -- Inicializar partículas de fondo
    for i = 1, 50 do
        table.insert(self.backgroundParticles, {
            x = math.random(0, 1280),
            y = math.random(0, 720),
            size = math.random(1, 4),
            speed = math.random(10, 30),
            alpha = math.random(0.1, 0.5),
            vx = math.random(-10, 10),
            vy = math.random(-10, 10)
        })
    end
    
    -- Crear Botones
    self.buttons = {}
    
    local startY = 300
    local spacing = 80
    local buttonWidth = 400
    local buttonHeight = 60
    local buttonX = (1280 - buttonWidth) / 2
    
    self.optionsData = {
        {id = "solo", label = "Un Jugador", description = "Jugar en solitario"},
<<<<<<< HEAD
        {id = "profile", label = "Perfil", description = "Ver tus estadísticas y rango"},
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        {id = "multiplayer", label = "Multijugador", description = "Jugar en línea"},
        {id = "editor", label = "Editor", description = "Crear o editar mapas"},
        {id = "settings", label = "Opciones", description = "Configuración del juego"},
        {id = "exit", label = "Salir", description = "Cerrar el juego"}
    }
    
    for i, opt in ipairs(self.optionsData) do
        local y = startY + (i - 1) * spacing
        local btn = Button:new(buttonX, y, buttonWidth, buttonHeight, opt.label, function()
            self:selectOption(opt.id)
        end, opt.description)
<<<<<<< HEAD
        
        -- Staggered entry animation
        btn.entryProgress = -i * 0.15
        
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        table.insert(self.buttons, btn)
    end
end

function MainMenu:enter(params)
    self.animationTime = 0
    self.selectedIndex = 1
    
    -- Resetear estado de botones
    for i, btn in ipairs(self.buttons) do
        btn.isHovered = false
        btn.isSelected = (i == self.selectedIndex)
        btn.isPressed = false
    end
<<<<<<< HEAD

    -- Reproducir música del menú si hay archivos disponibles
    if not AudioManager:isMusicPlaying() then
        local songs = love.filesystem.getDirectoryItems("assets/songs")
        for _, file in ipairs(songs) do
            if file:match("%.mp3$") or file:match("%.ogg$") then
                self.menuMusic = AudioManager:loadMusic("assets/songs/" .. file)
                AudioManager:playMusic(self.menuMusic, 0.5)
                break
            end
        end
    end
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

function MainMenu:exit()
end

function MainMenu:update(dt)
    self.animationTime = self.animationTime + dt
    
    -- Actualizar partículas
    for _, particle in ipairs(self.backgroundParticles) do
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Rebotar en los bordes
        if particle.x < 0 or particle.x > 1280 then particle.vx = -particle.vx end
        if particle.y < 0 or particle.y > 720 then particle.vy = -particle.vy end
    end
    
    -- Actualizar Botones
    for i, btn in ipairs(self.buttons) do
        btn.isSelected = (i == self.selectedIndex)
        btn:update(dt)
    end
end

function MainMenu:draw()
    -- Fondo base
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Efecto de gradiente animado
    local r = 0.1 + math.sin(self.animationTime * 0.5) * 0.05
    local g = 0.1 + math.cos(self.animationTime * 0.3) * 0.05
    local b = 0.2 + math.sin(self.animationTime * 0.4) * 0.1
    love.graphics.setColor(r, g, b, 0.5)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Partículas
    for _, particle in ipairs(self.backgroundParticles) do
        love.graphics.setColor(0.5, 0.8, 1, particle.alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
    
    -- Logo / Título
    love.graphics.setColor(1, 1, 1, 1)
    local titleFont = love.graphics.newFont(60)
    love.graphics.setFont(titleFont)
    
    -- Animación de título
    local titleY = 100 + math.sin(self.animationTime * 2) * 10
    love.graphics.printf("RITMINITY", 0, titleY, 1280, "center")
    
    local subtitleFont = love.graphics.newFont(20)
    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(0.5, 0.8, 1, 1)
    love.graphics.printf("The Ultimate Rhythm Experience", 0, titleY + 70, 1280, "center")
    
    -- Dibujar Botones
    for _, btn in ipairs(self.buttons) do
        btn:draw()
    end
    
    -- Info de controles
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("Use ↑/↓ keys or Mouse to navigate. Enter to select.", 0, 680, 1280, "center")
end

-- Input de Teclado
function MainMenu:handleInput(key)
    if key == "up" or key == "w" then
        self.selectedIndex = self.selectedIndex - 1
        if self.selectedIndex < 1 then
            self.selectedIndex = #self.buttons
        end
    elseif key == "down" or key == "s" then
        self.selectedIndex = self.selectedIndex + 1
        if self.selectedIndex > #self.buttons then
            self.selectedIndex = 1
        end
<<<<<<< HEAD
    elseif key == "return" or key == "enter" or key == "kpenter" or key == "space" then
        self.buttons[self.selectedIndex]:click()
    elseif key == "escape" then
        love.event.quit()
=======
    elseif key == "return" or key == "enter" then
        self.buttons[self.selectedIndex]:click()
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

-- Hover del mouse
function MainMenu:mousemoved(x, y, dx, dy)
    local hoveredAny = false
    for i, btn in ipairs(self.buttons) do
        if btn:mousemoved(x, y) then
            self.selectedIndex = i
            hoveredAny = true
        end
    end
end

-- Clic del mouse
function MainMenu:mousepressed(x, y, button)
    for _, btn in ipairs(self.buttons) do
        if btn:mousepressed(x, y, button) then
            break
        end
    end
end

-- Release del mouse
function MainMenu:mousereleased(x, y, button)
    for _, btn in ipairs(self.buttons) do
        btn:mousereleased(x, y, button)
    end
end

-- Lógica de selección
function MainMenu:selectOption(optionId)
    if optionId == "solo" then
        StateManager:change("songselect")
<<<<<<< HEAD
    elseif optionId == "profile" then
        StateManager:change("profile")
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    elseif optionId == "multiplayer" then
        StateManager:change("multiplayer")
    elseif optionId == "editor" then
        StateManager:change("editor")
    elseif optionId == "settings" then
        StateManager:change("settings")
    elseif optionId == "exit" then
        love.event.quit()
    end
end

return MainMenu