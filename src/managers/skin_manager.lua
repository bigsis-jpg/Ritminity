--[[
    RITMINITY - Skin Manager
    Gestiona texturas y estilos visuales para el gameplay
]]

local SkinManager = {}
SkinManager.__index = SkinManager

function SkinManager:new()
    local self = setmetatable({}, SkinManager)
    self.textures = {}
    self.currentSkin = "default"
    return self
end

function SkinManager:loadSkin(skinName)
    self.currentSkin = skinName or "default"
    local path = "assets/skins/" .. self.currentSkin .. "/"
    
    -- Texturas básicas (si no existen, usaremos rectángulos)
    self.textures.note_tap = self:loadTexture(path .. "note_tap.png")
    self.textures.note_hold = self:loadTexture(path .. "note_hold.png")
    self.textures.receptor = self:loadTexture(path .. "receptor.png")
    self.textures.receptor_pressed = self:loadTexture(path .. "receptor_pressed.png")
    self.textures.column_light = self:loadTexture(path .. "column_light.png")
end

function SkinManager:loadTexture(path)
    if love.filesystem.getInfo(path) then
        return love.graphics.newImage(path)
    end
    return nil
end

function SkinManager:getNoteColor(column, totalColumns)
    -- Estilo Mania 4K (Blanco - Azul - Azul - Blanco)
    if totalColumns == 4 then
        if column == 1 or column == 4 then
            return {1, 1, 1}
        else
            return {0.3, 0.6, 1}
        end
    elseif totalColumns == 7 then
        -- 7K (Blanco - Azul - Blanco - Rojo - Blanco - Azul - Blanco)
        local colors = {
            {1, 1, 1}, {0.3, 0.6, 1}, {1, 1, 1},
            {1, 0.3, 0.3},
            {1, 1, 1}, {0.3, 0.6, 1}, {1, 1, 1}
        }
        return colors[column] or {1, 1, 1}
    end
    return {1, 1, 1}
end

return SkinManager:new()
