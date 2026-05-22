
_G.event = {}

function event.pushEvent(name, ...)
    computer.pushSignal(name, ...)
end

function event.pushEvents(eventsData)
    for _, sig in ipairs(eventsData) do
        computer.pushSignal(table.unpack(sig))
    end
end

function event.pullAllEvents()
    local buf = {}
    repeat
        local val = table.pack(computer.pullSignal(0))
        local eType = val[1]
        if eType then
            table.insert(buf, val)
        end
    until not type
    return buf
end

function event.pullEvents(eventType)
    local eventsData = event.pullAllEvents()
    local retBuffer = {}
    local repushBuffer = {}

    for _, evt in ipairs(eventsData) do
        if evt[0] == eventType then
            table.insert(retBuffer, evt)
        else
            table.insert(repushBuffer, evt)
        end
    end

    event.pushEvents(repushBuffer)

    return retBuffer
end

function event.flushEvents()
    repeat
        local val = table.pack(computer.pullSignal(0))
        local eType = val[1]
    until not eType
end
