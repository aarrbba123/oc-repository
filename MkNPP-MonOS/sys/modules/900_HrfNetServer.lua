--- Hrf3-net server

local port = 12930

--- Removes invalid hrf3-net packets. Essentally `true` means it blocks any hrf3-net packet that is invalid,
--- preventing scripts/programs ran later than this program from processing said hrf3-net packet.
--- dw, the events will be cleared at the end of the loop.
local removeOnInvalid = true

--- A list of commands supported and processed by the server
--- Realistically, `DEC` and `ACK` are not processed since this is not a client.
--- Oh, and `LOG_DAT` and `GEN_DAT`? Not really processed & acted on.
local supportedCMD = {"GEN_REQ", "LOG_REQ", "PNG"}

--- Supported buffer types
--- `LOG` and `OUT` are the same here, btw.
local supportedBufType = {"LOG", "OUT", "ERR"}

--- Supported General Requests
local supportedGRQ = {"CMD", "MOD"}

--- Supported Log Requests
local supportedLRQ = {"LEN", "LOG"}

local function serializeBasic(tblData)
    if #tblData ~= 0 then
        local retData = tblData[1]
        for i = 2, #tblData do
            local val = tblData[i]
            retData = retData .. '\0' .. val
        end

        return retData
    else
        return ""
    end
end

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
        transmitInvalidPacket(sendAddr, "INV_CMD", "Invalid hrf3-net command!")
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
            networking.send(sendAddr, port, "hrf3-net", "GEN_DAT", "MOD", "BASIC")
            return true
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

            transmitLogs(sendAddr, getBufferNFromType(logType), fline, lline)
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
    event.pushEvents(repushEvtTbl)
end
klib.registerModule(HrfNetServer)
print("Hrf3-Net Server V2 registered successfully!")
