--[[
    RITMINITY - Auth Manager
    Sistema de autenticación para el cliente
]]

local json = require("json")
local http = require("socket.http")
local ltn12 = require("ltn12")
local SESSION_LIFETIME = 86400 -- 24 hours in seconds

local AuthManager = {}
AuthManager.__index = AuthManager

-- Estado de autenticación
AuthManager.state = {
    logged_in = false,
    user = nil,
    token = nil,
    expires_at = 0
}

-- URLs de la API
AuthManager.apiUrl = "http://localhost/ritminity/api"

function AuthManager:new()
    local self = setmetatable({}, AuthManager)
    self:loadSession()
    return self
end

function AuthManager:loadSession()
    -- Intentar cargar sesión desde archivo local
    local sessionData = love.filesystem.read("session.json")
    if sessionData then
        local success, data = pcall(function()
            return json.decode(sessionData)
        end)
        
        if success and data then
            self.state.user = data.user
            self.state.token = data.token
            self.state.expires_at = data.expires_at
            self.state.logged_in = (data.expires_at > os.time())
        end
    end
end

function AuthManager:saveSession()
    -- Guardar sesión en archivo local
    local sessionData = {
        user = self.state.user,
        token = self.state.token,
        expires_at = self.state.expires_at
    }
    
    local jsonData = json.encode(sessionData)
    love.filesystem.write("session.json", jsonData)
end

function AuthManager:clearSession()
    self.state = {
        logged_in = false,
        user = nil,
        token = nil,
        expires_at = 0
    }
    love.filesystem.remove("session.json")
end

function AuthManager:isLoggedIn()
    return self.state.logged_in and (self.state.expires_at > os.time())
end

function AuthManager:getUser()
    return self.state.user
end

function AuthManager:getToken()
    return self.state.token
end

function AuthManager:login(username, password, callback)
    -- Validar entrada
    if not username or username == "" then
        if callback then callback(false, "Username is required") end
        return
    end
    
    if not password or password == "" then
        if callback then callback(false, "Password is required") end
        return
    end
    
    -- Preparar datos
    local data = {
        username = username,
        password = password
    }
    
    -- Realizar petición HTTP
    local function httpRequest()
        local responseBody = {}
        local res, code, headers = http.request{
            url = self.apiUrl .. "/auth/login",
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = tostring(#json.encode(data))
            },
            source = ltn12.source.string(json.encode(data)),
            sink = ltn12.sink.table(responseBody)
        }
        
        if res == 1 and code == 200 then
            local response = json.decode(table.concat(responseBody))
            if response.success then
                self.state.user = response.user
                self.state.token = response.token
                self.state.expires_at = os.time() + SESSION_LIFETIME -- 24 horas
                self.state.logged_in = true
                self:saveSession()
                if callback then callback(true, "Login successful") end
            else
                if callback then callback(false, response.error or "Login failed") end
            end
        else
            if callback then callback(false, "Connection error: " .. tostring(code)) end
        end
    end
    
    -- Ejecutar en hilo separado para no bloquear la UI
    love.thread.newThread(httpRequest):start()
end

function AuthManager:register(username, email, password, callback)
    -- Validar entrada
    if not username or username == "" then
        if callback then callback(false, "Username is required") end
        return
    end
    
    if not email or email == "" then
        if callback then callback(false, "Email is required") end
        return
    end
    
    if not password or password == "" then
        if callback then callback(false, "Password is required") end
        return
    end
    
    if #password < 6 then
        if callback then callback(false, "Password must be at least 6 characters") end
        return
    end
    
    -- Preparar datos
    local data = {
        username = username,
        email = email,
        password = password
    }
    
    -- Realizar petición HTTP
    local function httpRequest()
        local responseBody = {}
        local res, code, headers = http.request{
            url = self.apiUrl .. "/auth/register",
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = tostring(#json.encode(data))
            },
            source = ltn12.source.string(json.encode(data)),
            sink = ltn12.sink.table(responseBody)
        }
        
        if res == 1 and code == 200 then
            local response = json.decode(table.concat(responseBody))
            if response.success then
                if callback then callback(true, "Registration successful") end
            else
                if callback then callback(false, response.error or "Registration failed") end
            end
        else
            if callback then callback(false, "Connection error: " .. tostring(code)) end
        end
    end
    
    -- Ejecutar en hilo separado para no bloquear la UI
    love.thread.newThread(httpRequest):start()
end

function AuthManager:logout(callback)
    if not self:isLoggedIn() then
        if callback then callback(true, "Already logged out") end
        return
    end
    
    -- Preparar datos
    local data = {
        token = self.state.token
    }
    
    -- Realizar petición HTTP
    local function httpRequest()
        local responseBody = {}
        local res, code, headers = http.request{
            url = self.apiUrl .. "/auth/logout",
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = tostring(#json.encode(data))
            },
            source = ltn12.source.string(json.encode(data)),
            sink = ltn12.sink.table(responseBody)
        }
        
        if res == 1 and code == 200 then
            local response = json.decode(table.concat(responseBody))
            if response.success then
                self:clearSession()
                if callback then callback(true, "Logout successful") end
            else
                if callback then callback(false, response.error or "Logout failed") end
            end
        else
            -- Incluso si falla la petición, limpiar sesión localmente
            self:clearSession()
            if callback then callback(true, "Logout successful (local)") end
        end
    end
    
    -- Ejecutar en hilo separado para no bloquear la UI
    love.thread.newThread(httpRequest):start()
end

return AuthManager