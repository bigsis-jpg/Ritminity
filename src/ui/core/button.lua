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
    
    -- Estilos
    self.font = love.graphics.newFont(24)
    self.descFont = love.graphics.newFont(14)
    
    return self
end

function Button:update(dt)
    -- Transición suave del alpha de hover
    local targetAlpha = (self.isHovered or self.isSelected) and 1.0 or 0.0
    self.hoverAlpha = self.hoverAlpha + (targetAlpha - self.hoverAlpha) * 10 * dt
    
    -- Efecto de escala al hacer clic
    if self.isPressed then
        self.scale = self.scale + (0.95 - self.scale) * 20 * dt
        self.pressedTimer = self.pressedTimer + dt
        if self.pressedTimer > 0.1 then
            self.isPressed = false
        end
    else
        self.scale = self.scale + (1.0 - self.scale) * 15 * dt
    end
end

function Button:draw()
    love.graphics.push()
    
    -- Centrar escala
    local cx = self.x + self.w / 2
    local cy = self.y + self.h / 2
    love.graphics.translate(cx, cy)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-cx, -cy)

    -- Fondo base
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
    end
    love.graphics.setFont(self.font)
    
    -- Centrar texto verticalmente
    local textHeight = self.font:getHeight()
    local textY = self.y + (self.h - textHeight) / 2
    
    love.graphics.printf(self.text, self.x, textY, self.w, "center")
    
    love.graphics.pop()
    
    -- Descripción abajo si está seleccionado o hovered
    if (self.isHovered or self.isSelected) and self.description ~= "" then
        love.graphics.setFont(self.descFont)
        love.graphics.setColor(0.7, 0.7, 0.7, self.hoverAlpha)
        love.graphics.printf(self.description, 0, self.y + self.h + 5, 1280, "center")
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
