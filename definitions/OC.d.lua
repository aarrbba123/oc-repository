---@meta

---@class component
component = {}

---Returns the documentation string for the method with the specified name of the component with the specified address, if any.
---@param address string Address of documentation
---@param method string Method to get documentation on
---@return string Documentation
function component.doc(address, method)
end

---Lists components connected to the computer
---@param filter string Name to filter the components
---@return table components A list of connected components
function component.list(filter)
end

---Returns the function table for the specified component
---@param address string Address of component
---@return table functions A table of function
function component.proxy(address)
end

---Calls a method on the specified component
---@param address string The component's address
---@param method string The name of the method/function
---@param ... any The method/function's paramaters
---@return any ... The method/function's return value(s), if any
function component.invoke(address, method, ...)
end

---Gets the primary for the specified component
---Raises an error if no primary component found
---@param component string Component to search
---@return string address Component's primary address
function component.getPrimary(component)
end

---Sets the primary for the specified component
---Removes the primary if the address is set to `nil`
---@param component string Component to set primary
---@param address string? Component address
function component.setPrimary(component, address)
end

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

---Gets the time, in real world seconds, the computer has been running, based on world time
---This means that it will only tick if the world is running (not paused, for example).
---@return number time Time passed since startup, in seconds.
function computer.uptime()
end
