---@meta
--- This contains definitions for the component class for OpenComputers.
--- More specifically, the bare-metal version.
--- Unfortunately, since the original definition files were deleted, we are forced to make our own

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
