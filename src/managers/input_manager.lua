--[[
    RITMINITY - Input Manager
    Sistema de gestión de entrada unificado para teclado, mouse y gamepad
]]

local EventSystem = require("src.core.event")

local InputManager = {}
InputManager.__index = InputManager

-- Tabla de teclas presionadas
InputManager.keys = {}
InputManager.keysPressed = {}
InputManager.keysReleased = {}

-- Tabla de mouse
InputManager.mouse = {
    x = 0,
    y = 0,
    dx = 0,
    dy = 0,
    wheel = 0,
    buttons = {},
    buttonsPressed = {},
    buttonsReleased = {}
}

-- Joysticks conectados
InputManager.joysticks = {}

-- Mapeo de teclas para gameplay (columnas)
InputManager.keyMap = {
    ["d"] = 1,
    ["f"] = 2,
    ["j"] = 3,
    ["k"] = 4,
    ["l"] = 5,
    [";"] = 6,
    ["a"] = 1,
    ["s"] = 2,
    ["w"] = 3,
    ["e"] = 4,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4
}

-- Teclas adicionales para más columnas
InputManager.extendedKeyMap = {
    ["d"] = 1, ["f"] = 2, ["g"] = 3, ["h"] = 4, ["j"] = 5, ["k"] = 6, ["l"] = 7,
    ["a"] = 1, ["s"] = 2, ["w"] = 3, ["e"] = 4, ["r"] = 5, ["t"] = 6, ["y"] = 7,
    ["1"] = 1, ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7
}

-- Callbacks de input
InputManager.callbacks = {}

function InputManager:initialize()
    self.keys = {}
    self.keysPressed = {}
    self.keysReleased = {}
    self.mouse = {
        x = 0,
        y = 0,
        dx = 0,
        dy = 0,
        wheel = 0,
        buttons = {},
        buttonsPressed = {},
        buttonsReleased = {}
    }
    self.joysticks = {}
    self.callbacks = {}
end

-- Manejar tecla presionada
function InputManager:handleKeyPressed(key, scancode, isRepeat)
    self.keys[key] = true
    self.keysPressed[key] = true
    
    -- Emitir evento
    EventSystem:emit(EventSystem.EVENTS.KEY_PRESS, key, scancode, isRepeat)
    
    -- Verificar callbacks
    if self.callbacks[key] then
        for _, cb in ipairs(self.callbacks[key]) do
            cb(true)
        end
    end
end

-- Manejar tecla liberada
function InputManager:handleKeyReleased(key, scancode)
    self.keys[key] = false
    self.keysReleased[key] = true
    
    -- Emitir evento
    EventSystem:emit(EventSystem.EVENTS.KEY_RELEASE, key, scancode)
    
    -- Verificar callbacks
    if self.callbacks[key] then
        for _, cb in ipairs(self.callbacks[key]) do
            cb(false)
        end
    end
end

-- Verificar si una tecla está presionada
function InputManager:isDown(key)
    return self.keys[key] == true
end

-- Verificar si una tecla fue presionada este frame
function InputManager:isPressed(key)
    return self.keysPressed[key] == true
end

-- Verificar si una tecla fue liberada este frame
function InputManager:isReleased(key)
    return self.keysReleased[key] == true
end

-- Limpiar estados de pressed/released
function InputManager:clearFrameState()
    self.keysPressed = {}
    self.keysReleased = {}
    self.mouse.buttonsPressed = {}
    self.mouse.buttonsReleased = {}
    self.mouse.wheel = 0
end

-- Obtener columna para una tecla
function InputManager:getColumnFromKey(key)
    return self.keyMap[key] or self.extendedKeyMap[key]
end

-- Obtener todas las teclas para una columna
function InputManager:getKeysForColumn(column)
    local keys = {}
    for key, col in pairs(self.keyMap) do
        if col == column then
            table.insert(keys, key)
        end
    end
    return keys
end

-- Manejar mouse presionado
function InputManager:handleMousePressed(x, y, button, isTouch)
    self.mouse.buttons[button] = true
    self.mouse.buttonsPressed[button] = true
    
    EventSystem:emit(EventSystem.EVENTS.MOUSE_PRESS, x, y, button, isTouch)
end

-- Manejar mouse liberado
function InputManager:handleMouseReleased(x, y, button, isTouch)
    self.mouse.buttons[button] = false
    self.mouse.buttonsReleased[button] = true
    
    EventSystem:emit(EventSystem.EVENTS.MOUSE_RELEASE, x, y, button, isTouch)
end

-- Manejar movimiento de mouse
function InputManager:handleMouseMoved(x, y, dx, dy, isTouch)
    self.mouse.x = x
    self.mouse.y = y
    self.mouse.dx = dx
    self.mouse.dy = dy
end

-- Manejar wheel
function InputManager:handleWheelMoved(x, y)
    self.mouse.wheel = y
end

-- Verificar si botón de mouse está presionado
function InputManager:isMouseDown(button)
    return self.mouse.buttons[button] == true
end

-- Obtener posición del mouse
function InputManager:getMousePosition()
    return self.mouse.x, self.mouse.y
end

-- Agregar joystick
function InputManager:addJoystick(joystick)
    table.insert(self.joysticks, joystick)
end

-- Remover joystick
function InputManager:removeJoystick(joystick)
    for i, js in ipairs(self.joysticks) do
        if js == joystick then
            table.remove(self.joysticks, i)
            return
        end
    end
end

-- Manejar axis de joystick
function InputManager:handleJoystickAxis(joystick, axis, value)
    -- Por implementar según necesidad
end

-- Manejar botón de joystick presionado
function InputManager:handleJoystickPressed(joystick, button)
    -- Por implementar según necesidad
end

-- Manejar botón de joystick liberado
function InputManager:handleJoystickReleased(joystick, button)
    -- Por implementar según necesidad
end

-- Registrar callback para una tecla
function InputManager:registerCallback(key, callback)
    if not self.callbacks[key] then
        self.callbacks[key] = {}
    end
    table.insert(self.callbacks[key], callback)
end

-- Actualizar
function InputManager:update(dt)
    self:clearFrameState()
end

return InputManager