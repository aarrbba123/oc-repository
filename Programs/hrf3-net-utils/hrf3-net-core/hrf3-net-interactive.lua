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

interactive.chooseAddr = function(modem, timeout)
    local res = net.scan(modem, timeout)
    if #res == 0 then
        return nil
    elseif #res == 1 then
        return res[1]
    end

    -- TODO: Finish this
    local info = {}
    for _, packet in ipairs(res) do
        net.sendGenReq(modem, packet[5], "MOD")
        local modPck = table.pack(table.unpack(net.recievePacket(timeout, false, "hrf3-net", nil, "GEN_DAT"), 5))
        net.sendGenReq(modem, packet[5], "VER")
        local verPck = table.pack(table.unpack(net.recievePacket(timeout, false, "hrf3-net", nil, "GEN_DAT"), 5))
        net.sendSysReq(modem, packet[5], "INFO")
        local sysPck = ser.deserializeMonOS(net.recievePacket(timeout, false, "hrf3-net", nil, "SYS_DAT")[8]) -- Change this if we implement different serialization methods
        -- TODO: this (the getter) is ASS, session terminated.
        -- (no failsafes!?!?!?!?)
        table.insert(info, {
            ["address"] = packet[6],
            ["distance"] = packet[4],
            ["platform"] = sysPck["platform"] or "<UNKNOWN>",
            ["version"] = tostring(verPck[5]) .. tostring(verPck[6]),
            ["serialization"] = modPck[5]
        })
    end

    for i, _ in ipairs(info) do
        -- Add the number because u forgor
        info[i]["ID"] = i
    end

    local val = -1
    while val < 1 or val > #info do
        -- Print number, address, and distance, OS, (hrf3-net) version (string version), serialization.
        printTable({"ID", "address", "distance", "platform", "version", "serialization"}, info, 2)
        val = io.read("n")
        if val < 1 or val > #info then
            print("ERR: Invalid number, please input a valid number!")
        end
    end

    return val, res

end

return interactive
