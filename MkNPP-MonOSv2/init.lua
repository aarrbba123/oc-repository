-- OS init

local bootaddr = computer.getBootAddress()
local invoke = component.invoke

local function loadfile(file)
    local fd = assert(invoke(bootaddr, "open", file), "Unable to open file '" .. file .. "'!")
    local buf = ""

    repeat
        local dt = invoke(bootaddr, "read", fd, math.huge or math.maxinteger)
        buf = buf .. (dt or "")
    until not dt

    invoke(bootaddr, "close", fd)

    return load(buf, "=" .. file, "bt", _G)
end

computer.beep(".")
loadfile("/sys/boot.lua")()
