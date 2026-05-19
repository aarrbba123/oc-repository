local function processNetworkSend()
    networking.processTransmitBuffer()
end
klib.registerModule(processNetworkSend)
iolib.print("Networking Send Processor registered successfully!")
