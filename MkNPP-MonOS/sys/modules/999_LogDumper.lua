--- Log dumper for offline use.
--- Use in case the online filesystem protocol is unusable

local OFFLINE_DEBUG_MODE = true
local OFFLINE_DEBUG_INTERVAL = 100
local OFFLINE_DEBUG_TICK = 0

local invoke = component.invoke
local print = iolib.print
local outFS = computer.getBootAddress()

if OFFLINE_DEBUG_MODE then
    local function logDumper()
        if OFFLINE_DEBUG_TICK >= OFFLINE_DEBUG_INTERVAL then
            OFFLINE_DEBUG_TICK = 0
            logger.dump()
        else
            OFFLINE_DEBUG_TICK = OFFLINE_DEBUG_TICK + 1

        end

    end
    klib.registerModule(logDumper)
    print("Successfully registered offline logging module!")
end
