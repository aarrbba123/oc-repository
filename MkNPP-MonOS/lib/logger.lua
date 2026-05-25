--- A library that provides access to offline logging

_G.logger = {}

local invoke = component.invoke
local outFS = computer.getBootAddress()

local function duplicateHandler(filePath, fileExt)
    local repPath = filePath .. fileExt
    local i = 1
    while invoke(outFS, "exists", repPath) do
        repPath = filePath .. " (" .. tostring(i) .. ")" .. fileExt
    end

    return repPath
end

function logger.dump()
    if not invoke(outFS, "exists", "/log/") then
        invoke(outFS, "makeDirectory", "/log/")
        print("Successfully setted up log directory")
    end

    print("[Log Dumper] Dumping log data...")
    local fd = invoke(outFS, "open", duplicateHandler("/log/outLog", ".txt"), "w")
    invoke(outFS, "write", fd, utils.allToStr(table.unpack(_G.STDOUT_BUF)))
    invoke(outFS, "close", fd)

    print("[Log Dumper] Dumping err data...")
    fd = invoke(outFS, "open", duplicateHandler("/log/outErr", ".txt"), "w")
    invoke(outFS, "write", fd, utils.allToStr(table.unpack(_G.STDERR_BUF)))
    invoke(outFS, "close", fd)
    print("[Log Dumper] Log dump complete!")

    -- flush logs
    _G.STDOUT_OFFSET = #_G.STDOUT_BUF + 1
    _G.STDERR_OFFSET = #_G.STDERR_BUF + 1

    _G.STDOUT_BUF = {}
    _G.STDERR_BUF = {}
end
