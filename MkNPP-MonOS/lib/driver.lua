_G.driver = {}

local componentList = {"gpu", "modem", "redstone", "screen", "ocelot"}

component.raw = {}

function driver.updateComponentBinds()
    for _, comp in ipairs(componentList) do
        local primaryComponent = component.list(comp)()
        if primaryComponent ~= nil then
            component[comp] = component.proxy(primaryComponent)
            component.raw[comp] = primaryComponent
        else
            component[comp] = nil
            component.raw[comp] = nil
        end
    end

    -- Classic filesystem list
    component.filesystems = component.list("filesystem")
end
