--[[
    RITMINITY - Main Entry Point
    Videojuego de Ritmo Profesional
    Motor: Love2D
    Autor: Ritminity Team
]]

-- Carga de configuración global
local config = require("conf")

-- Módulos del core
local Logger = require("src.core.logger")
local EventSystem = require("src.core.event")
local ResourceManager = require("src.core.resource")
local StateManager = require("src.core.state")
local InputManager = require("src.input.manager")
local AudioManager = require("src.audio.manager")
local RenderManager = require("src.render.manager")
local NetworkManager = require("src.network.manager")

-- Estados del juego
local MainMenu = require("src.ui.screens.mainmenu")
local Gameplay = require("src.ui.screens.gameplay")
local SongSelect = require("src.ui.screens.songselect")
local Editor = require("src.ui.screens.editor")
local Results = require("src.ui.screens.results")
local Settings = require("src.ui.screens.settings")
local Multiplayer = require("src.ui.screens.multiplayer")
local Login = require("src.ui.screens.auth.login")
local Register = require("src.ui.screens.auth.register")

-- Variables globales
RITMINITY = {
    version = "1.0.0",
    running = true,
    paused = false,
    currentScreen = nil,
    profile = nil,
    session = {
        score = 0,
        combo = 0,
        maxCombo = 0,
        accuracy = 0,
        grade = "F",
        mods = {},
        time = 0
    }
}

-- Logger global
local log = Logger.new()

-- Función de inicialización
function love.load(arg)
    -- Configurar logger
    log:info("RITMINITY v" .. RITMINITY.version .. " initializing...")
    
    -- Configurar pantalla
    love.window.setTitle("RITMINITY")
    love.window.setMode(config.screen.width, config.screen.height, {
        fullscreen = config.screen.fullscreen,
        vsync = config.screen.vsync,
        msaa = config.screen.msaa
    })
    
    -- Inicializar sistemas
    EventSystem:initialize()
    ResourceManager:initialize()
    InputManager:initialize()
    AudioManager:initialize()
    RenderManager:initialize()
    NetworkManager:initialize()
    StateManager:initialize()
    
    -- Registrar estados
    StateManager:register("mainmenu", MainMenu)
    StateManager:register("gameplay", Gameplay)
    StateManager:register("songselect", SongSelect)
    StateManager:register("editor", Editor)
    StateManager:register("results", Results)
    StateManager:register("settings", Settings)
    StateManager:register("multiplayer", Multiplayer)
    StateManager:register("auth.login", Login)
    StateManager:register("auth.register", Register)
    
    -- Estado inicial
    StateManager:change("mainmenu")
    
    log:info("RITMINITY initialized successfully")
end

-- Loop principal de actualización
function love.update(dt)
    -- Limitar delta time para evitar saltos
    dt = math.min(dt, config.performance.maxDeltaTime)
    
    -- Actualizar managers (excepto Input, que debe ser al final)
    AudioManager:update(dt)
    NetworkManager:update(dt)
    ResourceManager:update(dt)
    
    -- Actualizar estado actual
    if StateManager.current then
        StateManager.current:update(dt)
    end
    
    -- Procesar eventos
    EventSystem:update(dt)
    
    -- Limpiar frame actual de inputs al final
    InputManager:update(dt)
end

-- Loop principal de renderizado
function love.draw()
    -- Limpiar pantalla
    love.graphics.clear(0.05, 0.05, 0.1, 1)
    
    -- Renderizar estado actual
    if StateManager.current then
        StateManager.current:draw()
    end
    
    -- UI overlay (FPS, etc)
    if config.debug.enabled and config.debug.showFPS then
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.setColor(1, 1, 1, 0.7)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.print("RITMINITY v" .. RITMINITY.version, 10, 25)
    end
end

-- Manejo de eventos de teclado
function love.keypressed(key, scancode, isRepeat)
    InputManager:handleKeyPressed(key, scancode, isRepeat)
    
    if StateManager.current and StateManager.current.handleInput then
        StateManager.current:handleInput(key, scancode, isRepeat)
    end
    
    -- Atajos globales
    if key == "escape" then
        if StateManager.current and StateManager.current.onEscape then
            StateManager.current:onEscape()
        end
    elseif key == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
    elseif key == "f12" then
        -- Captura de pantalla
        local screenshot = love.graphics.newScreenshot()
        screenshot:encode("ritminity_screenshot_" .. os.time() .. ".png")
    end
end

function love.keyreleased(key, scancode)
    InputManager:handleKeyReleased(key, scancode)
    
    if StateManager.current and StateManager.current.keyreleased then
        StateManager.current:keyreleased(key, scancode)
    end
end

-- Manejo de eventos de mouse
function love.mousepressed(x, y, button, isTouch)
    InputManager:handleMousePressed(x, y, button, isTouch)
    if StateManager.current and StateManager.current.mousepressed then
        StateManager.current:mousepressed(x, y, button, isTouch)
    end
end

function love.mousereleased(x, y, button, isTouch)
    InputManager:handleMouseReleased(x, y, button, isTouch)
    if StateManager.current and StateManager.current.mousereleased then
        StateManager.current:mousereleased(x, y, button, isTouch)
    end
end

function love.mousemoved(x, y, dx, dy, isTouch)
    InputManager:handleMouseMoved(x, y, dx, dy, isTouch)
    if StateManager.current and StateManager.current.mousemoved then
        StateManager.current:mousemoved(x, y, dx, dy, isTouch)
    end
end

function love.wheelmoved(x, y)
    InputManager:handleWheelMoved(x, y)
end

-- Manejo de focus
function love.focus(focused)
    if not focused then
        RITMINITY.paused = true
        log:info("Application paused (focus lost)")
    else
        RITMINITY.paused = false
        log:info("Application resumed (focus gained)")
    end
end

-- Manejo de cierre
function love.quit()
    log:info("RITMINITY shutting down...")
    
    -- Limpiar recursos
    ResourceManager:cleanup()
    AudioManager:cleanup()
    NetworkManager:cleanup()
    
    log:info("RITMINITY closed successfully")
    return false
end

-- Configuración de joystick
function love.joystickadded(joystick)
    log:info("Joystick connected: " .. joystick:getName())
    InputManager:addJoystick(joystick)
end

function love.joystickremoved(joystick)
    log:info("Joystick disconnected: " .. joystick:getName())
    InputManager:removeJoystick(joystick)
end

-- Configuración de joystick axis
function love.joystickaxis(joystick, axis, value)
    InputManager:handleJoystickAxis(joystick, axis, value)
end

function love.joystickpressed(joystick, button)
    InputManager:handleJoystickPressed(joystick, button)
end

function love.joystickreleased(joystick, button)
    InputManager:handleJoystickReleased(joystick, button)
end