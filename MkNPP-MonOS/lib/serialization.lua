-- New and improved serialization library

_G.serialization = {}

serialization.serializationVersion = {
    ["MonOS"] = 1
}

function serialization.serializeBasic(tblData, sepChar)
    if #tblData ~= 0 then
        local retData = tblData[1]
        for i = 2, #tblData do
            local val = tblData[i]
            retData = retData .. sepChar .. val
        end

        return retData
    else
        return ""
    end
end

---Local string.split function, because luan't
---@param str string String to split
---@param delim string String character to split with
---@return table splittedStr Splitted string
local function _split(str, delim)
    local retBuf = {}
    for tk in string.gmatch(str, "([^" .. delim .. "]+)") do
        table.insert(retBuf, tk)
    end

    return retBuf
end

---The old serialization function, but in reverse. Uses a seperator char to split strings.
---@param strData any
---@param sepChar any
---@return table
function serialization.deserializeBasic(strData, sepChar)
    if #strData ~= 0 then
        return _split(strData, sepChar)
    else
        return {}
    end
end

local function _StrToMonOS(str)
    -- yea you kinda have to sanitize the str to prevent accidental seperation
    local sanStr = ""
    for i = 1, #str, 1 do
        local chr = str[i]
        if chr == "\0" then
            sanStr = sanStr .. "\\0"
        elseif chr == "\\" then
            sanStr = sanStr .. "\\\\"
        else
            sanStr = sanStr .. chr
        end
    end

    return "s\0" .. sanStr
end

local function _NumToMonOS(num)
    return "n\0" .. tostring(num)
end

local function _BoolToMonOS(yn)
    if yn == true then
        return "b\0true"
    else
        return "b\0false"
    end
end

local function _sepOnNZero(num)
    if num > 0 then
        return '\0'
    else
        return ''
    end
end

local function _TableToMonOS(tbl)
    local retBuf = ""
    local entryLen = 2

    if #tbl ~= 0 then
        for key, val in pairs(tbl) do
            local serVal = ""
            local vType = type(val)

            if vType == "string" then
                serVal = _sepOnNZero(entryLen - 2) .. tostring(key) .. '\0' .. _StrToMonOS(val)
                entryLen = entryLen + 3

            elseif vType == "number" then
                serVal = _sepOnNZero(entryLen - 2) .. tostring(key) .. '\0' .. _NumToMonOS(val)
                entryLen = entryLen + 3

            elseif vType == "boolean" then
                serVal = _sepOnNZero(entryLen - 2) .. tostring(key) .. '\0' ..  _BoolToMonOS(val)
                entryLen = entryLen + 3

            elseif vType == "table" then
                local tblLen
                serVal, tblLen = _TableToMonOS(val)
                -- don't forget about the key
                serVal = _sepOnNZero(entryLen - 2) .. tostring(key) .. '\0' .. tostring(tblLen) .. '\0' .. serVal

                entryLen = entryLen + 1 + tblLen -- The two at the start only covers the type and length, the +1 is for the key

            end

            retBuf = retBuf .. _sepOnNZero(entryLen) .. serVal
        end

        return "t\0" .. tostring(entryLen) .. '\0' .. retBuf, entryLen
    else
        -- octal escape sequences my behated
        return "t\0" .. '0', 2
    end
end

---The newer MonOS serialization format
---@param tblData table data to serialize
---@return string strData serialized data
function serialization.serializeMonOS(tblData)
    -- Since we are already serializing with tables, why not call the table function
    return _TableToMonOS(tblData)[0]
end

local function _MonOSToBool(val)
    if val == "true" then
        return true
    else
        return false
    end
end

local function _MonOSToString(str)
    -- Time to desanitize it
    local retData = ""
    local escape = false

    for i = 1, #str, 1 do
        local chr = str[i]
        if chr == '\\' then
            if escape then
                escape = true
            else
                escape = false
                retData = retData .. '\\'
            end

        elseif chr == '0' and escape then
            escape = false
            retData = retData .. '\0'

        else
            retData = retData .. chr

        end
    end
end

local function _MonOSToNumber(num)
    return tonumber(num)
end

local function _MonOSToTable(tblData)
    local retBuf = {}
    local ptr = 1
    local mode = 0
    local type
    local len
    local key

    while ptr <= #tblData do
        local val = tblData[ptr]
        if mode == 0 then
            -- Key data retrieval mode
            if tonumber(val) ~= nil then
                key = tonumber(val)
            else
                key = val
            end

            mode = 1
            ptr = ptr + 1

        elseif mode == 1 then
            -- Type data retrieval mode
            type = val
            if type == 't' then
                mode = 2
            else
                mode = 3
            end
            ptr = ptr + 1

        elseif mode == 2 then
            -- tables only, len get mode
            len = val
            mode = 3
            ptr = ptr + 1

        else
            -- mode 3, or data conversion
            if type == 't' then
                retBuf[key] = _MonOSToTable(table.pack(table.unpack(tblData, ptr, ptr + len)))
                ptr = ptr + len + 1 -- ptr + len will just go to the end of list, the + 1 will go to the next entry

            elseif type == 's' then
                retBuf[key] = _MonOSToString(val)
                ptr = ptr + 1

            elseif type == 'n' then
                retBuf[key] = _MonOSToNumber(val)
                ptr = ptr + 1

            elseif type == 'b' then
                retBuf[key] = _MonOSToBool(val)
                ptr = ptr + 1

            else
                ptr = ptr + 1

            end

            -- reset mode
            mode = 0
        end
    end

    return retBuf
end

---The new MonOS serialization format, but in reverse
---@param strData string String to deserialize
---@return table deserializedData
function serialization.deserializeMonOS(strData)
    local bufData = _split(strData, '\0')
    if #bufData < 3 then
        return {}
    else
        return _MonOSToTable(table.pack(table.unpack(bufData, 3, #bufData)))
    end
end
