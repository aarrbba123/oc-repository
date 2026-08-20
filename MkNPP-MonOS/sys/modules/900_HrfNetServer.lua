--- Hrf3-net server

local port = 12930

--- List of users, and their passwords; if not nil
--- For persistence, it should append/insert; not overwrite.
local users = {
    ["admin"] = "MonOSP@ss1234!"
}

--- hrf3-net protocol version.
local protocolVer = {2, 0}

--- System information
local sysInfo = {
    ["version"] = {
        ["major"] = 1,
        ["minor"] = 4,
        ["patch"] = 0
    }
}

--- How large should the data be before it gets fragmented into multiple packets
local fragSize = 5 * 1024

local tcpInfo = {
    ["TIMEOUT"] = 5,
    ["TOLERANCE"] = 3
}

--- Removes invalid hrf3-net packets. Essentally `true` means it blocks any hrf3-net packet that is invalid,
--- preventing scripts/programs ran later than this program from processing said hrf3-net packet.
--- Please note that re-registered events have the same lifetime, meaning that it will get removed as if it wasn't even processed at all.
--- This is to protect from a OOM crash caused by DoS/DDoS
local removeOnInvalid = true

--- A list of commands supported and processed by the server
--- Realistically, `DEC` and `ACK` are not processed since this is not a client.
--- Oh, and `LOG_DAT` and `GEN_DAT`? Not really processed & acted on.
local supportedCMD = {"GEN_REQ", "SYS_REQ", "PNG"}

--- Supported buffer types
--- `LOG` and `OUT` are the same here, btw.
local supportedBufType = {"LOG", "OUT", "ERR"}

--- Supported General Requests
local supportedGRQ = {"CMD", "MOD", "VER"}

--- Supported System Requests
local supportedSRQ = {"LOG", "ERR", "CMDS", "INFO", "LOGIN", "LIST", "READ", "WRITE"}

--- Context for sending fragmented packets; or access control.
--- the KEY should be the sender's address
--- TODO: send context data
--- UnTODO: Data 
local addrContext = {}

--- Serialization-related stuff
--- Useless, since we replaced it with a more advanced version of the basic serialization
local seperator = string.char(81)

--- Transmits a decline packet
---@param senderAddr string Sender's address to send to
---@param invReason string Reason for decline
---@param ... any Additional decline data
local function transmitInvalidPacket(senderAddr, invReason, ...)
    local reasonTbl = table.pack(...)
    networking.send(senderAddr, port, "hrf3-net", "DEC", invReason, serialization.serializeMonOS(reasonTbl))
end

---Transmits an Acknowledge packet
---@param senderAddr string Sender's address to send to
local function transmitAckPacket(senderAddr)
    networking.send(senderAddr, port, "hrf3-net", "ACK")
end

---Transmits a General Data packet
---@param senderAddr string Sender's address to send to
---@param ... any Additional data
local function transmitGenDataPacket(senderAddr, ...)
    networking.send(senderAddr, port, "hrf3-net", "GEN_DAT", ...)
end

---Transmits a System Data packet
---@param senderAddr string Sender's address to send to
---@param ... any Additional data
local function transmitSysDataPacket(senderAddr, ...)
    networking.send(senderAddr, port, "hrf3-net", "SYS_DAT", ...)
end

--- TCP MODE EXCLUSIVE PACKETS ---

---Transmits a TCP Disconnect Packet
---@param senderAddr string Sender's address to send to
---@param reason string Reason Code
local function transmitTCPDisconnectPacket(senderAddr, reason)
    networking.send(senderAddr, port, "hrf3-net", "TCP_DSC", reason)
end

---Transmits a TCP Data Packet
---@param senderAddr string Sender's address to send to
---@param packetID number The ID of the packet
---@param data string The data, serialized.
local function transmitTCPDataPacket(senderAddr, packetID, data)
    networking.send(senderAddr, port, "hrf3-net", "TCP_DAT", packetID, data)
end

---Transmits a TCP Start Packet
---@param senderAddr string Sender's address to send to
---@param header table The TCP header
local function transmitTCPStartPacket(senderAddr, header)
    networking.send(senderAddr, port, "hrf3-net", "TCP_ST", serialization.serializeMonOS(header))
