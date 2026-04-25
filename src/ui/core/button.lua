--[[
    RITMINITY - UI Button Core
    Clase reutilizable para botones funcionales con animaciones
]]

local Button = {}
Button.__index = Button

function Button:new(x, y, w, h, text, onClick, description)
    local self = setmetatable({}, Button)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.text = text or ""
    self.description = description or ""
    self.onClick = onClick
    
    -- Estados
    self.isHovered = false
    self.isPressed = false
    self.isSelected = false -- para navegacion por teclado
    
    -- Animaciones
    self.hoverAlpha = 0
    self.scale = 1.0
    self.pressedTimer = 0
<<<<<<< HEAD
    self.entryProgress = 0
    self.pulseTimer = 0
=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    
    -- Estilos
    self.font = love.graphics.newFont(24)
    self.descFont = love.graphics.newFont(14)
    
    return self
end

function Button:update(dt)
<<<<<<< HEAD
    -- Animación de entrada
    if self.entryProgress < 1 then
        self.entryProgress = math.min(1, self.entryProgress + dt * 2)
    end

=======
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    -- Transición suave del alpha de hover
    local targetAlpha = (self.isHovered or self.isSelected) and 1.0 or 0.0
    self.hoverAlpha = self.hoverAlpha + (targetAlpha - self.hoverAlpha) * 10 * dt
    
<<<<<<< HEAD
    -- Pulso de selección
    if self.isSelected then
        self.pulseTimer = self.pulseTimer + dt * 5
    else
        self.pulseTimer = 0
    end

    -- Efecto de escala al hacer clic
    if self.isPressed then
        self.scale = self.scale + (0.92 - self.scale) * 25 * dt
=======
    -- Efecto de escala al hacer clic
    if self.isPressed then
        self.scale = self.scale + (0.95 - self.scale) * 20 * dt
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
        self.pressedTimer = self.pressedTimer + dt
        if self.pressedTimer > 0.1 then
            self.isPressed = false
        end
    else
<<<<<<< HEAD
        local targetScale = 1.0
        if self.isSelected or self.isHovered then
            targetScale = 1.05 + math.sin(self.pulseTimer) * 0.02
        end
        self.scale = self.scale + (targetScale - self.scale) * 15 * dt
=======
        self.scale = self.scale + (1.0 - self.scale) * 15 * dt
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

function Button:draw()
<<<<<<< HEAD
    if self.entryProgress <= 0 then return end
    
    love.graphics.push()
    
    -- Aplicar animación de entrada (suavizado)
    local smoothEntry = 1 - (1 - self.entryProgress)^3
    local drawX = self.x - (1 - smoothEntry) * 100
    local drawAlpha = smoothEntry
    
    -- Centrar escala
    local cx = drawX + self.w / 2
=======
    love.graphics.push()
    
    -- Centrar escala
    local cx = self.x + self.w / 2
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    local cy = self.y + self.h / 2
    love.graphics.translate(cx, cy)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-cx, -cy)

    -- Fondo base
<<<<<<< HEAD
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8 * drawAlpha)
    love.graphics.rectangle("fill", drawX, self.y, self.w, self.h, 5, 5)
    
    -- Fondo hover
    if self.hoverAlpha > 0 then
        love.graphics.setColor(0.2, 0.6, 1, 0.4 * self.hoverAlpha * drawAlpha)
        love.graphics.rectangle("fill", drawX, self.y, self.w, self.h, 5, 5)
    end
    
    -- Borde y Glow
    if self.isHovered or self.isSelected then
        -- Glow exterior
        love.graphics.setLineWidth(4)
        love.graphics.setColor(0.2, 0.6, 1, 0.2 * drawAlpha)
        love.graphics.rectangle("line", drawX - 2, self.y - 2, self.w + 4, self.h + 4, 6, 6)
        
        love.graphics.setLineWidth(2)
        love.graphics.setColor(1, 1, 1, 1 * drawAlpha)
    else
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.3, 0.3, 0.3, 0.6 * drawAlpha)
    end
    love.graphics.rectangle("line", drawX, self.y, self.w, self.h, 5, 5)
    
    -- Texto
    if self.isHovered or self.isSelected then
        love.graphics.setColor(1, 1, 1, 1 * drawAlpha)
    else
        love.graphics.setColor(0.6, 0.6, 0.6, 0.8 * drawAlpha)
=======
    love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 5, 5)
    
    -- Fondo hover
    if self.hoverAlpha > 0 then
        love.graphics.setColor(0.2, 0.6, 1, 0.3 * self.hoverAlpha)
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 5, 5)
    end
    
    -- Borde
    if self.isHovered or self.isSelected then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
    end
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, 5, 5)
    
    -- Texto
    if self.isHovered or self.isSelected then
        love.graphics.setColor(1, 1, 1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
    love.graphics.setFont(self.font)
    
    -- Centrar texto verticalmente
    local textHeight = self.font:getHeight()
    local textY = self.y + (self.h - textHeight) / 2
    
<<<<<<< HEAD
    love.graphics.printf(self.text, drawX, textY, self.w, "center")
=======
    love.graphics.printf(self.text, self.x, textY, self.w, "center")
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    
    love.graphics.pop()
    
    -- Descripción abajo si está seleccionado o hovered
    if (self.isHovered or self.isSelected) and self.description ~= "" then
        love.graphics.setFont(self.descFont)
<<<<<<< HEAD
        love.graphics.setColor(0.7, 0.7, 0.7, self.hoverAlpha * drawAlpha)
        love.graphics.printf(self.description, 0, self.y + self.h + 8, 1280, "center")
=======
        love.graphics.setColor(0.7, 0.7, 0.7, self.hoverAlpha)
        love.graphics.printf(self.description, 0, self.y + self.h + 5, 1280, "center")
>>>>>>> fc9fba8c9d95bbf81299517e75bcc2e4260a8cb5
    end
end

function Button:mousemoved(x, y)
    local wasHovered = self.isHovered
    self.isHovered = (x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h)
    
    -- Feedback de sonido opcional al entrar al hover
    -- if self.isHovered and not wasHovered then
    --     AudioManager:playSound("hover")
    -- end
    
    return self.isHovered
end

function Button:mousepressed(x, y, btn)
    if btn == 1 and self.isHovered then
        self.isPressed = true
        self.pressedTimer = 0
        return true
    end
    return false
end

function Button:mousereleased(x, y, btn)
    if btn == 1 and self.isHovered and self.isPressed then
        self.isPressed = false
        if self.onClick then
            self.onClick()
        end
        return true
    end
    self.isPressed = false
    return false
end

-- Simular clic desde teclado
function Button:click()
    self.isPressed = true
    self.pressedTimer = 0
    if self.onClick then
        self.onClick()
    end
end

return Button
