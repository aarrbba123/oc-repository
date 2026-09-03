--- A library that replaces the package library
--- TODO: Finish this!

_G.package = {}

package.preload = {}
package.loaded = {}
package._loaded = {} -- Main loaded table, containing all the data
package.persistence = {} -- Persistence table, for when a module decides to write a variable to the packages

package.searchers = {} -- Search modules

package.path = "/lib/?.lua" -- Package path string

--- Preloaded libraries to be used for booting purposes  
--- Will be nil'd at runtime  
package.preloaded = {} -- A proxy table, which will error
package._preloaded = {} -- Main data stuff

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
