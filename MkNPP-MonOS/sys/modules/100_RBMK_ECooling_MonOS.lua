--[[
Emergency Cooling Script v2.2
Built for Mika Nuclear Power Plant (MkNPP)
Replaces RBMK E-Cooling (Which was lost during the update)
For now, Activates if > 750C and deactivates < 675C (Semi-mimics function of the old RBMK coolers)
]]--

local printInterval = 40
local curPrintNum = 0

local print = iolib.print
local invoke = component.invoke

local function rbmk_loop()
    local rbmk_com = component.list("rbmk_")
    local temp_buffer = {}

    for addr, cType in pairs(rbmk_com) do
        if not (cType == "rbmk_outgasser" or cType == "rbmk_crane" or cType == "rbmk_console") then
            table.insert(temp_buffer, invoke(addr, "getHeat"))

        elseif cType == "rbmk_console" then
            for y = 0, 15 do
                for x = 0, 15 do
                    local col = invoke(addr, "getColumnData", x, y)
                    if col then
                        table.insert(temp_buffer, col["hullTemp"])
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

    local rs = component.redstone
    if SYS_MODE == 1 then
        invoke(rs, "setOutput", {15, 15, 15, 15, 15, 15})
        print("!!!!! EMERGENCY COOLING ACTIVE !!!!!")
    else
        invoke(rs, "setOutput", {0, 0, 0, 0, 0, 0})
    end

    curPrintNum = curPrintNum + 1
    if curPrintNum > printInterval then
        print("[RBMK Monitoring] avg_t: ", avg_temp, " current MODE: ", SYS_MODE)
        curPrintNum = 0
    end
end
klib.registerModule(rbmk_loop)
print("RBMK Monitoring System successfully registered!")
