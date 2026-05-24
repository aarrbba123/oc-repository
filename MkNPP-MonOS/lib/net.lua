--- Basic networking library

_G.networking = {}
_G.networking.transmitBuffer = {}

local invoke = component.invoke

function networking.getMaxSendSize()
    return computer.getDeviceInfo("modem")[component.modem]["capacity"]
end

function networking.isOpen(port)
    return invoke(component.modem, "isOpen", port)
end

function networking.open(port)
    return invoke(component.modem, "open", port)
end

function networking.close(port)
    return invoke(component.modem, "close", port)
end

function networking.send(netAddr, port, ...)
    table.insert(networking.transmitBuffer, {netAddr, port, ...})
end

-- Fragmentation my beloved
function networking.processTransmitBuffer()
    local newBuffer = {}
    for _, packetData in ipairs(networking.transmitBuffer) do
        local sent = invoke(component.modem, "send", table.unpack(packetData))
        if not sent then
            table.insert(newBuffer, packetData)
        end
    end
    
    _G.networking.transmitBuffer = newBuffer
end
