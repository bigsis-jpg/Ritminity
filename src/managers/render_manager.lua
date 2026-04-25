--[[
    RITMINITY - Render Manager
    Sistema de renderizado optimizado con batching y post-procesamiento
]]

local RenderManager = {}
RenderManager.__index = RenderManager

-- Shaders disponibles
RenderManager.shaders = {}

-- Buffers de renderizado
RenderManager.batches = {}
RenderManager.currentBatch = nil

-- Configuración de renderizado
RenderManager.config = {
    vsync = true,
    msaa = 0,
    canvas = true,
    postProcessing = true
}

-- Canvas para post-procesamiento
RenderManager.mainCanvas = nil
RenderManager.postCanvas = nil

function RenderManager:initialize()
    -- Crear canvas principal
    self.mainCanvas = love.graphics.newCanvas()
    self.postCanvas = love.graphics.newCanvas()
    
    -- Inicializar batches
    self.batches = {
        images = {},
        shapes = {},
        text = {}
    }
    
    -- Cargar shaders básicos
    self:loadDefaultShaders()
end

-- Cargar shaders por defecto
function RenderManager:loadDefaultShaders()
    -- Shader de tintado simple
    local tintShader = love.graphics.newShader([[
        uniform float time;
        uniform vec4 tint;
        
        vec4 effect(vec4 color, Image tex, vec2 texPos, vec2 scrPos) {
            return Texel(tex, texPos) * tint;
        }
    ]])
    
    self.shaders.tint = tintShader
    
    -- Shader de desenfoque simple
    local blurShader = love.graphics.newShader([[
        uniform vec2 direction;
        uniform vec2 resolution;
        
        vec4 effect(vec4 color, Image tex, vec2 texPos, vec2 scrPos) {
            vec4 sum = vec4(0.0);
            float blur = 1.0 / resolution.x;
            
            sum += Texel(tex, texPos + vec2(-4.0 * blur, 0.0) * direction) * 0.051;
            sum += Texel(tex, texPos + vec2(-3.0 * blur, 0.0) * direction) * 0.0918;
            sum += Texel(tex, texPos + vec2(-2.0 * blur, 0.0) * direction) * 0.12245;
            sum += Texel(tex, texPos + vec2(-1.0 * blur, 0.0) * direction) * 0.1531;
            sum += Texel(tex, texPos) * 0.1633;
            sum += Texel(tex, texPos + vec2(1.0 * blur, 0.0) * direction) * 0.1531;
            sum += Texel(tex, texPos + vec2(2.0 * blur, 0.0) * direction) * 0.12245;
            sum += Texel(tex, texPos + vec2(3.0 * blur, 0.0) * direction) * 0.0918;
            sum += Texel(tex, texPos + vec2(4.0 * blur, 0.0) * direction) * 0.051;
            
            return sum;
        }
    ]])
    
    self.shaders.blur = blurShader
end

-- Iniciar frame de renderizado
function RenderManager:beginFrame()
    love.graphics.setCanvas(self.mainCanvas)
    love.graphics.clear(0, 0, 0, 1)
end

-- Finalizar frame de renderizado
function RenderManager:endFrame()
    love.graphics.setCanvas()
    
    -- Post-procesamiento si está habilitado
    if self.config.postProcessing then
        self:renderPostProcessing()
    else
        -- Renderizar canvas directamente
        love.graphics.draw(self.mainCanvas)
    end
end

-- Renderizar post-procesamiento
function RenderManager:renderPostProcessing()
    love.graphics.setCanvas(self.postCanvas)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.draw(self.mainCanvas)
    love.graphics.setCanvas()
    
    -- Renderizar resultado final
    love.graphics.draw(self.postCanvas)
end

-- Dibujar imagen con transformaciones
function RenderManager:draw(image, x, y, rotation, scaleX, scaleY, originX, originY)
    rotation = rotation or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    
    love.graphics.draw(image, x, y, rotation, scaleX, scaleY, originX, originY)
end

-- Dibujar imagen con tintado
function RenderManager:drawTinted(image, x, y, r, g, b, a, rotation, scaleX, scaleY)
    if self.shaders.tint then
        love.graphics.setShader(self.shaders.tint)
        self.shaders.tint:send("tint", {r, g, b, a})
    end
    
    love.graphics.draw(image, x, y, rotation or 0, scaleX or 1, scaleY or 1)
    
    love.graphics.setShader()
end

-- Dibujar rectángulo con esquinas redondeadas
function RenderManager:drawRoundedRectangle(mode, x, y, width, height, radius)
    local points = {}
    
    -- Esquinas
    local segments = 8
    
    -- Esquina superior izquierda
    for i = 0, segments do
        local angle = (i / segments) * math.pi / 2
        table.insert(points, x + radius + math.cos(angle + math.pi) * radius)
        table.insert(points, y + radius + math.sin(angle + math.pi) * radius)
    end
    
    -- Esquina superior derecha
    for i = 0, segments do
        local angle = (i / segments) * math.pi / 2
        table.insert(points, x + width - radius + math.cos(angle + math.pi/2) * radius)
        table.insert(points, y + radius + math.sin(angle + math.pi/2) * radius)
    end
    
    -- Esquina inferior derecha
    for i = 0, segments do
        local angle = (i / segments) * math.pi / 2
        table.insert(points, x + width - radius + math.cos(angle) * radius)
        table.insert(points, y + height - radius + math.sin(angle) * radius)
    end
    
    -- Esquina inferior izquierda
    for i = 0, segments do
        local angle = (i / segments) * math.pi / 2
        table.insert(points, x + radius + math.cos(angle - math.pi/2) * radius)
        table.insert(points, y + height - radius + math.sin(angle - math.pi/2) * radius)
    end
    
    love.graphics.polygon(mode, unpack(points))
end

-- Dibujar texto con sombra
function RenderManager:drawTextWithShadow(font, text, x, y, color, shadowColor, offset)
    offset = offset or 2
    shadowColor = shadowColor or {0, 0, 0, 0.5}
    
    -- Sombra
    love.graphics.setColor(shadowColor)
    love.graphics.setFont(font)
    love.graphics.print(text, x + offset, y + offset)
    
    -- Texto principal
    love.graphics.setColor(color)
    love.graphics.print(text, x, y)
end

-- Dibujar barra de progreso
function RenderManager:drawProgressBar(x, y, width, height, progress, backgroundColor, foregroundColor)
    -- Fondo
    love.graphics.setColor(backgroundColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    -- Barra de progreso
    if progress > 0 then
        love.graphics.setColor(foregroundColor)
        love.graphics.rectangle("fill", x, y, width * progress, height)
    end
    
    -- Borde
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.rectangle("line", x, y, width, height)
end

-- Establecer color
function RenderManager:setColor(r, g, b, a)
    love.graphics.setColor(r, g, b, a or 1)
end

-- Restablecer color
function RenderManager:resetColor()
    love.graphics.setColor(1, 1, 1, 1)
end

-- Establecer blend mode
function RenderManager:setBlendMode(mode)
    love.graphics.setBlendMode(mode)
end

-- Obtener dimensiones de pantalla
function RenderManager:getScreenSize()
    return love.graphics.getWidth(), love.graphics.getHeight()
end

-- Limpiar
function RenderManager:cleanup()
    self.batches = {}
    self.shaders = {}
end

return RenderManager