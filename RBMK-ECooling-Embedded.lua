--[[
Emergency Cooling Script v2
Built for Kiki Nuclear Power Plant (kNPP)
Replaces RBMK E-Cooling
For now, Activates if > 750C and deactivates < 675C
]]--

SYS_MODE = 0

-- Init section (screen, mainly)

-- Main section
while true do
    local rbmk_com = component.list("rbmk_")
    local temp_buffer = {}

    for addr, cType in pairs(rbmk_com) do
        if not (cType == "rbmk_outgasser" or cType == "rbmk_crane" or cType == "rbmk_console") then
            local col = component.proxy(addr)
            table.insert(temp_buffer, col.getHeat())

        elseif cType == "rbmk_console" then
            local consl = component.proxy(addr)

            for y = 0, 15, 1 do
                for x = 0, 15, 1 do
                    local col = consl.getColumnData(x, y)
                    if col ~= nil then
                        table.insert(temp_buffer, col.hullTemp)
                    end
                end
            end

        end
    end

    local avg_temp = 0
    for _, val in ipairs(temp_buffer) do
        avg_temp = avg_temp + val
    end
    avg_temp = avg_temp / #temp_buffer

    if avg_temp > 750 then
        SYS_MODE = 1
    elseif avg_temp < 650 then
        SYS_MODE = 0
    end

    local rs = component.proxy(component.list("redstone")())
    if SYS_MODE == 1 then
        rs.setOutput({15, 15, 15, 15, 15, 15})
    else
        rs.setOutput({0, 0, 0, 0, 0, 0})
    end

    if coroutine.isyieldable() then
        coroutine.yield()
    end
end
