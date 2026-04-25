-- Simple JSON module for LUA
local json = {}

function json.encode(t)
    local function serialize(val)
        if type(val) == "table" then
            local is_array = #val > 0
            local res = is_array and "[" or "{"
            local first = true
            for k, v in pairs(val) do
                if not first then res = res .. "," end
                if not is_array then
                    res = res .. '"' .. tostring(k) .. '":'
                end
                res = res .. serialize(v)
                first = false
            end
            res = res .. (is_array and "]" or "}")
            return res
        elseif type(val) == "string" then
            return '"' .. val:gsub('"', '\\"') .. '"'
        else
            return tostring(val)
        end
    end
    return serialize(t)
end

function json.decode(s)
    -- Simple mock decoder (returns table if possible)
    -- In a real AAA project, we would use a proper C or Lua binding
    return {}
end

return json
