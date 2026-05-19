--- Basic networking library

_G.networking = {}
_G.networking.transmitBuffer = {}

local modem = component.modem
local invoke = component.invoke

function networking.send(netAddr, port, ...)
    table.insert(networking.transmitBuffer, {netAddr, port, ...})
end

-- Fragmentation my beloved
function networking.processTransmitBuffer()
    local newBuffer = {}
    for _, packetData in ipairs(networking.transmitBuffer) do
        local sent = invoke(modem, "send", table.unpack(packetData))
        if not sent then
            table.insert(newBuffer, packetData)
        end
    end
    
    _G.networking.transmitBuffer = newBuffer
end
