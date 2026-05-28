_G.driver = {}

function driver.updateComponentBinds()
    component.gpu = component.list("gpu")()
    component.modem = component.list("modem")()
    component.redstone = component.list("redstone")()
    component.screen = component.list("screen")()

    -- Classic filesystem list
    component.filesystem = component.list("filesystem")
end
