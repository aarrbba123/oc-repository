SYS_MODE = 0
DBG_ENABLED = 0
PASSWD = "kNPP_P@ss123"

-- Init section (network & library, mainly)

-- Main section
while true do
    -- Not using ipairs ensures it loads in the order the modules register
    for i = 1, #main do
        main[i]()
    end

    -- end of loop
    event.flushEvents()
    os.sleep()
end
