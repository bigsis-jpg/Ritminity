--[[
    RITMINITY - Login Screen
    Pantalla de inicio de sesión
]]

local StateManager = require("src.core.state")

local Login = {}
Login.__index = Login

-- Estado
Login.username = ""
Login.password = ""
Login.errorMessage = ""
Login.successMessage = ""
Login.isSubmitting = false

function Login:init()
end

function Login:enter(params)
    self.username = ""
    self.password = ""
    self.errorMessage = ""
    self.successMessage = ""
    self.isSubmitting = false
end

function Login:exit()
end

function Login:update(dt)
end

function Login:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Iniciar Sesión", 0, 150, 1280, "center")
    
    -- Campo de usuario
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Usuario", 0, 250, 340, "right")
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 360, 240, 560, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 360, 240, 560, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.username, 370, 250)
    
    -- Campo de contraseña
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Contraseña", 0, 310, 340, "right")
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 360, 300, 560, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 360, 300, 560, 40)
    
    local passwordDisplay = string.rep("*", #self.password)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(passwordDisplay, 370, 310)
    
    -- Mensaje de error
    if self.errorMessage ~= "" then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.printf(self.errorMessage, 0, 380, 1280, "center")
    end
    
    -- Mensaje de éxito
    if self.successMessage ~= "" then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(0.3, 1, 0.3, 1)
        love.graphics.printf(self.successMessage, 0, 380, 1280, "center")
    end
    
    -- Botón de iniciar sesión
    local buttonColor = {0.1, 0.1, 0.15, 0.8}
    if self.isSubmitting then
        buttonColor = {0.5, 0.5, 0.5, 1}
    elseif self.hoverButton then
        buttonColor = {0.2, 0.6, 1, 0.3}
    end
    
    love.graphics.setColor(buttonColor[1], buttonColor[2], buttonColor[3], buttonColor[4])
    love.graphics.rectangle("fill", 440, 420, 400, 50)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 440, 420, 400, 50)
    
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1, 1)
    if self.isSubmitting then
        love.graphics.printf("Iniciando...", 0, 435, 1280, "center")
    else
        love.graphics.printf("Iniciar Sesión", 0, 435, 1280, "center")
    end
    
    -- Enlace para registrarse
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.5, 0.5, 1, 1)
    if self.hoverRegister then love.graphics.setColor(0.7, 0.7, 1, 1) end
    love.graphics.printf("¿No tienes cuenta? Regístrate", 0, 500, 1280, "center")
    
    -- Instrucciones
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.printf("Tab: Siguiente campo  |  Enter/Clic: Enviar  |  Esc: Volver", 0, 650, 1280, "center")
end

function Login:onEscape()
    StateManager:change("mainmenu")
end

function Login:handleInput(key)
    if key == "tab" then
        -- Alternar entre campos
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            -- Shift+Tab: ir al campo anterior
            -- Por simplicidad, alternamos entre los dos campos
            if love.mouse.getX() > 500 then -- Asumimos que estamos en contraseña
                -- Ir a usuario
            else
                -- Ir a contraseña
            end
        else
            -- Tab: ir al campo siguiente
            -- Por simplicidad, alternamos entre los dos campos
            if love.mouse.getX() > 500 then -- Asumimos que estamos en usuario
                -- Ir a contraseña
            else
                -- Ir a usuario
            end
        end
    elseif key == "return" or key == "enter" then
        self:submit()
    end
end

function Login:mousemoved(x, y, dx, dy)
    self.hoverButton = false
    self.hoverRegister = false
    
    if x >= 440 and x <= 840 and y >= 420 and y <= 470 then
        self.hoverButton = true
    end
    
    if x >= 440 and x <= 840 and y >= 490 and y <= 520 then
        self.hoverRegister = true
    end
end

function Login:mousepressed(x, y, button)
    if button == 1 then -- Click izquierdo
        -- Verificar si se hizo clic en el campo de usuario
        if x >= 360 and x <= 920 and y >= 240 and y <= 280 then
            -- Focus en usuario
        end
        
        -- Verificar si se hizo clic en el campo de contraseña
        if x >= 360 and x <= 920 and y >= 300 and y <= 340 then
            -- Focus en contraseña
        end
        
        -- Verificar si se hizo clic en el botón
        if x >= 440 and x <= 840 and y >= 420 and y <= 470 and not self.isSubmitting then
            self:submit()
        end
        
        -- Verificar si se hizo clic en el enlace de registro
        if y >= 490 and y <= 520 then
            StateManager:change("auth.register")
        end
    end
end

function Login:submit()
    if self.isSubmitting then return end
    
    -- Validar campos
    if self.username == "" then
        self.errorMessage = "El usuario es requerido"
        return
    end
    
    if self.password == "" then
        self.errorMessage = "La contraseña es requerida"
        return
    end
    
    self.isSubmitting = true
    self.errorMessage = ""
    self.successMessage = ""
    
    -- Obtener el manager de autenticación
    local AuthManager = require("src.auth.manager"):getInstance()
    
    -- Intentar iniciar sesión
    AuthManager:login(self.username, self.password, function(success, message)
        self.isSubmitting = false
        if success then
            self.successMessage = message
            -- Esperar un momento y luego ir al menú principal
            love.timer.sleep(1)
            StateManager:change("mainmenu")
        else
            self.errorMessage = message
        end
    end)
end

return Login