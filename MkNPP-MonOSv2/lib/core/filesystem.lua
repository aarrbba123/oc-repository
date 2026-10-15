-- Filesystem package
-- Required by package.lua
-- Load this first!

--[[
Filesystem object format
{
    ["fd"]: int,
    ["diskaddr"]: string,
    [<functions>]
    ...
}
]]--

-- TODO: this!

local filesystem = {}

filesystem.open = function(diskAddr, path, mode)
    local invoke = component.invoke

    -- Check it exists before committing
    if not invoke(diskAddr, "exists", path) then
        return nil
    end

    local retObj = {
        ["fd"] = invoke(diskAddr, "open", path, mode),
        ["diskaddr"] = diskAddr,
        ["seek"] = function(loc, where)

        end
    }

    if string.match(mode, "[r+]") then
        retObj["read"] = function(size)

        end
    end
    if string.match(mode, "[w+]") then
        
    end
end

return filesystem
