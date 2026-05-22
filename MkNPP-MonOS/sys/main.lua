SYS_MODE = 0
DBG_ENABLED = 0
PASSWD = "kNPP_P@ss123"

local HMEM_PRESSURE = 0.9

local print = iolib.print
local error = iolib.error

-- Init section
local function kernelErrHandler(err)
    print("!!! KERNEL ALERT !!!")
    print("A kernel module has encountered an error!")
    print(err)
end

local function panic(...)
    error("!!! KERNEL PANIC !!!")
    error(...)
    error("!!! KERNEL PANIC !!!")
    logger.dump()
    assert(false, "Kernel Panicked, dumped log data to disk!")
end

-- Main section
while true do
    -- Not using ipairs ensures it loads in the order the modules register
    for i = 1, #main do
        xpcall(main[i], kernelErrHandler)
        if (computer.totalMemory() - computer.freeMemory()) /  computer.totalMemory >= HMEM_PRESSURE then
            panic("Critically Low Memory! (Free: ", computer.freeMemory(),")")
        end
    end

    -- end of loop
    event.flushEvents()
end
