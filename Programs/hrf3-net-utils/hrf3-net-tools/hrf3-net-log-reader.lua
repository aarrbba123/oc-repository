-- basic network log reader

local argv = table.pack(...)

if #argv < 1 or type(tonumber(argv[1])) ~= "string" then
    print("hrf3-net-log-reader.lua [PORT] <FILENAME>")
end

local port = tonumber(argv[1])
local locallyManaged = false

local filename = nil
if #argv > 1 then
    filename = argv[2]
end

local component = require("component")
local computer = require("computer")
local event = require("event")

local addrContext = nil
local packetBuffer = {}

local mdm = component.getPrimary("modem")

local function exit()
    if locallyManaged then
        mdm.close(port)
    end
    os.exit()
end

local function checkInterrupt()
    local val = event.pull(0, "interrupted")
    if val ~= nil then
        print("Interrupted, aborting.")
        exit()
    end
end

-- Null seperated strings, while 'proprietary', is the most simplest way to serialize some strings.
local function basicDeserialize(val)
    local retBuf = {}
    local curBuf = ""
    for i = 1, #val do
        local charDat = val[i]
        if charDat == '\0' then
            table.insert(retBuf, curBuf)
            curBuf = ""
        else
            curBuf = curBuf .. charDat
        end
    end

    return retBuf
end

local function checkHrfNetPacket(netID, netCmd)
    if type(netID) ~= "string" and type(netCmd) ~= "string" then
        return false
    end

    if netID == "hrf3-net" then
        for _, chk in ipairs({"LOG_DAT", "LOG_REQ", "ACK", "DEC", "PNG"}) do
            if netCmd == chk then
                return true
            end
        end
    end
    return false
end

local function scanPackets()
    local evtTable = {}
    repeat
        local evt = table.pack(event.pull(0, "modem_message"))
        local type = evt[1]
        if type then
            table.insert(evtTable, evt)
        end
    until not type

    for _, evt in ipairs(evtTable) do
        if #evt >= 7 and checkHrfNetPacket(table.unpack(evt, 5, 6)) then
            local sender
        end
    end
end

-- Main code

print("Now working on hrf3-net @ port " .. argv[1])

while true do
    checkInterrupt()
    scanPackets()
end
