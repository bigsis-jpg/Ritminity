function love.load()
    local status, err = pcall(function()
        local generator = require("src.ai.generator")
        local ai = generator:new()
        local chart = ai:generateFromAudio("assets/songs/Buena Vida Mala Fama Speed Up (Instrumental).mp3")
        return chart
    end)
    local f = io.open("c:/Users/Vino/Downloads/ritminity/test_output.txt", "w")
    if not status then
        f:write("CRASH: " .. tostring(err))
    else
        f:write("SUCCESS")
    end
    f:close()
    love.event.quit()
end
