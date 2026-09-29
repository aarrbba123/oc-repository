-- Core utils (i.e string split, etc)

local utils = {}

--- LIST UTILS ---

function utils.inTable(tbl, val)
    for _, chk in pairs(tbl) do
        if val == chk then
            return true
        end
    end

    return false
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

--- STRING MANIPULATION ---

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

---Replace a string at val with rep
---@param str string Original string
---@param val string String to be replaced
---@param rep string String to replace with
---@param amt number? How much to replace. If nil, will replace all occurences
---@return string repString replaced string
function utils.replace(str, val, rep, amt)
    return string.gsub(str, "([^" .. val .. "]+)", rep, amt)[0]
end

return utils
