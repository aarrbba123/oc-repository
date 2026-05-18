--- Main boot script

local invoke = component.invoke
local rootAddr = computer.getBootAddress()

-- Init helper reader/writer functions

function _G.loadfile(path, mode, env)
    local fd = invoke(rootAddr, "open", path)
    local buf = ""

    repeat
        local dt = invoke(rootAddr, "read", fd, math.maxinteger or math.huge)
        buf = buf .. dt
    until not dt

    return load(buf, "=" .. path, mode, env)
end

function _G.listdir(path)
    return invoke(rootAddr, "list", path)
end

-- Global data/buffers

_G.STDOUT_BUF = {}
_G.STDERR_BUF = {}

-- Main functions. Any functions registered in this table will be ran
_G.main = {}

-- Library files
loadfile("/lib/net.lua", "bt", _G)()
loadfile("/lib/event.lua", "bt", _G)()
loadfile("/lib/iolib.lua", "bt", _G)()

-- Module files
-- Load em'
local moduleFiles = listdir("/sys/modules")
for _, moduleName in ipairs(moduleFiles) do
    loadfile("/sys/modules/" .. moduleName, "bt", _G)()
end

-- Kernel
loadfile("/sys/main.lua", "bt", _G)()
