--- An extremely simple script used for the lab's power network
--- By default, we're using the PC's internal energy to command.

local threshold = 0.2
local triggerSide = "back"

local rstAddr = component.list("redstone")()
assert(rstAddr ~= nil, "Redstone card not installed!")

local rst = component.proxy(rstAddr)

local sides = {
    ["bottom"] = 0,
    ["top"] = 1,
    ["back"] = 2,
    ["front"] = 3,
    ["right"] = 4,
    ["left"] = 5
}

local function triggerIfUnchanged(strength)
    local curTrigger = rst.getOutput(sides[triggerSide])
    if curTrigger ~= strength then
        rst.setOutput(sides[triggerSide], strength)
    end
end

local function dumpQueue()
    -- We don't actually NEED any events here, soooo
    repeat
        local eType = computer.pullSignal(0)
    until not eType
end

computer.beep(".")

while true do
    local percent = computer.energy() / computer.maxEnergy()
    if percent <= threshold then
        triggerIfUnchanged(15)
    else
        triggerIfUnchanged(0)
    end

    dumpQueue()
end
