local generator = require("src.ai.generator")
local ai = generator:new()
local chart, err = ai:generateFromAudio("assets/songs/Buena Vida Mala Fama Speed Up (Instrumental).mp3")
if not chart then
    print("Error:", err)
else
    print("Success! Notes generated:", #chart.notes)
end
