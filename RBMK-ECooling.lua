--[[
Emergency Cooling Script v1.1
Built for Kiki Nuclear Power Plant (kNPP)
Replaces RBMK E-Cooling
For now, Activates if > 750C and deactivates < 675C
]]--

--[[
| Mode info:
| 0 - Normal mode
| 1 - Emergency mode
]]--
MODE = 0

-- Main loop.
while true do
    local rbmk_comp = component.list("rbmk_")

    local rbmk_temp_data = {}

    for addr, cType in pairs(rbmk_comp) do

        if ~(cType == "rbmk_console" or cType == "rbmk_crane" or cType == "rbmk_outgasser") then
            -- Get temp directly
            local column = component.proxy(addr)
            table.insert(rbmk_temp_data, column.getHeat())

        elseif cType == "rbmk_console" then
            -- Get temp from each position (indirect)
            local console = component.proxy(addr)
            for y = 0, 14, 1 do
                for x = 0, 14, 1 do
                    local colData = console.getColumnData(x, y)
                    if colData ~= nil then
                        table.insert(rbmk_temp_data, colData["hullTemp"])
                    end
                    
                end
            end

        end
    end

    local rbmk_temp_avg = 0
    for _, temp in ipairs(rbmk_temp_data) do
        rbmk_temp_avg = rbmk_temp_avg + temp
    end

    rbmk_temp_avg = rbmk_temp_avg / #rbmk_temp_data

    -- Temp check
    if rbmk_temp_avg > 750 then
        MODE = 1
    elseif rbmk_temp_avg < 675 then
        MODE = 0
    end

    -- Redstone signal
    local signal_amt = 0
    if MODE == 1 then
        signal_amt = 15
    end

    -- Redstone actions
    local rst_comp = component.list("redstone")
    for addr, cType in pairs(rst_comp) do
        local redstone = component.proxy(addr)
        for side = 0, 5, 1 do
            -- Send output at all 6 sides IF not == signal_amt
            if redstone.getOutput(side) ~= signal_amt then redstone.setOutput(side, signal_amt) end
        end
    end

    -- Yield (since we're done here)
    if coroutine.isyieldable() then
        coroutine.yield()
    end
end
