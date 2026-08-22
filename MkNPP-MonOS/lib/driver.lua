_G.driver = {}

local componentList = {"gpu", "modem", "redstone", "screen", "ocelot"}

function driver.updateComponentBinds()
    for _, comp in ipairs(componentList) do
        local primaryComponent = component.list(comp)()
        if primaryComponent ~= nil then
            component[comp] = component.proxy(primaryComponent)
        else
            component[comp] = nil
        end
    end

    -- Classic filesystem list
    component.filesystems = component.list("filesystem")
end
