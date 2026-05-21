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
            if not invoke(outFS, "exists", "/log/") then
                invoke(outFS, "makeDirectory", "/log/")
                print("Successfully setted up log directory")
            end

            print("[Log Dumper] Dumping log data...")
            local fd = invoke(outFS, "open", "/log/outLog.txt", "w")
            invoke(outFS, "write", fd, utils.allToStr(table.unpack(_G.STDOUT_BUF)))
            invoke(outFS, "close", fd)

            print("[Log Dumper] Dumping err data...")
            fd = invoke(outFS, "open", "/log/outErr.txt", "w")
            invoke(outFS, "write", fd, utils.allToStr(table.unpack(_G.STDERR_BUF)))
            invoke(outFS, "close", fd)
            print("[Log Dumper] Log dump complete!")
        else
            OFFLINE_DEBUG_TICK = OFFLINE_DEBUG_TICK + 1

        end

    end
    klib.registerModule(logDumper)
    print("Successfully registered offline logging module!")
end
