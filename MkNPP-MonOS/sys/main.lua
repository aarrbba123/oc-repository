SYS_MODE = 0
DBG_ENABLED = 0
PASSWD = "kNPP_P@ss123"

-- Init section (network & library, mainly)

-- Main section
while true do
    for _, func in ipairs(_G.main) do
        -- 10/10 safety, will do again later (not)
        func()
    end

    -- end of loop
    event.flushEvents()
    os.sleep()
end
