--- Basic networking library

_G.networking = {}

networking.driver = component.list("modem")()

function networking.transmitLogs(type, startIndex, endIndex)
    local maxTransmitSize = 
end
