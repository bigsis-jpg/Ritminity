function love.load()
    local function check(dir)
        local items = love.filesystem.getDirectoryItems(dir)
        for _, item in ipairs(items) do
            local path = dir == "" and item or dir .. "/" .. item
            local info = love.filesystem.getInfo(path)
            if info.type == "directory" then
                check(path)
            elseif path:match("%.lua$") then
                local chunk, err = loadfile(path)
                if not chunk then
                    print("ERROR in " .. path .. ": " .. tostring(err))
                end
            end
        end
    end
    check("")
    print("DONE")
    love.event.quit()
end
