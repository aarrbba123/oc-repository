
_G.event = {}
_G.event.eventBuffer = {}

function event.pushEvent(name, ...)
    computer.pushSignal(name, ...)
end

function event.pushEvents(eventsData)
    for _, sig in ipairs(eventsData) do
        computer.pushSignal(table.unpack(sig))
    end
end

function event.pullAllEvents()
    local retBuffer = event.eventBuffer
    event.eventBuffer = {}
    return retBuffer
end

function event.pullEvents(eventType)
    local newBuffer = {}
    local retBuffer = {}
    for _, evt in ipairs(event.eventBuffer) do
        local eType = evt[1]
        if eType == eventType then
            table.insert(retBuffer, evt)
        else
            table.insert(newBuffer, evt)
        end
    end

    event.eventBuffer = newBuffer
    return retBuffer
end

function event.flushEvents()
    -- Instead of flushing ALL events in the queue, if will check the lifetimes of the individual event
    -- Only allowing those who has at least 1 lifetime to stay
    local newBuffer = {}
    for _, evt in ipairs(event.eventBuffer) do
        local lifetime = evt["lifetime"]
        if lifetime > 0 then
            evt["lifetime"] = evt["lifetime"] - 1
            table.insert(newBuffer, evt)
        end
    end

    event.eventBuffer = newBuffer
end

--- Moves all events/signals from the queue to the event buffer
function event.processQueue()
    repeat
        local evt = table.pack(computer.pullSignal(0))
        local eType = evt[1]
        if eType then
            evt["lifetime"] = _G.event_lifetime
            table.insert(event.eventBuffer, evt)
        end
    until not eType
end
