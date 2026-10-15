-- Initializes core libraries for use in the OS.
-- Basically package before package.

_G.package = {}

package.loaded = {}
package._loaded = {}


local invoke = component.invoke

assert(invoke(BOOTADDR, "extsts", "/lib/core/filesystem.lua"), "Core file 'filesystem.lua' is missing!")

-- Implement loadfile
_G.loadfile = function(path, mode, env)
    local fdata = ""
    local fd = invoke(BOOTADDR, "open", path)
    repeat
        local chnk = invoke(BOOTADDR, "read", fd, math.huge or math.maxinteger)
        fdata = fdata .. (chnk or "")
    until chnk == nil
    invoke(BOOTADDR, "close", fd)
    return load(fdata, path, mode, env)
end

-- Load filesystem, utils_core (str2list) -> loaded
local fs = loadfile("/lib/core/filesystem.lua")()
local utils = loadfile("/lib/core/utils_core.lua")()

-- core package, remember?
local coreMtTbl = { ["is_core"] = true }
setmetatable(fs, coreMtTbl)
setmetatable(utils, coreMtTbl)

package._loaded["filesystem"] = fs
package._loaded["utils_core"] = utils
