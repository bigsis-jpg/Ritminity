--[[
    RITMINITY - Settings Screen
    Pantalla de configuración
]]

local StateManager = require("src.core.state")

local Settings = {}
Settings.__index = Settings

-- Categorías de settings
Settings.categories = {
    {id = "general", label = "General"},
    {id = "graphics", label = "Graphics"},
    {id = "audio", label = "Audio"},
    {id = "input", label = "Input"},
    {id = "gameplay", label = "Gameplay"}
}

-- Settings actuales
Settings.currentCategory = 1
Settings.currentIndex = 1

-- Opciones por categoría
Settings.options = {
    general = {
        {id = "username", label = "Username", type = "text", value = "Player"},
        {id = "language", label = "Language", type = "select", value = "English", options = {"English", "Spanish", "Japanese"}},
        {id = "theme", label = "Theme", type = "select", value = "Dark", options = {"Dark", "Light"}}
    },
    graphics = {
        {id = "resolution", label = "Resolution", type = "select", value = "1280x720", options = {"1280x720", "1920x1080", "2560x1440"}},
        {id = "fullscreen", label = "Fullscreen", type = "boolean", value = false},
        {id = "vsync", label = "VSync", type = "boolean", value = true},
        {id = "fps", label = "Show FPS", type = "boolean", value = true}
    },
    audio = {
        {id = "masterVolume", label = "Master Volume", type = "slider", value = 80, min = 0, max = 100},
        {id = "musicVolume", label = "Music Volume", type = "slider", value = 80, min = 0, max = 100},
        {id = "effectVolume", label = "Effect Volume", type = "slider", value = 100, min = 0, max = 100},
<<<<<<< HEAD
        {id = "offset", label = "Audio Offset", type = "slider", value = 0, min = -200, max = 200},
        {id = "calibrate", label = "Run Calibration", type = "button", value = "START"}
=======
        {id = "offset", label = "Audio Offset", type = "slider", value = 0, min = -100, max = 100}
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    },
    input = {
        {id = "key1", label = "Column 1 Key", type = "key", value = "d"},
        {id = "key2", label = "Column 2 Key", type = "key", value = "f"},
        {id = "key3", label = "Column 3 Key", type = "key", value = "j"},
        {id = "key4", label = "Column 4 Key", type = "key", value = "k"},
        {id = "columnCount", label = "Column Count", type = "select", value = "4", options = {"4", "5", "6", "7", "8"}}
    },
    gameplay = {
        {id = "skin", label = "Skin", type = "select", value = "Default", options = {"Default", "Classic", "Modern"}},
        {id = "noteSpeed", label = "Note Speed", type = "slider", value = 100, min = 50, max = 200},
        {id = "scrollSpeed", label = "Scroll Speed", type = "slider", value = 100, min = 50, max = 200},
        {id = "judgmentWindow", label = "Judgment Window", type = "select", value = "Normal", options = {"Easy", "Normal", "Hard", "Insane"}},
        {id = "backgroundDim", label = "Background Dim", type = "slider", value = 80, min = 0, max = 100}
    }
}

function Settings:init()
end

function Settings:enter(params)
    self.currentCategory = 1
    self.currentIndex = 1
<<<<<<< HEAD
    
    -- Sincronizar valores desde RITMINITY.settings
    for _, opt in ipairs(self.options.audio) do
        if opt.id == "offset" then
            opt.value = RITMINITY.settings.globalOffset
        end
    end
    
    -- Si venimos de calibración, actualizar el valor recibido
    if params and params.newOffset then
        RITMINITY.settings.globalOffset = math.floor(params.newOffset + 0.5)
        for _, opt in ipairs(self.options.audio) do
            if opt.id == "offset" then opt.value = RITMINITY.settings.globalOffset end
        end
    end
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
end

function Settings:exit()
end

function Settings:update(dt)
end

function Settings:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(30))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Ajustes", 0, 50, 1280, "center")
    
    -- Categorías
    self:drawCategories()
    
    -- Opciones
    self:drawOptions()
end

function Settings:drawCategories()
    local startX = 100
    local y = 120
    
    for i, category in ipairs(self.categories) do
        local x = startX + (i - 1) * 200
        
        if i == self.currentCategory then
            love.graphics.setColor(0.2, 0.6, 1, 1)
            love.graphics.rectangle("fill", x - 10, y - 10, 180, 40)
        else
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", x - 10, y - 10, 180, 40)
        end
        
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(category.label, x - 10, y, 180, "center")
    end
end

