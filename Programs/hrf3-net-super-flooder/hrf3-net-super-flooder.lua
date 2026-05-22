local params = table.pack(...)

if #params < 2 or (type(tonumber(params[1])) ~= "number" or type(params[2]) ~= "string") then
    print("hrf3-net-super-flooder.lua [PORT] [DEATH MODE (y/n)]")
    os.exit()
end

local modem = component.modem
local port = tonumber(params[1])

local locallyManaged = false
local maxSendSize = tonumber(computer.getDeviceInfo()[component.modem.address]["capacity"])
if not modem.isOpen(port) then
    locallyManaged = true
    modem.open(port)
    print("Opened hrf3-net port @ ", params[1])
end

local deathMode = false
if params[2] == "y" then
    deathMode = true
    print("DEATH MODE ENGAGED, TIME TO KILL THEM!!!")
end

local sendBuffer = "PNG"
if deathMode then
    sendBuffer = ""
    for i = 15, maxSendSize do
        sendBuffer = sendBuffer .. "L"
    end
end

while true do
    local val = event.pull(0, "interrupted")
    if val ~= nil then
        print("Interrupted")
        break
    end
    local st = modem.broadcast(port, "hrf3-net", sendBuffer)
end

if locallyManaged then
    modem.close(port)
end
