--- A library that replaces the package library
--- TODO: Finish this!

package = {}

package.loaded = {}

package.searchers = {}

-- The recursive searcher
local function _libSearcher(fName, libDir)
    if component.invoke(BOOTADDR, "exists", libDir .. "/" .. fName) then
        local localEnv = {} -- TODO: The environment
        loadfile(libDir .. "/" .. fName, "bt", localEnv)()
        return localEnv
    end

    local fList = component.invoke(BOOTADDR, "list", libDir)
    for _, name in ipairs(fList) do
        -- Preload folder blacklist
        if libDir .. "/" .. name .. "/" ~= "/lib/preload" then
            -- Folder checker
            if component.invoke(BOOTADDR, "list", name) ~= nil then
                local dat = _libSearcher(fName, libDir .. "/" .. name)
                if dat ~= nil then
                    return dat
                end
            end
        end
    end

    return nil
end

function package.searchers.libSearcher(modname)
    local fName = modname .. ".lua"
    return _libSearcher(fName, "/lib")
end

function _G.require(modname)
    if package.loaded[modname] ~= nil then
        return package.loaded[modname]
    end

    for _, fun in pairs(package.searchers) do
        local data = fun(modname)
        if data ~= nil then
            package.loaded[modname] = data
            return data
        end

    end
end
