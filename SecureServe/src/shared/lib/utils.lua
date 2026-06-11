local Utils = {}

local KEY_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

function Utils.random_key(length)
    local size = tonumber(length) or 32
    size = math.floor(size)
    if size < 1 then size = 1 end

    local chars = {}
    local char_count = #KEY_CHARS

    for i = 1, size do
        local index = math.random(1, char_count)
        chars[i] = KEY_CHARS:sub(index, index)
    end

    return table.concat(chars)
end

return Utils
