--- A library that provides access to offline logging

_G.logger = {}

-- Only create another file IF we just booted
logger.overrideID = nil

local invoke = component.invoke
local outFS = computer.getBootAddress()

local function duplicateHandler(filePath, fileExt)
    local repPath = filePath .. fileExt

    if logger.overrideID == nil then
        local i = 1

        while invoke(outFS, "exists", repPath) do
            repPath = filePath .. " (" .. tostring(i) .. ")" .. fileExt
            i = i + 1
        end

        logger.overrideID = i
    else
        repPath = filePath .. " (" .. tostring(logger.overrideID) .. ")" .. fileExt

    end

    return repPath
end

-- Gets the amount of duplicates
-- I'm pretty sure regex does better than this. - future you
local function listDuplicates(filePath, fileExt)
    local repPath = filePath .. fileExt
    local retList = {}
    local i = 1
    while invoke(outFS, "exists", repPath) do
        table.insert(retList, repPath)
        repPath = filePath .. " (" .. tostring(i) .. ")" .. fileExt
        i = i + 1
    end

    return retList
end

local function getLog(id)
    -- sir, we cannot get the future now, we need to wait until future is past before we can get the past now.
    -- that one spaceballs scene, i think.
    if id > logger.overrideID or id < 0 then
        return nil
    end

    local fPath = "/log/outLog (" .. tostring(id) .. ").txt"

    if not invoke(outFS, "exists", fPath) then
        return nil
    end

    local fd = invoke(outFS, "open", fPath, "r")
    local data = ""
    

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
end


