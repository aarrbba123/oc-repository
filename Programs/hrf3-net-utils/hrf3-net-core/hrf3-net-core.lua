--- Hrf3-Net Core functions
--- Provides the proprietary serialization functions
--- Also the hrf3-net v2 packet sending & validating functions
--- NOTE: Please open port 12930, or it don't do shi-

local evt = require("event")
local ser = require("monos-serialization")
local cpr = require("computer")

local function getEvent(timeout, name, ...)
    local ret = evt.pull(timeout, name, ...)
    if ret ~= nil then
        return table.pack(table.unpack({ret}, 2))
    else
        return nil
    end
end

---Copies the table, and the tables within.
---@param tblData table Table to copy from
---@return table copy Copy of the original table
local function deepcopy(tblData)
    if type(tblData) ~= "table" then
        return tblData
    end

    local retTbl = {}
    for k, v in pairs(tblData) do
        if type(v) == "table" then
            retTbl[k] = deepcopy(v)
        else
            retTbl[k] = v
        end
    end

    return retTbl

end

local hf3nt = {}

hf3nt.tcpHeader = {
    ["TIMEOUT"] = 5,
    ["TOLERANCE"] = 3
}

---Scans the network for valid hrf3-net servers
---@param modem table Modem to send and recieve the packets
---@param timeout number? How long until timeout, in seconds. Defaults to `1`
---@return table packets A list of packets
hf3nt.scan = function(modem, timeout)
    if timeout == nil then
        timeout = 1
    end

    modem.broadcast(12930, "hrf3-net", modem.address, "PNG")
    local retBuf = {}
    local data = getEvent(timeout, "modem_message", "hrf3-net", nil, "ACK")
    while data ~= nil do
        table.insert(retBuf, data)
        data = getEvent(timeout, "modem_message", "hrf3-net", nil, "ACK")
    end

    return retBuf

end

---get a packet or a list of packets
---@param timeout number? how long to wait before timing out and returning `nil`
---@param multi boolean if `true`, gets a list of packets
---@param ... any Filters to apply
---@return table? packetOrListOfPackets A packet, or a list of packets. `nil` or an empty table if no packets are found.
hf3nt.recievePacket = function(timeout, multi, ...)
    if timeout == nil then
        timeout = 1
    end

    local retData = getEvent(timeout, "modem_message", ...)
    if multi == true then
        local retBuf = {}
        while retData ~= nil do
            table.insert(retBuf, retData)
            retData = getEvent(timeout, "modem_message", ...)
        end

        return retBuf
    end

    return retData
end

--- Packet sending code

---Send an Acknowledge packet
---@param modem table The modem proxy/primary
---@param sendAddr string Address to send to
---@return boolean status `true` if successfully sent
hf3nt.sendAck = function(modem, sendAddr)
    return modem.send(sendAddr, 12930, "hrf3-net", modem.address, "ACK")
end

---Send a General Request packet
---@param modem table The modem proxy/primary
---@param sendAddr string Address to send to
---@param code string General request code to send
---@return boolean status `true` if successfully sent
hf3nt.sendGenReq = function(modem, sendAddr, code)
    return modem.send(sendAddr, 12930, "hrf3-net", modem.address, "GEN_REQ", code)
end

---Send a General Request packet
---@param modem table The modem proxy/primary
---@param sendAddr string Address to send to
---@param code string System request code to send
---@param ... any Additional paramaters to send
---@return boolean status `true` if successfully sent
hf3nt.sendSysReq = function(modem, sendAddr, code, ...)
    return modem.send(sendAddr, 12930, "hrf3-net", modem.address, "SYS_REQ", code, ...)
end

--- TCP Related code ---

---Send a TCP start packet
---@param modem table The modem proxy
---@param sendAddr string Address to send to
---@param byteSize number? The size of the data, `nil` if unspecified/continuous stream of data
---@return boolean status `true` if successfully sent
hf3nt.sendTCPStart = function(modem, sendAddr, byteSize)
    local hdr = deepcopy(hf3nt.tcpHeader)
    if byteSize ~= nil then
        hdr["PACKETAMT"] = math.ceil(byteSize / cpr.getDeviceInfo()[modem.address]["capacity"])
    else
        hdr["PACKETAMT"] = -1
    end
    return modem.send(sendAddr, 12930, "hrf3-net", modem.address, "TCP_ST", ser.serializeMonOS(hdr))
end

---Send a TCP data packet
---@param modem table The modem proxy
---@param sendAddr string Address to send to
---@param pktID number Packet ID
---@param data table A table of data, which will be serialized later.
---@return boolean status `true` if successfully sent
hf3nt.sendTCPData = function(modem, sendAddr, pktID, data)
    return modem.send(sendAddr, 12930, "hrf3-net", modem.address, "TCP_DAT", pktID, ser.serializeMonOS(data))
end

---Send a TCP disconnect packet
---@param modem table The modem proxy
---@param sendAddr string Address to send to
---@param code string The reason code for the disconnect
---@return boolean status `true` if successfully sent
hf3nt.sendTCPDisconnect = function(modem, sendAddr, code)
    return modem.send(sendAddr, 12930, "hrf3-net", modem.address, "TCP_DSC", code)
end

return hf3nt
