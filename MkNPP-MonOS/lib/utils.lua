_G.utils = {}

function utils.inBounds(val, min, max)
    if val > max or val < min then
        return false
    end

    return true
end

function utils.allToStr(...)
    local params = table.pack(...)
    local dataBuffer = ""

    for _, val in ipairs(params) do
        dataBuffer = dataBuffer .. tostring(val)
    end
    return dataBuffer
end
