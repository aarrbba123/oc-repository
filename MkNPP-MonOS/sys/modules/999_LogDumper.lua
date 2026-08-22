--- Log dumper for offline use.
--- Use in case the online hrf3-net protocol is unusable

local OFFLINE_DEBUG_MODE = true
local OFFLINE_DEBUG_INTERVAL = 5
local OFFLINE_DEBUG_TIME = 0

local invoke = component.invoke
local print = iolib.print
local outFS = computer.getBootAddress()

if OFFLINE_DEBUG_MODE then
    local function logDumper()
        if computer.uptime() - OFFLINE_DEBUG_TIME >= OFFLINE_DEBUG_INTERVAL then
            OFFLINE_DEBUG_TIME = computer.uptime()
            logger.dump()
        end

    end
    klib.registerModule(logDumper)
    print("Offline logging module registered successfully!")
end
