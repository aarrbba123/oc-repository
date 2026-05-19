--- Basic library used to manage stdout/stderr buffer, clear it, etc.

_G.iolib = {}

local function allToStr(...)
    local params = table.pack(...)
    local dataBuffer = ""

    for _, val in ipairs(params) do
        dataBuffer = dataBuffer .. tostring(val)
    end
    return dataBuffer
end

function iolib.print(...)
    table.insert(_G.STDOUT_BUF, allToStr(...))
end

function iolib.error(...)
    table.insert(_G.STDERR_BUF, allToStr(...))
end

function iolib.flushBuffer(type)
    if type == "stderr" then
        _G.STDERR_BUF = {}
    else
        _G.STDOUT_BUF = {}
    end
end
