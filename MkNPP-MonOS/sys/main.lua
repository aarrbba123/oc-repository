SYS_MODE = 0
DBG_ENABLED = 0

--- High Memory Pressure threshold. Crashes the system
local HMEM_PRESSURE = 0.9

--- Moderate Memory Pressure threshold. forces GC to occur to prevent using too much memory.
local MMEM_PRESSURE = 0.69

--- Amount of module errors that can occur before the system crashes. < 0 to disable
local ERR_THRESHOLD = 0
local ERR_COUNT = 0

--- Panick variable which forces a panic outside safety
local PANIC = nil

local error = iolib.error

-- Init section

local function doGC()
    for i = 0, 10 do
        -- Performing things that yield like pulling signals force GC to occur.
        event.flushEvents()
    end
end

local function panic(...)
    error("!!! KERNEL PANIC !!!")
    error(...)
    error("!!! KERNEL PANIC !!!")
    logger.dump()
    assert(false, "Kernel Panicked, dumped log data to disk!")
end

local function kernelErrHandler(err)
    error("- KERNEL ALERT -")
    error("A kernel module has encountered an error!")
    error(err)
    error("- KERNEL ALERT -")

    print("[Kernel] A module has encountered an error!")
    if ERR_COUNT >= ERR_THRESHOLD and ERR_THRESHOLD >= 0 then
        PANIC = table.pack("The amount of module errors encountered has surpassed acceptable amounts, crashing!")
    end

    ERR_COUNT = ERR_COUNT + 1
end

print("----- MAIN LOOP STARTED -----")

-- Main section
while true do
    -- Not using ipairs ensures it loads in the order the modules register
    for i = 1, #main do
        local stat = xpcall(main[i], kernelErrHandler)
        if not stat then
            print("[Kernel] xpcall returned a failiure!")
        end

        local freeMemory = utils.getFreeMem()
        local usedMemory = computer.totalMemory() - freeMemory
        local usedPercent = usedMemory / computer.totalMemory()

        if PANIC then
            panic(table.unpack(PANIC))
        end

        if usedPercent >= HMEM_PRESSURE then
            panic("Critically Low Memory! (Free Left: ", freeMemory, " [", freeMemory / 1000, " KB])")
        elseif usedPercent >= MMEM_PRESSURE then
            doGC()
            print("[Kernel] Performed GC due to low memory!")
            print("(Free MEM Left:", freeMemory, " bytes [", freeMemory / 1000, " KB])")
        end
    end

    -- end of loop
    event.flushEvents()
    event.processQueue()
end
