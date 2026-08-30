--- The file that autoruns
--- Gets the label, then remounts the disk into that label

local fs = require("filesystem")
local proxy = ...

local name = proxy.getLabel()
fs.mount(proxy, "/mnt/" .. name)
