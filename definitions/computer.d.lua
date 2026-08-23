---@meta
--- This contains definitions for the computer class for OpenComputers.
--- More specifically, the bare-metal version.
--- Unfortunately, since the original definition files were deleted, we are forced to make our own

---@class computer
computer = {}

---Causes the computer to beep
---@param value string '.' to short beep, '-' to long beep
function computer.beep(value)
end

---Causes the computer to beep
---@param freq number The frequency to beep
---@param time number How long to beep, in seconds
---@overload fun(value: string)
function computer.beep(freq, time)
end

---Pushes the signal into the signal queue
---@param name string Name of the signal
---@param ... any The signal data
function computer.pushSignal(name, ...)
end

---Pulls the signal from the signal queue
---@param timeout number How long to take before timing out, returning nil
---@return any? signal Signal data, or `nil` if timed out.
function computer.pullSignal(timeout)
end

---Gets the boot filesystem of the computer
---@return string address Boot address of the system
function computer.getBootAddress()
end

---Gets unused/free memory in the computer
---@return number amount Amount of free memory left in the computer, in bytes.
function computer.freeMemory()
end

---Gets total memory in the computer
---@return number amount Amount of total memory installed in the computer, in bytes.
function computer.totalMemory()
end

---Gets the time, in real world seconds, the computer has been running, based on world time
---This means that it will only tick if the world is running (not paused, for example).
---@return number time Time passed since startup, in seconds.
function computer.uptime()
end

---Gets information of each component, with the key as its address
---@return table components A list of components
function computer.getDeviceInfo()
end

---Gets the computer's current energy buffer
---@return number amount Amount of energy stored in the computer.
function computer.energy()
end

---Gets the computer's max energy buffer
---@return number capacity The amount of energy that can be stored in the computer.
function computer.maxEnergy()
end
