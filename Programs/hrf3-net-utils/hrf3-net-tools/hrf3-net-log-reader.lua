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

local hrfNetBuffer = {}

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

local function absorbHrfNetPackets(...)
    local packet = table.pack(...)
    
end

-- TL;DR: Ping, wait 1-2s, grab stored (n' valid) hrf3-net packets to find valid servers,
-- Get Serialization Mode & Command List & Logging buffer (if exists)
if not mdm.isOpen(port) then
    locallyManaged = true
    mdm.open(port)
    print("Opened @ port " .. tostring(port))
end

mdm.broadcast(port, "hrf3-net", "PNG")
