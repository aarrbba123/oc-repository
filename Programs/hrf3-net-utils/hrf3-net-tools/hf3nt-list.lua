--- Basic script that pings and gets the address of available hrf3-net servers

local comp = require("component")
local event = require("event")
local os = require("os")

local locallyManaged = false
local modem = comp.modem
local data = {}

local function netGetter(name, recvAddr, sendAddr, port, distance, ...)
    local pktData = table.pack(...)
    if #pktData < 2 or pktData[1] ~= "hrf3-net" then
        return
    end

    table.insert(data, {recvAddr, sendAddr, port, distance, ...})

end

-- Main code

if not modem.isOpen(12930) then
    modem.open(12930)
    locallyManaged = true
end

event.listen("modem_message", netGetter)

print("Pinging...")
modem.broadcast(12930, "hrf3-net", modem.address, "PNG")
os.sleep(2)

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

event.ignore("modem_message", netGetter)

if locallyManaged then
    modem.close(12930)
end
