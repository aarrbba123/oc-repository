--- HPort is basically the official port
local HPORT = 12930
local invoke = component.invoke

--- A key-context for remembering what we should do.
local addrContexts = {}

--- Remove on an invalid hrf3-net packet policy.
--- Why does its implementation look weird?
--- Well, because returning true will make the function not repush the event, effectively removing it.
local removeOnInvalid = true

local function transmitLogs(netAddr, buf, first_line, last_line)
    local sendBuf = {}
    -- This is based off of manual calculations.
    local curSendSize = 26
    local curBuf = nil

    local maxSendSize = networking.getMaxSendSize()
    -- We're gonna do smth a lil different here.

    for x = first_line, last_line do
        if not curBuf == nil then
            table.insert(sendBuf, curBuf)
            curSendSize = curSendSize + #curBuf
        end

        curBuf = buf[x]

        if curSendSize + #curBuf >= maxSendSize then
            networking.send(netAddr, HPORT, table.unpack(sendBuf))
            curSendSize = 26
        end

    end

end

local function parseCommands(evt, mdm)
    local receiverAddr, senderAddr, port, wirelessDist, id, command = table.unpack(evt, 1, 6)
    local payloadLen = #evt - 6

    if id ~= "hrf3-net" or port ~= HPORT then
        return false
    end

    -- Command parsing section
    if command == "LOG_REQ" then
        if payloadLen >= 2 then
            local logType, logReq = table.unpack(evt, 7, 8)
            local logData
            if not (logType == "log" or logType == "err") then
                return removeOnInvalid
            elseif logType == "log" then
                logData = _G.STDOUT_BUF
            elseif logType == "err" then
                logData = _G.STDERR_BUF
            end

            if logReq == "LEN" then
                networking.send(senderAddr, port, "hrf3-net", "LOG_DAT", logType, "LEN", #logData)
                return true
            elseif logReq == "LOG" then
                if not payloadLen >= 4 then
                    return removeOnInvalid
                end
                local first_line, last_line = table.unpack(evt, 9, 10)

                transmitLogs(senderAddr, logData, first_line, last_line)
                return true
            else
                return removeOnInvalid
            end

        else
            -- too smol.m4v
            return removeOnInvalid
        end
    elseif command == "PNG" then
        computer.beep(".")
        return true

    else
        -- Invalid request
        return removeOnInvalid
    end

end

local function logTransmitter()
    local mdm = component.modem
    local print = iolib.print
    if not invoke(mdm, "isOpen", HPORT) then
        print("Opening HRF3-Net Port @ " .. tostring(HPORT))
        invoke(mdm, "open", HPORT)
    else
        -- Listen
        local evtList = event.pullEvents("modem_message")
        local repushEventList = {}

        for _, evt in ipairs(evtList) do
            -- Your packets are around 6 values or more
            local valid = false
            if #evt > 6 then
                valid = parseCommands(evt, mdm)
            end

            if not valid then
                table.insert(repushEventList, evt)
            end

        end

        -- Repush unparsed/invalid network events
        event.pushEvents(repushEventList)
    end
end
klib.registerModule(logTransmitter)
iolib.print("Successfully registered LogTransmitter/hrf3-net server!")
