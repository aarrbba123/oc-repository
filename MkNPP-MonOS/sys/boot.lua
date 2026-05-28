--- Main boot script

local invoke = component.invoke
local rootAddr = computer.getBootAddress()

-- Init helper reader/writer functions

function _G.loadfile(path, mode, env)
    local fd = invoke(rootAddr, "open", path)
    local buf = ""

    repeat
        local dt = invoke(rootAddr, "read", fd, math.maxinteger or math.huge)
        buf = buf .. (dt or "")
    until not dt

    return load(buf, "=" .. path, mode, env)
end

function _G.listdir(path)
    return invoke(rootAddr, "list", path)
end

-- Global data/buffers

_G.STDOUT_BUF = {}
_G.STDERR_BUF = {}

_G.STDOUT_OFFSET = 1
_G.STDERR_OFFSET = 1

-- Main functions. Any functions registered in this table will be ran
_G.main = {}

-- Event lifetime amount

_G.event_lifetime = 2


-- Driver™
loadfile("/lib/driver.lua", "bt", _G)()
driver.updateComponentBinds()

-- Library files
local libFiles = listdir("/lib")
for _, libName in ipairs(libFiles) do
    loadfile("/lib/" .. libName, "bt", _G)()
end

-- Global functions

-- Even in MonOS, this global is one of the most useful.
_G.print = iolib.print

-- Module files
-- Load em'
-- The functions registered to main 
local moduleFiles = listdir("/sys/modules")
for _, moduleName in ipairs(moduleFiles) do
    loadfile("/sys/modules/" .. moduleName, "bt", _G)()
end

-- Audibly celebrate (successful boot)
computer.beep(1500, 0.3)
computer.beep(2000, 0.2)

iolib.print("Boot Successful!")

-- Kernel
loadfile("/sys/main.lua", "bt", _G)()
