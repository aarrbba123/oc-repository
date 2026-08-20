_G.utils = {}

function utils.inBounds(val, min, max)
    if val > max or val < min then
        return false
    end

    return true
end

function utils.inList(list, val)
    for _, chk in ipairs(list) do
        if val == chk then
            return true
        end
    end

    return false
end

---Local string.split function, because luan't
---@param str string String to split
---@param delim string String character to split with
---@return table splittedStr Splitted string
function utils.split(str, delim)
    local retBuf = {}
    for tk in string.gmatch(str, "([^" .. delim .. "]+)") do
        table.insert(retBuf, tk)
    end

    return retBuf
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

function utils.capStrToSize(str, size, cont)
    cont = cont or ""

    if #str > size then
        return string.sub(str, 1, size - #cont) .. cont
    end
end

---Copies the table, and the tables within.
---@param tblData table Table to copy from
---@return table copy Copy of the original table
function utils.deepcopy(tblData)
    if type(tblData) ~= "table" then
        return tblData
    end

    local retTbl = {}
    for k, v in pairs(tblData) do
        if type(v) == "table" then
            retTbl[k] = utils.deepcopy(v)
        else
            retTbl[k] = v
        end
    end

    return retTbl

end

---A temporary function that gets the parent of the specified path
---@param path string Path to get parent from
---@return string parentPath the parent to the path
function utils.getParentPath(path)
    local splitPath = utils.split(path, '/')
    if #splitPath <= 1 then
        return '/'
    end

    return '/' .. table.concat(splitPath, '/', 1, #splitPath) .. '/'

end

function utils.getFreeMem()
    local ret = computer.freeMemory()
    for i = 0, 10 do
        ret = math.min(ret, computer.freeMemory())
    end
    return ret
end
