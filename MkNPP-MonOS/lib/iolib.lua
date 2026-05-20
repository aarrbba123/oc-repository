--- Basic library used to manage stdout/stderr buffer, clear it, etc.

_G.iolib = {}

function iolib.print(...)
    table.insert(_G.STDOUT_BUF, utils.allToStr(...))
end

function iolib.error(...)
    table.insert(_G.STDERR_BUF, utils.allToStr(...))
end

function iolib.flushBuffer(type)
    if type == "stderr" then
        _G.STDERR_BUF = {}
    else
        _G.STDOUT_BUF = {}
    end
end
