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
    },
    ["platform"] = "monos"
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

--- Packet-Sending Functions ---

--- Transmits a decline packet
---@param senderAddr string Sender's address to send to
---@param invReason string Reason for decline
---@param ... any Additional decline data
local function transmitInvalidPacket(senderAddr, invReason, ...)
    local reasonTbl = table.pack(...)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "DEC", invReason, serialization.serializeMonOS(reasonTbl))
end

---Transmits an Acknowledge packet
---@param senderAddr string Sender's address to send to
local function transmitAckPacket(senderAddr)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "ACK")
end

---Transmits a General Data packet
---@param senderAddr string Sender's address to send to
---@param code string Code to re-send
---@param ... any Additional data
local function transmitGenDataPacket(senderAddr, code, ...)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "GEN_DAT", code, ...)
end

---Transmits a System Data packet
---@param senderAddr string Sender's address to send to
---@param code string Code to re-send
---@param ... any Additional data
local function transmitSysDataPacket(senderAddr, code, ...)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "SYS_DAT", code, ...)
end

--- TCP MODE EXCLUSIVE PACKETS ---

---Transmits a TCP Disconnect Packet
---@param senderAddr string Sender's address to send to
---@param reason string Reason Code
local function transmitTCPDisconnectPacket(senderAddr, reason)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "TCP_DSC", reason)
end

---Transmits a TCP Data Packet
---@param senderAddr string Sender's address to send to
---@param packetID number The ID of the packet
---@param data table The data
local function transmitTCPDataPacket(senderAddr, packetID, data)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "TCP_DAT", packetID, serialization.serializeMonOS(data))
end

---Transmits a TCP Start Packet
---@param senderAddr string Sender's address to send to
---@param header table The TCP header
local function transmitTCPStartPacket(senderAddr, header)
    networking.send(senderAddr, port, "hrf3-net", senderAddr, "TCP_ST", serialization.serializeMonOS(header))
end

--- Helper Functions ---

local function doLenCheck(setLen, addr, checkLen)
    if checkLen < setLen then
        transmitInvalidPacket(addr, "INV_LEN", "Expected at least " .. tostring(setLen) .. " paramaters(s), got " .. tostring(checkLen) .. "!")
        return false

    end

    return true
end

local function doAccessCheck(sender)
    if addrContext[sender] == nil or addrContext[sender]["user"] == nil then
        transmitInvalidPacket(sender, "ACC_DENIED", "Invalid credentials, Access is denied.")
        return false
    end

    return true
end

local function updateTCPContext(contextData)
    contextData["timestamp"] = computer.uptime()
    contextData["amt_resent"] = 0
end

-- TODO: Fix whatever tf broke the server i'm tired

