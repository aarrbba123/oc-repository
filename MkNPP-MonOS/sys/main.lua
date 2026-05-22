SYS_MODE = 0
DBG_ENABLED = 0
PASSWD = "kNPP_P@ss123"

local HMEM_PRESSURE = 0.9
local MMEM_PRESSURE = 0.69

local print = iolib.print
local error = iolib.error

-- Init section

local function doGC()
    for i = 0, 10 do
        -- Performing things that yield like pulling signals force GC to occur.
        event.flushEvents()
    end
end

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

        local usedMemory = computer.totalMemory() - computer.freeMemory()
        local usedPercent = usedMemory / computer.totalMemory()
        if usedPercent >= HMEM_PRESSURE then
            panic("Critically Low Memory! (Free Left: ", computer.freeMemory(), ")")
        elseif usedPercent >= MMEM_PRESSURE then
            doGC()
            print("[Kernel] Performed GC due to low memory. (Free Left: ", computer.freeMemory(), " )")
        end
    end

    -- end of loop
    event.flushEvents()
end
