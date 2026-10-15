-- Special file for basic utility functions
-- Required by package.lua
-- Also load this first!

local utils_core = {}

utils_core.str2list = function(str, sep)
    local retBuf = {}
    for tk in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(retBuf, tk)
    end

    return retBuf
end

utils_core.inList = function(table, val)
    for _, v in pairs(table) do
        if v == val then
            return true
        end
    end
    return false
end

return utils_core
