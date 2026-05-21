SYS_MODE = 0
DBG_ENABLED = 0
PASSWD = "kNPP_P@ss123"

local print = iolib.print

-- Init section
local function kernelErrHandler(err)
    print("!!! KERNEL ALERT !!!")
    print("A kernel module has encountered an error!")
    print(err)
end

-- Main section
while true do
    -- Not using ipairs ensures it loads in the order the modules register
    for i = 1, #main do
        xpcall(main[i], kernelErrHandler)
    end

    -- end of loop
    event.flushEvents()
end