local function parsePacket(eventTbl)
    -- Basic length check; since the first 5 is modem event data and the other 3 is the magic, sender address and command
    if #eventTbl < 8 then
        return false
    end

    -- finally, only packet-related data
    local pktData = table.pack(table.unpack(eventTbl, 6, #eventTbl))

    -- Basic header check, only sending a dec on a valid magic, but invalid command
    if pktData[1] ~= "hrf3-net" then
        return false
    end

    -- sender address
    -- we use the ones located inside the main packet, since the sender address changes if packet goes through a relay
    local sender = pktData[2]

    if not utils.inList(supportedCMD, pktData[3]) then
        transmitInvalidPacket(sender, "INV_CMD")
        return removeOnInvalid
    end

    -- The actual command parser
    local command = pktData[3]
    if command == "PNG" then
        transmitAckPacket(sender)
        computer.beep('.')
        return true

    elseif command == "GEN_REQ" then
        if #pktData < 4 then
            transmitInvalidPacket(sender, "INV_LEN", "Expected at least 1 paramater(s), got None!")
            return removeOnInvalid
        elseif not utils.inList(supportedGRQ, pktData[4]) then
            transmitInvalidPacket(sender, "INV_SUB_CMD", "Subcommand '" .. pktData[4] .. "' not supported/valid!")
            return removeOnInvalid
        end

        -- Subcommand parser for General Requests
        local subcommand = pktData[4]
        if subcommand == "VER" then
            transmitGenDataPacket(sender, "VER", table.unpack(protocolVer))
            return true

        elseif subcommand == "MOD" then
            transmitGenDataPacket(sender, "MOD", "MONOS")
            return true

        elseif subcommand == "CMD" then
            transmitGenDataPacket(sender, "CMD", serialization.serializeMonOS(supportedCMD))
            return true

        end

    elseif command == "SYS_REQ" then
        if not doLenCheck(4, sender, #pktData) then
            return removeOnInvalid
        elseif not utils.inList(supportedGRQ, pktData[3]) then
            transmitInvalidPacket(sender, "INV_SUB_CMD", "Subcommand '" .. pktData[3] .. "' not supported/valid!")
            return removeOnInvalid
        end

        -- Subcommand parser for System Requests
        local subcommand = pktData[4]
        if subcommand == "CMDS" then
            transmitSysDataPacket(sender, "CMDS", serialization.serializeMonOS(supportedSRQ))
            return true

        elseif subcommand == "INFO" then
            transmitSysDataPacket(sender, "INFO", serialization.serializeMonOS(sysInfo))
            return true

        elseif subcommand == "LOGIN" then
            -- Length check
            if not doLenCheck(6, sender, #pktData) then
                return removeOnInvalid
            end

            -- User and passwd check
            local user = tostring(pktData[5])
            if users[user] == nil then
                transmitInvalidPacket(sender, "INV_LOGIN", "Invalid login, please try again")
                return removeOnInvalid

            end

            local passwd = pktData[6]
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
            if addrContext[sender] == nil or addrContext[sender]["user"] == nil then
                transmitInvalidPacket(sender, "INV_LOGIN", "Not logged in.")
                return removeOnInvalid

            end

            addrContext[sender] = nil

            transmitAckPacket(sender)
            return true

        elseif subcommand == "LIST" then
            -- Length check
            if not doLenCheck(5, sender, #pktData) then
                return removeOnInvalid
            end

            -- Paramater check
            if type(pktData[5]) ~= "string" then
                transmitInvalidPacket(sender, "INV_PRM", "Invalid paramater!")
                return removeOnInvalid

            end

            -- Access check
            if doAccessCheck(sender) then
                return removeOnInvalid
            end

            -- Path check
            if not component.invoke(BOOTADDR, "exists", pktData[5]) or not component.invoke(BOOTADDR, "list", pktData[5]) then
                transmitInvalidPacket(sender, "INV_PATH", "Invalid PATH '" .. pktData[4] .. "'!")
                return removeOnInvalid

            end

            transmitSysDataPacket(sender, "LIST", serialization.serializeMonOS(component.invoke(BOOTADDR, "list")))
            return true

        elseif subcommand == "READ" then
            -- Length check
            if not doLenCheck(4, sender, #pktData) then
                return removeOnInvalid
            end

            -- Paramater check
            if type(pktData[5]) ~= "string" then
                transmitInvalidPacket(sender, "INV_PRM", "Invalid paramater!")
                return removeOnInvalid

            end

            -- Access check
            if doAccessCheck(sender) then
                return removeOnInvalid
            end

            -- File check
            if not component.invoke(BOOTADDR, "exists", pktData[5]) or component.invoke(BOOTADDR, "list", pktData[5]) then
                transmitInvalidPacket(sender, "INV_PATH", "Invalid PATH '" .. pktData[5] .. "'!")
                return removeOnInvalid

            end

            -- Start TCP mode
            local header = utils.deepcopy(tcpInfo)
            header["PACKETAMT"] = math.ceil(component.invoke(BOOTADDR, "size", pktData[5]) / fragSize)
            transmitTCPStartPacket(sender, header)

            addrContext[sender]["TCP_context"] = {
                ["code"] = {"system", "read", pktData[5], 0},
                ["timestamp"] = computer.uptime(),
                ["amt_resent"] = 0,
                ["packet_amt"] = header["PACKETAMT"],
                ["is_client"] = false,
                ["tolerance"] = tcpInfo["TOLERANCE"],
                ["timeout"] = tcpInfo["TIMEOUT"]
            }

            return true

        elseif subcommand == "WRITE" then
            -- Length check
            if not doLenCheck(5, sender, #pktData) then
                return removeOnInvalid
            end

            -- Paramater check
            if type(pktData[5]) ~= "string" then
                transmitInvalidPacket(sender, "INV_PRM", "Invalid paramater!")
                return removeOnInvalid

            end

            -- Access check
            if doAccessCheck(sender) then
                return removeOnInvalid
            end

            -- File (well, folder) check & non-folder check
            if not component.invoke(BOOTADDR, "exists", utils.getParentPath(pktData[5])) or component.invoke(BOOTADDR, "list", pktData[5]) then
                transmitInvalidPacket(sender, "INV_PATH", "Invalid PATH '" .. pktData[5] .. "'!")
                return removeOnInvalid

            end

            -- Start TCP Mode, but as client instead.
            transmitAckPacket(sender)

            -- Instead of storing data in here, append recieved data to file <filename>.tmp, before deleting the original file and
            -- renaming the new file, if the original file exists
            -- Yes, we need to store timestamp and amt resent, to automatically kis.
            -- By default, timeout is twice to account for lag.
            addrContext[sender]["TCP_context"] = {
                ["code"] = {"system", "write", pktData[5]},
                ["is_client"] = true,
                ["timestamp"] = computer.uptime(),
                ["amt_resent"] = 0,
                ["tolerance"] = tcpInfo["TOLERANCE"],
                ["timeout"] = tcpInfo["TIMEOUT"] * 2
            }

            return true

        end

    elseif command == "ACK" then
        -- Check if sender has a valid tcp context and stuff
        if addrContext[sender] == nil or addrContext[sender]["TCP_context"] == nil then
            -- Sir, who tf are you???
            -- Either way, we don't return a decline, as maybe someone with extra braincells would put ACK after every normal-mode operation.
            -- I don't, just resend the dang command if timeout occurs.
            return true
        end

        local tCont = addrContext[sender]["TCP_context"]
        local code = tCont["code"]
        local id, subid = table.unpack(code, 1, 2)
        -- Code check
        if id == "system" then
            -- Realistically, only read does this, if they send ACK with a write context, then someting wong
            if subid == "read" then
                -- Send the next packet
                -- Unlike write, we need to know the offset for the file (it's stored in-context)
                local fpath = code[3]
                local offset = code[4]

                local fd = component.invoke(BOOTADDR, "open", fpath, "r")
                component.invoke(BOOTADDR, "seek", fd, "set", offset)
                local data = component.invoke(BOOTADDR, "read", fd, fragSize)
                component.invoke(BOOTADDR, "close", fd)

                if data ~= nil then
                    -- Update context (dw, pointers exists) & transmit the next packet

                    -- Nu id (or reuse the old one idc)
                    local pktId = 1
                    if tCont["prev_packet"] ~= nil then
                        pktId = tCont["prev_packet"][0] + 1
                    end

                    local packet = {pktId, {data}}
                    tCont["prev_packet"] = packet
                    updateTCPContext(tCont)
                    transmitTCPDataPacket(sender, pktId, {data})
                else
                    -- Terminate connection. I'm sorry, Elizabeth-
                    addrContext[sender]["TCP_context"] = nil
                    transmitTCPDisconnectPacket(sender, "SUCCESS")
                end
                return true
            else
                transmitInvalidPacket(sender, "OTHER", "Malformed TCP packet -- expecting `TCP_DAT`!!!")
                return removeOnInvalid
            end
        end

    elseif command == "TCP_DAT" then
        if addrContext[sender] == nil or addrContext[sender]["TCP_context"] == nil then
            -- Why are YOU sending data to US????
            -- You using modem.broadcast or smth!? -- The server, probably.
            transmitInvalidPacket(sender, "OTHER", "Attepted to send a `TCP_DAT` packet without establishing a TCP connection!")
            return removeOnInvalid
        end

        if not doLenCheck(5, sender, #pktData) then
            return removeOnInvalid
        end

        local tCont = addrContext[sender]["TCP_context"]
        local code = tCont["code"]
        local id, subid = table.unpack(code, 1, 2)
        -- Code check, but write
        if id == "system" then
            -- Realistically, only write does this, if they send TCP_DAT with a read context, then someting wong
            if subid == "write" then
                -- Store in temp file, once on successful DC, remove original file and replace w/ temp file
                local fPath = code[3] .. ".tmp"
                local fd = component.invoke(BOOTADDR, "open", fPath, "a")
                component.invoke(BOOTADDR, "write", fd, serialization.deserializeMonOS(pktData[4])[0])
                component.invoke(BOOTADDR, "close", fd)

                -- Update timestamp & reset counter
                updateTCPContext(tCont)
                transmitAckPacket(sender)
                return true
            else
                transmitInvalidPacket(sender, "OTHER", "Malformed TCP packet -- expecting `ACK`!!!")
                return removeOnInvalid
            end
        end

    elseif command == "TCP_DSC" then
        if addrContext[sender] == nil or addrContext[sender]["TCP_context"] == nil then
            -- y'know that one post where they fire you but you already quit YEARS ago?
            -- This is probably what it feels like
            transmitInvalidPacket(sender, "OTHER", "No TCP connection exists!")
            return removeOnInvalid
        end

        if not doLenCheck(4, sender, #pktData) then
            return removeOnInvalid
        end

        local tCont = addrContext[sender]["TCP_context"]
        local code = tCont["code"]
        local id, subid = table.unpack(code, 1, 2)
        -- Code check, but write
        if id == "system" then
            if subid == "write" then
                -- Only write would have issues from disconnection
                -- Only SUCCESS should commit, otherwise discard.
                local fPath = code[3]
                local reason = pktData[4]
                if reason == "SUCCESS" then
                    if component.invoke(BOOTADDR, "exists", fPath) then
                        component.invoke(BOOTADDR, "remove", fPath)
                    end

                    component.invoke(BOOTADDR, "rename", fPath .. ".tmp", fPath)
                else
                    component.invoke(BOOTADDR, "remove", fPath .. ".tmp")
                end

                addrContext[sender]["TCP_context"] = nil

            else
                -- Otherwise, we can just drop the context w/ no issues
                addrContext[sender]["TCP_context"] = nil
            end

        end

        return true

    elseif command == "TCP_ST" then
        if addrContext[sender] == nil or addrContext[sender]["TCP_context"] == nil then
            -- cool, but who are you???
            transmitInvalidPacket(sender, "OTHER", "No TCP context exists!")
            return removeOnInvalid
        end

        if not doLenCheck(4, sender, #pktData) then
            return removeOnInvalid
        end

        local tCont = addrContext[sender]["TCP_context"]
        local code = tCont["code"]
        local id, subid = table.unpack(code, 1, 2)

        -- Copy the information
        if tCont["is_client"] == true then
            local header = serialization.deserializeMonOS(pktData[4])
            tCont["timeout"] = header["TIMEOUT"] or tcpInfo["TIMEOUT"]
            tCont["tolerance"] = header["TOLERANCE"] or tcpInfo["TOLERANCE"]

            if #header == 0 then
                iolib.print("[HrfNetServer] WARN: Empty header in a TCP start packet, check serialization!")
            end

        end

        return true

    end

end

local function handleTimeout()
    for sender, val in pairs(addrContext) do
        if val["TCP_context"] ~= nil then
            local context = val["TCP_context"]

            local diffTime = computer.uptime() - context["timestamp"]
            if diffTime >= context["timeout"] then
                -- Server and client are similar in timeout handling
                -- Server re-sends packets and counts numbers up, while client only counts the numbers up
                if context["amt_resent"] < context["tolerance"] then
                    if context["is_client"] ~= true then
                        if context["prev_packet"] ~= nil then
                            transmitTCPDataPacket(sender, table.unpack(context["prev_packet"]))
                        else
                            local header = utils.deepcopy(tcpInfo)
                            header["PACKETAMT"] = context["packet_amt"]
                            transmitTCPStartPacket(sender, header)
                        end
                    end

                    context["amt_resent"] = context["amt_resent"] + 1

                else
                    -- We only transmit a DC as a server.
                    if context["is_client"] ~= true then
                        transmitTCPDisconnectPacket(sender, "TIMEOUT")
                    end
                    -- drop connection
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
