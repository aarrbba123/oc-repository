--[[
Emergency Cooling Script v2.2
Built for Mika Nuclear Power Plant (MkNPP)
Replaces RBMK E-Cooling (Which was lost during the update)
For now, Activates if > 750C and deactivates < 675C (Semi-mimics function of the old RBMK coolers)
]]--

local printInterval = 20
local curPrintNum = 0

local function printToLog(...)
    if curPrintNum >= 20 then
        iolib.print(...)
    end
end

local function rbmk_loop()
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

    local rs = component.proxy(component.redstone)
    if SYS_MODE == 1 then
        rs.setOutput({15, 15, 15, 15, 15, 15})
        printToLog("!!!!! EMERGENCY COOLING ACTIVE !!!!!")
    else
        rs.setOutput({0, 0, 0, 0, 0, 0})
    end

    printToLog("[RBMK Monitoring] avg_t: ", avg_temp, " current MODE: ", SYS_MODE)

    curPrintNum = curPrintNum + 1
    if curPrintNum > 20 then
        curPrintNum = 0
    end
end
klib.registerModule(rbmk_loop)
