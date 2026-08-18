-- New and improved serialization library

_G.serialization = {}

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
    local entryLen = 0

    if #tbl ~= 0 then
        for _, val in ipairs(tbl) do
            local serVal = ""
            local vType = type(val)

            if vType == "string" then
                serVal = _StrToMonOS(val)

            elseif vType == "number" then
                serVal = _NumToMonOS(val)

            elseif vType == "boolean" then
                serVal = _BoolToMonOS(val)

            elseif vType == "table" then
                serVal = _TableToMonOS(val)

            else
                -- yea we just ignore invalid data
                entryLen = entryLen - 1

            end

            retBuf = retBuf .. _sepOnNZero(entryLen) .. serVal
            entryLen = entryLen + 1
        end

        return "t\0" .. tostring(entryLen) .. '\0' .. retBuf
    else
        -- octal escape sequences my behated
        return "t\0" .. '0'
    end
end

---The newer MonOS serialization format
---@param tblData table data to serialize
---@return string strData serialized data
function serialization.serializeMonOS(tblData)
    -- Since we are already serializing with tables, why not call the table function
    return _TableToMonOS(tblData)
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

    while ptr <= #tblData do
        local val = tblData[ptr]
        if mode == 0 then
            type = val
            if type == 't' then
                mode = 1
            else
                mode = 2
            end
            ptr = ptr + 1

        elseif mode == 1 then
            -- tables only, len get mod
            len = val
            mode = 2
            ptr = ptr + 1

        else
            -- mode 2, or data conversion
            if type == 't' then
                retBuf.insert(_MonOSToTable(table.pack(table.unpack(tblData, ptr, ptr + len))))
                ptr = ptr + len
                
            elseif type == 's' then
                retBuf.insert(_MonOSToString(val))
                ptr = ptr + 1

            elseif type == 'n' then
                retBuf.insert(_MonOSToNumber(val))
                ptr = ptr + 1

            elseif type == 'b' then
                retBuf.insert(_MonOSToBool(val))
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

function serialization.deserializeMonOS(strData)
    local bufData = _split(strData, '\0')
    if #bufData < 3 then
        return {}
    else
        return _MonOSToTable(table.pack(table.unpack(bufData, 3, #bufData)))
    end
end
