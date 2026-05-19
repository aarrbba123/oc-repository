-- Updates component driver
-- That's pretty much it, really

local function driverUpdater()
    driver.updateComponentBinds()
end
klib.registerModule(driverUpdater)
iolib.print("Driver updater registered successfully!")