end

--[[
local function parsePacket(evtDat)
    local dataSize = #evtDat - 5
    if dataSize < 2 then
        return false
    end

    local _, sendAddr, port, dist, netID, netCMD = table.unpack(evtDat, 2, 7)
    if (type(netID) ~= "string" or type(netCMD) ~= "string") or netID ~= "hrf3-net" then
        return false
    end

    -- Anything after here is based on a hrf3-net standard.

    if not validateList(supportedCMD, netCMD) then
        transmitInvalidPacket(sendAddr, "INV_CMD", "Invalid hrf3-net command '" .. utils.capStrToSize(netCMD, 255, "...") .. "'!")
        return removeOnInvalid
    end

    -- Command parsing
    if netCMD == "GEN_REQ" then
        if dataSize < 3 then
            transmitInvalidParamPacket(sendAddr, 3)
            return removeOnInvalid
        end

        local netSubCMD = evtDat[8]
        if type(netSubCMD) ~= "string" or not validateList(supportedGRQ, netSubCMD) then
            transmitInvalidSubCMDPacket(sendAddr, netSubCMD)
            return removeOnInvalid
        end

        -- subcommand parsing
        if netSubCMD == "CMD" then
            networking.send(sendAddr, port, "hrf3-net", "GEN_DAT", "CMD", serializeBasic(supportedCMD))
            return true
        elseif netSubCMD == "MOD" then
            networking.send(sendAddr, port, "hrf3-net", "GEN_DAT", "MOD", "BASIC", string.byte(seperator))
            return true
        elseif netSubCMD == "VER" then
            networking.send(sendAddr, port, "hrf3-net", "GEN_DAT", "VER", table.unpack(protocolVer))
        end

    elseif netCMD == "LOG_REQ" then
        if dataSize < 4 then
            transmitInvalidParamPacket(sendAddr, 4)
            return removeOnInvalid
        end

        local logType, netSubCMD = table.unpack(evtDat, 8, 9)
        if type(logType) ~= "string" or not validateList(supportedBufType, logType) then
            transmitInvalidBufPacket(sendAddr, logType)
            return removeOnInvalid
        elseif type(netSubCMD) ~= "string" or not validateList(supportedLRQ, netSubCMD) then
            transmitInvalidSubCMDPacket(sendAddr, netSubCMD)
            return removeOnInvalid
        end

        -- subcommand parsing
        if netSubCMD == "LEN" then
            networking.send(sendAddr, port, "hrf3-net", "LOG_DAT", logType, "LEN", #_G[getBufferNFromType(logType)])
            return true

        elseif netSubCMD == "LOG" then
            if dataSize < 6 then
                transmitInvalidParamPacket(sendAddr, 6)
                return removeOnInvalid
            end

            local fline, lline = table.unpack(evtDat, 10, 11)
            if type(fline) ~= "number" or type(lline) ~= "number" then
                transmitInvalidPacket(sendAddr, "INV_PRM", "Expected first line and last line paramater to be a number!")
                return removeOnInvalid
            end

            -- secondary check to prevent error
            local bufDat = getBufferNFromType(logType)
            if not bufDat then
                transmitInvalidBufPacket(sendAddr, bufDat)
                return removeOnInvalid
            end
            transmitLogs(sendAddr, bufDat, fline, lline)
            return true
        end

    elseif netCMD == "PNG" then
        networking.send(sendAddr, port, "hrf3-net", "ACK")
        computer.beep(".")

        return true
    end
end
]]--

local function doParamCheck(setLen, addr, checkLen)
    if checkLen < setLen then
        transmitInvalidPacket(addr, "INV_LEN", "Expected at least " .. tostring(setLen) .. " paramaters(s), got " .. tostring(checkLen) .. "!")
        return false

    end

    return true
end

local function parsePacket(eventTbl)
    -- Basic length check; since the first 5 is modem event data and the other 2 is the magic and command
    if #eventTbl < 7 then
        return false
    end

    -- sender address
    local sender = eventTbl[2]

    -- finally, only packet-related data
    local pktData = table.pack(table.unpack(eventTbl, 6, #eventTbl))

    -- Basic header check, only sending a dec on a valid magic, but invalid command
    if pktData[1] ~= "hrf3-net" then
        return false
    end
    if not utils.inList(supportedCMD, pktData[2]) then
        transmitInvalidPacket(sender, "INV_CMD")
        return removeOnInvalid
    end

    -- The actual command parser
    local command = pktData[2]
    if command == "PNG" then
        transmitAckPacket(sender)
        computer.beep('.')
        return true

    elseif command == "GEN_REQ" then
        if #pktData < 3 then
            transmitInvalidPacket(sender, "INV_LEN", "Expected at least 1 paramater(s), got None!")
            return removeOnInvalid
        elseif not utils.inList(supportedGRQ, pktData[3]) then
            transmitInvalidPacket(sender, "INV_SUB_CMD", "Subcommand '" .. pktData[3] .. "' not supported/valid!")
            return removeOnInvalid
        end

        -- Subcommand parser for General Requests
        local subcommand = pktData[3]
        if subcommand == "VER" then
            transmitGenDataPacket(sender, table.unpack(protocolVer))
            return true

        elseif subcommand == "MOD" then
            transmitGenDataPacket(sender, "MONOS")
            return true

        elseif subcommand == "CMD" then
            transmitGenDataPacket(sender, serialization.serializeMonOS(supportedCMD))
            return true

        end

    elseif command == "SYS_REQ" then
        if not doParamCheck(3, sender, #pktData) then
            return removeOnInvalid
        elseif not utils.inList(supportedGRQ, pktData[3]) then
            transmitInvalidPacket(sender, "INV_SUB_CMD", "Subcommand '" .. pktData[3] .. "' not supported/valid!")
            return removeOnInvalid
        end

        -- Subcommand parser for System Requests
        local subcommand = pktData[3]
        if subcommand == "CMDS" then
            transmitSysDataPacket(sender, serialization.serializeMonOS(supportedSRQ))
            return true

        elseif subcommand == "INFO" then
            transmitSysDataPacket(sender, serialization.serializeMonOS(sysInfo))
            return true

        elseif subcommand == "LOGIN" then
            -- Length check
            if not doParamCheck(5, sender, #pktData) then
                return removeOnInvalid
            end

            -- User and passwd check
            local user = tostring(pktData[4])
            if users[user] == nil then
                transmitInvalidPacket(sender, "INV_LOGIN", "Invalid login, please try again")
                return removeOnInvalid

            end

            local passwd = pktData[5]
            if passwd ~= users[user] then
                transmitInvalidPacket(sender, "INV_LOGIN", "Invalid login, please try again")
                return removeOnInvalid

            end

            addrContext[sender] = {
                ["user"] = user
            }

            transmitAckPacket(sender)
            return true

        elseif subcommand == "LOGOUT" then
            -- Credential check
            if addrContext[sender] == nil then
                transmitInvalidPacket(sender, "INV_LOGIN", "Not logged in.")
                return removeOnInvalid

            end

            addrContext[sender] = nil

            transmitAckPacket(sender)
            return true

        elseif subcommand == "LIST" then
            -- Length check
            if not doParamCheck(4, sender, #pktData) then
                return removeOnInvalid
            end

            -- Paramater check
            if type(pktData[4]) ~= "string" then
                transmitInvalidPacket(sender, "INV_PRM", "Invalid paramater!")
                return removeOnInvalid

            end

            -- Access check
            if addrContext[sender] == nil then
                transmitInvalidPacket(sender, "ACC_DENIED", "Invalid credentials, access is denied.")
                return removeOnInvalid

            end

            -- Path check
            if not component.invoke(BOOTADDR, "exists", pktData[4]) or not component.invoke(BOOTADDR, "list", pktData[4]) then
                transmitInvalidPacket(sender, "INV_PATH", "Invalid PATH '" .. pktData[4] .. "'!")
                return removeOnInvalid

            end

            transmitSysDataPacket(sender, serialization.serializeMonOS(component.invoke(BOOTADDR, "list")))
            return true

        elseif subcommand == "READ" then
            -- Length check
            if not doParamCheck(4, sender, #pktData) then
                return removeOnInvalid
            end

            -- Paramater check
            if type(pktData[4]) ~= "string" then
                transmitInvalidPacket(sender, "INV_PRM", "Invalid paramater!")
                return removeOnInvalid

            end

            -- Access check
            if addrContext[sender] == nil then
                transmitInvalidPacket(sender, "ACC_DENIED", "Invalid credentials, access is denied.")
                return removeOnInvalid

            end

            -- File check
            if not component.invoke(BOOTADDR, "exists", pktData[4]) or component.invoke(BOOTADDR, "list", pktData[4]) then
                transmitInvalidPacket(sender, "INV_PATH", "Invalid PATH '" .. pktData[4] .. "'!")
                return removeOnInvalid

            end

            -- Start TCP mode
            local header = utils.deepcopy(tcpInfo)
            header["PACKETAMT"] = math.ceil(component.invoke(BOOTADDR, "size", pktData[4]) / fragSize)
            transmitTCPStartPacket(sender, header)

            addrContext[sender]["TCP_context"] = {
                ["code"] = {"system", "read", pktData[4], 0},
                ["timestamp"] = computer.uptime(),
                ["amt_resent"] = 0,
                ["packet_amt"] = header["PACKETAMT"],
                ["is_client"] = false
            }

            return true

        elseif subcommand == "WRITE" then
            -- Length check
            if not doParamCheck(4, sender, #pktData) then
                return removeOnInvalid
            end

            -- Paramater check
            if type(pktData[4]) ~= "string" then
                transmitInvalidPacket(sender, "INV_PRM", "Invalid paramater!")
                return removeOnInvalid

            end

            -- Access check
            if addrContext[sender] == nil then
                transmitInvalidPacket(sender, "ACC_DENIED", "Invalid credentials, access is denied.")
                return removeOnInvalid

            end

            -- File (well, folder) check & non-folder check
            if not component.invoke(BOOTADDR, "exists", utils.getParentPath(pktData[4])) or component.invoke(BOOTADDR, "list", pktData[4]) then
                transmitInvalidPacket(sender, "INV_PATH", "Invalid PATH '" .. pktData[4] .. "'!")
                return removeOnInvalid

            end

            -- Start TCP Mode, but as client instead.
            transmitAckPacket(sender)

            -- Instead of storing data in here, append recieved data to file <filename>.tmp, before deleting the original file and
            -- renaming the new file, if the original file exists
            addrContext[sender]["TCP_context"] = {
                ["code"] = {"system", "write", pktData[4], 0},
                ["is_client"] = true
            }

        end

    end
    -- TODO: TCP Mode support

end

local function handleTimeout()
    for sender, val in pairs(addrContext) do
        if val["TCP_context"] ~= nil then
            local context = val["TCP_context"]

            local diffTime = computer.uptime() - context["timestamp"]
            if diffTime >= tcpInfo["TIMEOUT"] then
                if context["amt_resent"] < tcpInfo["TOLERANCE"] then
                    if context["prev_packet"] ~= nil then
                        transmitTCPDataPacket(sender, table.unpack(context["prev_packet"]))
                    else
                        local header = utils.deepcopy(tcpInfo)
                        header["PACKETAMT"] = context["packet_amt"]
                        transmitTCPStartPacket(sender, header)
                    end

                   context["packet_amt"] = context["packet_amt"] + 1
                else
                    -- drop connection
                    transmitTCPDisconnectPacket(sender, "TIMEOUT")
                    val["TCP_context"] = nil

                end

            end

        end
    end
end

local function HrfNetServer()
    if not networking.isOpen(12930) then
        networking.open(12930)
    end

    local evtTbl = event.pullEvents("modem_message")
    local repushEvtTbl = {}
    for _, pck in ipairs(evtTbl) do
        if not parsePacket(pck) then
            table.insert(repushEvtTbl, pck)
        end
    end

    -- TCP-mode timeout handler
    handleTimeout()

    -- re-push events
    event.repushEvents(repushEvtTbl)
end
klib.registerModule(HrfNetServer)
print("Hrf3-Net Server V2 registered successfully!")
