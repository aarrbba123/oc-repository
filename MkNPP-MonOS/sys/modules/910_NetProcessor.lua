local function processNetworkSend()
    networking.processTransmitBuffer()
end
klib.registerModule(processNetworkSend)
