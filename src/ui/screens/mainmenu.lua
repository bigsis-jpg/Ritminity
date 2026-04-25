--[[
    RITMINITY - Main Menu Screen
    Pantalla principal del menú
]]

local StateManager = require("src.core.state")

local MainMenu = {}
MainMenu.__index = MainMenu

-- Opciones del menú
MainMenu.options = {
    {id = "solo", label = "Un Jugador", description = "Jugar en solitario"},
    {id = "multiplayer", label = "Multijugador", description = "Jugar en línea con otros"},
    {id = "editor", label = "Editor de Mapas", description = "Crear tus propios charts"},
    {id = "results", label = "Puntuaciones", description = "Ver puntuaciones guardadas"},
    {id = "settings", label = "Ajustes", description = "Configurar el juego"},
    {id = "login", label = "Iniciar Sesión", description = "Acceder a tu cuenta"},
    {id = "register", label = "Registrarse", description = "Crear una nueva cuenta"},
    {id = "exit", label = "Salir al Escritorio", description = "Salir del juego"}
}

-- Estado
MainMenu.selectedIndex = 1
MainMenu.animationTime = 0
MainMenu.backgroundParticles = {}

function MainMenu:init()
    -- Inicializar partículas de fondo
    for i = 1, 50 do
        table.insert(self.backgroundParticles, {
            x = math.random() * 1280,
            y = math.random() * 720,
            vx = (math.random() - 0.5) * 0.5,
            vy = (math.random() - 0.5) * 0.5,
            size = math.random() * 3 + 1,
            alpha = math.random() * 0.5 + 0.2
        })
    end
end

function MainMenu:enter(params)
    self.selectedIndex = 1
    self.animationTime = 0
    
    -- Reproducir música del menú
    -- AudioManager:playMusic("menu")
end

function MainMenu:exit()
    -- Detener música
    -- AudioManager:stopMusic()
end

function MainMenu:update(dt)
    self.animationTime = self.animationTime + dt
    
    -- Actualizar partículas
    for _, particle in ipairs(self.backgroundParticles) do
        particle.x = particle.x + particle.vx
        particle.y = particle.y + particle.vy
        
        -- Rebotar en los bordes
        if particle.x < 0 or particle.x > 1280 then
            particle.vx = -particle.vx
        end
        if particle.y < 0 or particle.y > 720 then
            particle.vy = -particle.vy
        end
    end
end

function MainMenu:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Partículas de fondo
    for _, particle in ipairs(self.backgroundParticles) do
        love.graphics.setColor(0.2, 0.6, 1, particle.alpha)
        love.graphics.circle("fill", particle.x, particle.y, particle.size)
    end
    
    -- Título
    local titleY = 150
    local titleScale = 1.0 + math.sin(self.animationTime * 2) * 0.02
    
    love.graphics.setFont(love.graphics.newFont(60))
    love.graphics.setColor(1, 0.5, 0, 1)
    love.graphics.printf("RITMINITY", 0, titleY - 30, 1280, "center")
    
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.printf("A Rhythm Game Experience", 0, titleY + 40, 1280, "center")
    
    -- Opciones del menú
    local startY = 300
    local spacing = 60
    
    for i, option in ipairs(self.options) do
        local y = startY + (i - 1) * spacing
        local selected = (i == self.selectedIndex)
        
        -- Dibujar siempre una caja para el botón
        if selected then
            love.graphics.setColor(0.2, 0.6, 1, 0.3)
            love.graphics.rectangle("fill", 440, y - 25, 400, 50)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", 440, y - 25, 400, 50)
            
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(30))
        else
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 440, y - 25, 400, 50)
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("line", 440, y - 25, 400, 50)
            
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.setFont(love.graphics.newFont(24))
        end
        
        -- Texto centrado correctamente (x=0, limit=1280)
        love.graphics.printf(option.label, 0, y - 15, 1280, "center")
        
        -- Descripción
        if selected then
            love.graphics.setFont(love.graphics.newFont(14))
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
            love.graphics.printf(option.description, 0, y + 20, 1280, "center")
        end
    end
    
    -- Versión
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.printf("v1.0.0", 0, 700, 1280, "center")
    
    -- Controles
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("↑↓/Mouse: Navegar  |  Enter/Clic: Seleccionar  |  Esc: Salir", 0, 680, 1280, "center")
end

function MainMenu:onEscape()
    -- Salir del juego
    love.event.quit()
end

-- Manejar input de teclado
function MainMenu:handleInput(key)
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
end

-- Hover del mouse
function MainMenu:mousemoved(x, y, dx, dy)
    local startY = 300
    local spacing = 60
    local found = false
    
    for i, option in ipairs(self.options) do
        local optY = startY + (i - 1) * spacing
        -- Hitbox del botón: x(440 a 840), y(optY-25 a optY+25)
        if x >= 440 and x <= 840 and y >= (optY - 25) and y <= (optY + 25) then
            self.selectedIndex = i
            found = true
            break
        end
    end
    
    if not found then
        -- Opcional: se podría hacer que no se seleccione nada, pero como el menú requiere al menos 1 seleccionado para el teclado:
        -- Dejarlo como está, o tal vez establecer una variable `mouseHover`
    end
end

-- Clic del mouse
function MainMenu:mousepressed(x, y, button)
    if button == 1 then
        local startY = 300
        local spacing = 60
        
        for i, option in ipairs(self.options) do
            local optY = startY + (i - 1) * spacing
            if x >= 440 and x <= 840 and y >= (optY - 25) and y <= (optY + 25) then
                self:selectOption(option.id)
                break
            end
        end
    end
end

-- Seleccionar opción
function MainMenu:selectOption(optionId)
    if optionId == "solo" then
        StateManager:change("songselect")
    elseif optionId == "multiplayer" then
        StateManager:change("multiplayer")
    elseif optionId == "editor" then
        StateManager:change("editor")
    elseif optionId == "results" then
        StateManager:change("results")
    elseif optionId == "settings" then
        StateManager:change("settings")
    elseif optionId == "login" then
        StateManager:change("auth.login")
    elseif optionId == "register" then
        StateManager:change("auth.register")
    elseif optionId == "exit" then
        love.event.quit()
    end
end

return MainMenu