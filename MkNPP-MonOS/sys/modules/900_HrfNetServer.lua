--- Hrf3-net server

local port = 12930

--- hrf3-net protocol version.
local protocolVer = {0, 1}

--- Removes invalid hrf3-net packets. Essentally `true` means it blocks any hrf3-net packet that is invalid,
--- preventing scripts/programs ran later than this program from processing said hrf3-net packet.
--- Please note that re-registered events have the same lifetime, meaning that it will get removed as if it wasn't even processed at all.
--- This is to protect from a OOM crash caused by DoS/DDoS
local removeOnInvalid = true

--- A list of commands supported and processed by the server
--- Realistically, `DEC` and `ACK` are not processed since this is not a client.
--- Oh, and `LOG_DAT` and `GEN_DAT`? Not really processed & acted on.
local supportedCMD = {"GEN_REQ", "LOG_REQ", "PNG"}

--- Supported buffer types
--- `LOG` and `OUT` are the same here, btw.
local supportedBufType = {"LOG", "OUT", "ERR"}

--- Supported General Requests
local supportedGRQ = {"CMD", "MOD", "VER"}

--- Supported Log Requests
local supportedLRQ = {"LEN", "LOG"}

--- Serialization-related stuff
local seperator = string.char(81)
local serializeBasic = serialization.serializeBasic

local function getBufferNFromType(bufType)
    if bufType == "ERR" then
        return "STDERR_BUF"
    elseif bufType == "LOG" or bufType == "OUT" then
        return "STDOUT_BUF"
    else
        return nil
    end
end

local function transmitInvalidPacket(senderAddr, invReason, ...)
    local reasonTbl = table.pack(...)
    networking.send(senderAddr, port, "hrf3-net", "DEC", invReason, utils.allToStr(table.unpack(reasonTbl)))
end

local function transmitInvalidParamPacket(senderAddr, paramAmt)
    transmitInvalidPacket(senderAddr, "INV_LEN", "Expected ", tostring(paramAmt), " paramaters!")
end

local function transmitInvalidSubCMDPacket(senderAddr, subCMD)
    transmitInvalidPacket(senderAddr, "INV_SUB_CMD", "Invalid subcommand '", utils.capStrToSize(tostring(subCMD), 255, "..."), "'!")
end

local function transmitInvalidBufPacket(senderAddr, bufType)
    transmitInvalidPacket(senderAddr, "INV_BUF", "Invalid buffer type '", utils.capStrToSize(tostring(bufType), 255, "..."), "'!")
end

local function transmitLogs(senderAddr, bufType, first_line, last_line)
    local sendSize = 27
    local sendBuf = {}
    local send_fline = first_line
    local bufStr = getBufferNFromType(bufType)

    local maxSendSize = networking.getMaxSendSize()

    for i = first_line, last_line do
        local dat = _G[bufStr][i]
        if #dat + sendSize > maxSendSize then
            networking.send(senderAddr, port, "hrf3-net", "LOG_DAT",  bufType, "LOG", send_fline, serializeBasic(sendBuf))

            sendBuf = {}
            send_fline = i
            sendSize = 27
        end

        table.insert(sendBuf, dat)
        sendSize = sendSize + #dat + 1
    end
end

local function validateList(lst, cmd)
    for _, chk in ipairs(lst) do
        if cmd == chk then
            return true
        end
    end

    return false
end

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

    -- re-push events
    event.repushEvents(repushEvtTbl)
end
klib.registerModule(HrfNetServer)
print("Hrf3-Net Server V2 registered successfully!")
