--- Basic script that pings and gets the address of available hrf3-net servers

local comp = require("component")
local event = require("event")

local locallyManaged = false
local modem = comp.modem

-- Main code

if not modem.isOpen(12930) then
    modem.open(12930)
    locallyManaged = true
end

print("Pinging...")
modem.broadcast(12930, "hrf3-net", modem.address, "PNG")

local data = {}
repeat
    local rawPkt = table.pack(event.pull(2, "modem_message", nil, nil, nil, nil, "hrf3-net", nil, "ACK"))
    local str = rawPkt[1]
    if str ~= nil then
        local pkt = table.pack(table.unpack(rawPkt, 2))
        table.insert(data, pkt)
    end
until str == nil

if #data == 0 then
    print("No valid hrf3-net servers found!")
else
    print("-----")
    print("Address.............................\tDistance")
    for _, val in ipairs(data) do
        local distance, _, sendAddr = table.unpack(val, 4, 6)
        if distance == 0 then
            print(sendAddr .. "\t0 <WIRED>")
        else
            print(sendAddr .. "\t" .. distance)
        end
    end
end

if locallyManaged then
    modem.close(12930)
end
