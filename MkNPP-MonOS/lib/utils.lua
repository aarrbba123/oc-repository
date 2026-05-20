_G.utils = {}

function utils.inBounds(val, min, max)
    if val > max or val < min then
        return false
    end

    return true
end

local function representStr(str)
    return "\"" .. str .. "\""
end

function utils.tableToStr(tab)
    local dataBuffer = "{"
    for i, val in ipairs(tab) do
        local sVal = val
        local nVal = ", "

        if type(val) == "table" then
            sVal = utils.tableToStr(val)
        elseif type(val) == "string" then
            sVal = representStr(val)
        end

        if i == #tab then
            nVal = ""
        end

        dataBuffer = dataBuffer .. tostring(sVal) .. nVal
    end
    dataBuffer = dataBuffer .. "}"
    return dataBuffer
end

function utils.allToStr(...)
    local params = table.pack(...)
    local dataBuffer = ""

    for _, val in ipairs(params) do
        local sVal = val
        if type(val) == "table" then
            -- pls don't forget to unpack the input table k thx
            sVal = utils.tableToStr(val)
        end

        dataBuffer = dataBuffer .. tostring(sVal)
    end
    return dataBuffer
end
