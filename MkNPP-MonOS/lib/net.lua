--- Basic networking library

_G.networking = {}
_G.networking.transmitBuffer = {}

networking.modem = component.list("modem")()

local modem = networking.modem

-- Yes, the function of transmitting log data is implemented in a library. This OS wasn't meant for generic usage, remember?
function networking.transmitLogs(netAddr, type, startIndex, endIndex)
    local maxTransmitSize = invoke(modem, "maxPacketSize")

    

end
