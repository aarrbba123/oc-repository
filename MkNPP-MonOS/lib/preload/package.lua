--- A library that replaces the package library
--- TODO: Finish this!

_G.package = {}

package.preload = {}
package.loaded = {}
package._loaded = {} -- Main loaded table, containing all the data
package.persistence = {} -- Persistence table, for when a module decides to write a variable to the packages

package.searchers = {} -- Search modules

package.path = "/lib/?.lua" -- Package path string (also i forgor the delimiter so uhhh ; is used ig)

--- Preloaded libraries to be used for booting purposes  
--- Will be nil'd at runtime  
package.preloaded = {} -- A proxy table, which will error out
package._preloaded = {} -- Main data stuff

local function pathSearcher(modname)
    local searchPaths
    local utilLib
    local fsLib
    -- Get package depending on init level
    if package._preloaded ~= nil then
        utilLib = package.preloaded["utils_core"]
        fsLib = package.preloaded["fs_core"]
    else
        utilLib = package.loaded["utils"]
        fsLib = package.loaded["filesystem"]
    end

    searchPaths = utilLib.split(package.path, ';')

    for _, path in pairs(searchPaths) do
        -- Construct the path with the mod
        local curSPathSp = utilLib.split(path, '?')
        local curSPath
        if curSPathSp > 1 then
            for i, sPath in ipairs(curSPathSp) do
                if i == 1 then
                    curSPath = sPath
                else
                    curSPath = curSPath .. modname .. sPath
                end
            end

            -- Find the path, return early
            -- yes, we're using the core environment.
            if fsLib.exists(curSPath) then
                return load(fsLib.readAll(curSPath), curSPath, 'bt', _G)()
            end

        end
    end
    return nil
end

-- Main require module
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
