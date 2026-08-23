-- Common interactive code shared between hrf3-net programs
-- OpenOS-only, obviously.

local net = require("hrf3-net-core")
local ser = require("monos-serialization")
local term = require("term")

local interactive = {}

local function getStrRem(str, len)
    return len - #str
end

local function printTable(header, elements, padding)
    if padding == nil then
        padding = 1
    end

    local lenTable = {}
    for row, data in ipairs(elements) do
        for col, val in ipairs(data) do
            lenTable[col] = math.max(#tostring(val) + padding, lenTable[col] or padding)
        end
    end

    -- The actual printing part
    for col, val in ipairs(header) do
        term.write(val .. string.rep(" ", getStrRem(val, lenTable[col])), false)
    end

    for row, tbl in ipairs(elements) do
        for col, val in ipairs(tbl) do
            term.write(val .. string.rep(" ", getStrRem(val, lenTable[col])), false)
        end
        term.write("\n")
    end

end

---An interactive address chooser
---@param modem table Modem proxy to use
---@param timeout number How long to wait, in seconds, before timing out.
---@return number? index The chosen index of the return table. `nil` if no servers found
---@return table? packets The list of packets. `nil` if no servers found
interactive.chooseAddr = function(modem, timeout)
    local res = net.scan(modem, timeout)
    if #res == 0 then
        return nil, nil
    elseif #res == 1 then
        return 1, res
    end

    local val = 1

    return val, res

end

return interactive