function Settings:drawOptions()
    local category = self.categories[self.currentCategory]
    local options = self.options[category.id]
    
    if not options then
        return
    end
    
    local startY = 200
    
    for i, option in ipairs(options) do
        local y = startY + (i - 1) * 60
        local selected = (i == self.currentIndex)
        
        -- Fondo
        if selected then
            love.graphics.setColor(0.2, 0.6, 1, 0.3)
            love.graphics.rectangle("fill", 200, y - 10, 880, 50)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.rectangle("line", 200, y - 10, 880, 50)
        else
            love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
            love.graphics.rectangle("fill", 200, y - 10, 880, 50)
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("line", 200, y - 10, 880, 50)
        end
        
        -- Label
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(option.label, 250, y)
        
        -- Valor
        local valueStr = ""
        
        if option.type == "boolean" then
            valueStr = option.value and "On" or "Off"
        elseif option.type == "slider" then
            valueStr = tostring(option.value)
        elseif option.type == "select" then
            valueStr = option.value
        elseif option.type == "text" then
            valueStr = option.value
        elseif option.type == "key" then
            valueStr = option.value:upper()
        end
        
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
<<<<<<< HEAD
        if self.waitingForKey == option then
            valueStr = "PRESS A KEY..."
            love.graphics.setColor(1, 1, 0, 1)
        end
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        love.graphics.printf(valueStr, 200, y, 850, "right")
        
        -- Barra de slider
        if option.type == "slider" then
            local barWidth = 300
            local barX = 750
            local progress = (option.value - option.min) / (option.max - option.min)
            
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", barX, y + 25, barWidth, 10)
            
            love.graphics.setColor(0.2, 0.6, 1, 1)
            love.graphics.rectangle("fill", barX, y + 25, barWidth * progress, 10)
        end
    end
    
    -- Instrucciones
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.printf("←→/Clic: Categoría  |  ↑↓/Mouse: Opción  |  Enter/Clic: Modificar  |  Esc: Volver", 0, 680, 1280, "center")
end

function Settings:onEscape()
    StateManager:change("mainmenu")
end

function Settings:handleInput(key)
<<<<<<< HEAD
    if self.waitingForKey then
        if key ~= "escape" then
            self.waitingForKey.value = key
            -- Guardar en settings globales
            if self.waitingForKey.id:match("key%d") then
                local idx = tonumber(self.waitingForKey.id:match("key(%d)"))
                RITMINITY.settings.keys[idx] = key
            end
        end
        self.waitingForKey = nil
        return
    end

=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    if key == "left" or key == "a" then
        self.currentCategory = self.currentCategory - 1
        if self.currentCategory < 1 then
            self.currentCategory = #self.categories
        end
        self.currentIndex = 1
    elseif key == "right" or key == "d" then
        self.currentCategory = self.currentCategory + 1
        if self.currentCategory > #self.categories then
            self.currentCategory = 1
        end
        self.currentIndex = 1
    elseif key == "up" or key == "w" then
        self.currentIndex = self.currentIndex - 1
        local category = self.categories[self.currentCategory]
        local options = self.options[category.id]
        if self.currentIndex < 1 then
            self.currentIndex = #options
        end
    elseif key == "down" or key == "s" then
        self.currentIndex = self.currentIndex + 1
        local category = self.categories[self.currentCategory]
        local options = self.options[category.id]
        if self.currentIndex > #options then
            self.currentIndex = 1
        end
<<<<<<< HEAD
    elseif key == "return" or key == "enter" or key == "kpenter" or key == "space" then
        self:modifyOption()
    elseif key == "escape" then
        self:onEscape()
=======
    elseif key == "return" or key == "enter" then
        self:modifyOption()
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

function Settings:modifyOption()
    local category = self.categories[self.currentCategory]
    local options = self.options[category.id]
    local option = options[self.currentIndex]
    
    if option.type == "boolean" then
        option.value = not option.value
<<<<<<< HEAD
    elseif option.type == "button" then
        if option.id == "calibrate" then
            StateManager:change("calibration")
        end
    elseif option.type == "key" then
        self.waitingForKey = option
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    elseif option.type == "select" then
        local currentIdx = 1
        for i, opt in ipairs(option.options) do
            if opt == option.value then
                currentIdx = i
                break
            end
        end
        currentIdx = currentIdx + 1
        if currentIdx > #option.options then
            currentIdx = 1
        end
        option.value = option.options[currentIdx]
    elseif option.type == "slider" then
        option.value = option.value + 10
        if option.value > option.max then
            option.value = option.min
        end
<<<<<<< HEAD
        
        -- Sincronizar offset global
        if option.id == "offset" then
            RITMINITY.settings.globalOffset = option.value
        end
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

function Settings:mousemoved(x, y, dx, dy)
    -- Categorías (Tabs)
    local startX = 100
    local catY = 120
    for i, category in ipairs(self.categories) do
        local catX = startX + (i - 1) * 200
        if x >= (catX - 10) and x <= (catX + 170) and y >= (catY - 10) and y <= (catY + 30) then
            -- Solo hover visual (opcional), no cambia tab en hover para no ser molesto
            break
        end
    end
    
    -- Opciones
    local category = self.categories[self.currentCategory]
    local options = self.options[category.id]
    if options then
        local startY = 200
        for i, option in ipairs(options) do
            local optY = startY + (i - 1) * 60
            if x >= 200 and x <= 1080 and y >= (optY - 10) and y <= (optY + 40) then
                self.currentIndex = i
                break
            end
        end
    end
end

function Settings:mousepressed(x, y, button)
    if button == 1 then
        -- Clic en Categorías (Tabs)
        local startX = 100
        local catY = 120
        for i, category in ipairs(self.categories) do
            local catX = startX + (i - 1) * 200
            if x >= (catX - 10) and x <= (catX + 170) and y >= (catY - 10) and y <= (catY + 30) then
                self.currentCategory = i
                self.currentIndex = 1
                return
            end
        end
        
        -- Clic en Opciones
        local category = self.categories[self.currentCategory]
        local options = self.options[category.id]
        if options then
            local startY = 200
            for i, option in ipairs(options) do
                local optY = startY + (i - 1) * 60
                if x >= 200 and x <= 1080 and y >= (optY - 10) and y <= (optY + 40) then
                    self.currentIndex = i
                    self:modifyOption()
                    return
                end
            end
        end
    end
end

return Settings