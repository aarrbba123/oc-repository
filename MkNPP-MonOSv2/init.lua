--- Init lua for MonOS v2
--- Merges both `boot.lua` and `init.lua`

_G.BOOTADDR = computer.getBootAddress()
local invoke = component.invoke

local function loadfile(fpath)
    if invoke(BOOTADDR, "exists", fpath) then
        local fdata = ""
        local fd = invoke(BOOTADDR, "open", fpath)
        repeat
            local chnk = invoke(BOOTADDR, "read", fd, math.huge or math.maxinteger)
            fdata = fdata .. (chnk or "")
        until chnk == nil
        invoke(BOOTADDR, "close", fd)
        local ret = load(fdata, fpath, "bt", _G)()
        if ret ~= nil then
            return ret
        else
            return true
        end
    else
        return nil
    end
end

-- Load packagelib dependencies
assert(loadfile("/lib/core/packageinit.lua") ~= nil, "Core file 'packageinit.lua' failed to load!")
-- Load package module itself
assert(loadfile("/lib/core/package.lua") ~= nil, "Core file 'package.lua' failed to load!")

-- Using package module, load all core files
package.coreLoad()

-- Hand over control -> kernel
loadfile("/sys/main.lua")
