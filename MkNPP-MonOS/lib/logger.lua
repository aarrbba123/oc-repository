--- A library that provides access to offline logging

_G.logger = {}

local invoke = component.invoke
local print = iolib.print
local outFS = computer.getBootAddress()

function logger.dump()
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
end
