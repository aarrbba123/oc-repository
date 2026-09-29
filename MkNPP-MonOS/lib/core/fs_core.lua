--- Filesystem core library
--- Contains just enough functions to interact with the main filesystem

local fscore = {}

fscore.filesystem = component.proxy(computer.getBootAddress())

function fscore.exists(path)
    return fscore.filesystem.exists(path)
end

function fscore.readAll(path)
    local retBuf = ""
    local fd = fscore.filesystem.open(path, 'r')
    repeat
        local curBuf = fscore.filesystem.read(fd)
        if curBuf ~= nil then
            retBuf = retBuf .. curBuf
        end
    until curBuf == nil
end

return fscore
