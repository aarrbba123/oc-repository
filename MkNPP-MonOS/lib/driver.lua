_G.driver = {}

function driver.updateComponentBinds()
    component.redstone = component.list("redstone")()
    component.modem = component.list("modem")()
    -- Classic filesystem list
    component.filesystem = component.list("filesystem")
end
