_G.package = {}

package._persistance = {}

package.searchers = {}
package.path = "/lib/?.lua"

package.searchers.pathSearcher = function(module)
    local strSplit = package.loaded["string2list"] or package.loaded["utils"]
end

--[[
| NOTE: Metatable format
| Non-core: {["last_used_ticks"]: num, ["loaded"]: bool, ["path"]: str}
| Core: {["is_core"]: bool}
]]--

local function inList(val, list)
    for _, v in pairs(list) do
        if v == val then
            return true
        end
    end
    return false
end

--- Inits core packages
--- Unlike other packages, this has a metatable with is_core set to true.
package.coreLoad = function()
    local invoke = component.invoke
    local mtTbl = {
        ["is_core"] = true
    }
    local coreFList = invoke(BOOTADDR, "list", "/lib/core/")
    local coreFBlacklist = { "package.lua" }
    for i, v in ipairs(coreFList) do
        if inList(v, coreFBlacklist) then
            table.remove(coreFList, i)
        end
    end

    for i, v in ipairs(coreFList) do
        local fd = invoke(BOOTADDR, "open", "/lib/core/" .. v, "rt")
        local data = ""
        repeat
            local buf = invoke(BOOTADDR, "read", fd, math.huge or math.maxinteger)
            data = data .. (buf or "")
        until buf == nil
        local pkg = load(data, "/lib/core/" .. v, "bt")()
        setmetatable(pkg, mtTbl)
        package.loaded[v] = pkg
    end
end

local loadedMtTbl = {}

-- Used in accessing everything
-- _persistance should be accessed first before _loaded
loadedMtTbl.__index = function()

end

-- Used on writing to packages (for some reason)
-- This is why _persistance exists: to store runtime written data.
loadedMtTbl.__newindex = function()

end

setmetatable(package.loaded, loadedMtTbl)

package.require = function(modname)

end


