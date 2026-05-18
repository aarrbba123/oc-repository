-- Initializes the `OS`
-- Built for MkNPP, after realising that it requires > 4kB to actually monitor systems

_G.BOOTADDR = computer.getBootAddress()
local invoke = component.invoke

local function loadfile(file)
    local fd = assert(invoke(_G.BOOTADDR, "open", file), "Unable to open file " .. file .. "!")
    local buf = ""
    repeat
        local dt = invoke(_G.BOOTADDR, "read", fd, math.huge or math.maxinteger)
        buf = buf .. (dt or "")
    until not dt
    invoke(_G.BOOTADDR, "close", fd)

    return load(buf, "=" .. file, "bt", _G)
end

-- Say that we started
computer.beep(".")
loadfile("/sys/boot.lua")()
