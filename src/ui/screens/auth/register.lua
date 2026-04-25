--[[
    RITMINITY - Register Screen
    Pantalla de registro
]]

local StateManager = require("src.core.state")

local Register = {}
Register.__index = Register

-- Estado
Register.username = ""
Register.email = ""
Register.password = ""
Register.confirmPassword = ""
Register.errorMessage = ""
Register.successMessage = ""
Register.isSubmitting = false

function Register:init()
end

function Register:enter(params)
    self.username = ""
    self.email = ""
    self.password = ""
    self.confirmPassword = ""
    self.errorMessage = ""
    self.successMessage = ""
    self.isSubmitting = false
end

function Register:exit()
end

function Register:update(dt)
end

function Register:draw()
    -- Fondo
    love.graphics.setColor(0.05, 0.05, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    
    -- Título
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Crear Cuenta", 0, 100, 1280, "center")
    
    -- Campo de usuario
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Usuario", 0, 200, 340, "right")
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 300, 190, 680, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 300, 190, 680, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.username, 370, 200)
    
    -- Campo de email
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Email", 0, 260, 340, "right")
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 300, 240, 680, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 300, 240, 680, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(self.email, 370, 260)
    
    -- Campo de contraseña
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Contraseña", 0, 320, 340, "right")
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 300, 290, 680, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 300, 290, 680, 40)
    
    local passwordDisplay = string.rep("*", #self.password)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(passwordDisplay, 370, 320)
    
    -- Campo de confirmar contraseña
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.printf("Confirmar", 0, 380, 340, "right")
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
    love.graphics.rectangle("fill", 300, 340, 680, 40)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 300, 340, 680, 40)
    
    local confirmDisplay = string.rep("*", #self.confirmPassword)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(confirmDisplay, 370, 380)
    
    -- Mensaje de error
    if self.errorMessage ~= "" then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(1, 0.3, 0.3, 1)
        love.graphics.printf(self.errorMessage, 0, 440, 1280, "center")
    end
    
    -- Mensaje de éxito
    if self.successMessage ~= "" then
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.setColor(0.3, 1, 0.3, 1)
        love.graphics.printf(self.successMessage, 0, 440, 1280, "center")
    end
    
    -- Botón de registro
    local buttonColor = {0.1, 0.1, 0.15, 0.8}
    if self.isSubmitting then
        buttonColor = {0.5, 0.5, 0.5, 1}
    elseif self.hoverButton then
        buttonColor = {0.2, 0.6, 1, 0.3}
    end
    
    love.graphics.setColor(buttonColor[1], buttonColor[2], buttonColor[3], buttonColor[4])
    love.graphics.rectangle("fill", 440, 480, 400, 50)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", 440, 480, 400, 50)
    
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.setColor(1, 1, 1, 1)
    if self.isSubmitting then
        love.graphics.printf("Registrando...", 0, 495, 1280, "center")
    else
        love.graphics.printf("Crear Cuenta", 0, 495, 1280, "center")
    end
    
    -- Enlace para login
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.setColor(0.5, 0.5, 1, 1)
    if self.hoverLogin then love.graphics.setColor(0.7, 0.7, 1, 1) end
    love.graphics.printf("¿Ya tienes cuenta? Iniciar Sesión", 0, 560, 1280, "center")
    
    -- Instrucciones
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.printf("Tab: Siguiente campo  |  Enter/Clic: Enviar  |  Esc: Volver", 0, 650, 1280, "center")
end

function Register:onEscape()
    StateManager:change("mainmenu")
end

function Register:handleInput(key)
    if key == "tab" then
        -- Alternar entre campos (simplificado)
        -- En una implementación real, tendría un enfoque más sofisticado
    elseif key == "return" or key == "enter" then
        self:submit()
    end
end

function Register:mousemoved(x, y, dx, dy)
    self.hoverButton = false
    self.hoverLogin = false
    
    if x >= 440 and x <= 840 and y >= 480 and y <= 530 then
        self.hoverButton = true
    end
    
    if x >= 440 and x <= 840 and y >= 550 and y <= 580 then
        self.hoverLogin = true
    end
end

function Register:mousepressed(x, y, button)
    if button == 1 then -- Click izquierdo
        -- Verificar si se hizo clic en los campos
        if x >= 300 and x <= 980 then
            if y >= 190 and y <= 230 then
                -- Focus en usuario
            elseif y >= 240 and y <= 280 then
                -- Focus en email
            elseif y >= 290 and y <= 330 then
                -- Focus en contraseña
            elseif y >= 340 and y <= 380 then
                -- Focus en confirmar contraseña
            end
        end
        
        -- Verificar si se hizo clic en el botón
        if x >= 440 and x <= 840 and y >= 460 and y <= 510 and not self.isSubmitting then
            self:submit()
        end
        
        -- Verificar si se hizo clic en el enlace de login
        if y >= 530 and y <= 560 then
            StateManager:change("auth.login")
        end
    end
end

function Register:submit()
    if self.isSubmitting then return end
    
    -- Validar campos
    if self.username == "" then
        self.errorMessage = "El usuario es requerido"
        return
    end
    
    if self.username:len() < 3 or self.username:len() > 50 then
        self.errorMessage = "El usuario debe tener entre 3 y 50 caracteres"
        return
    end
    
    if self.email == "" then
        self.errorMessage = "El email es requerido"
        return
    end
    
    if not self.email:match("^[^@]+@[^@]+%.[^@]+$") then
        self.errorMessage = "Email no válido"
        return
    end
    
    if self.password == "" then
        self.errorMessage = "La contraseña es requerida"
        return
    end
    
    if self.password:len() < 6 then
        self.errorMessage = "La contraseña debe tener al menos 6 caracteres"
        return
    end
    
    if self.password ~= self.confirmPassword then
        self.errorMessage = "Las contraseñas no coinciden"
        return
    end
    
    self.isSubmitting = true
    self.errorMessage = ""
    self.successMessage = ""
    
    -- Obtener el manager de autenticación
    local AuthManager = require("src.auth.manager"):getInstance()
    
    -- Intentar registrar
    AuthManager:register(self.username, self.email, self.password, function(success, message)
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

return Register