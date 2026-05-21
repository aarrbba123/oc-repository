--- Miniaturized HRF3-NET functions

local invoke = component.invoke

PRINT_INTERVAL = 80

STDOUT_BUF = {}
STDOUT_LINE = 1

local function representStr(str)
    return "\"" .. str .. "\""
end

local function tableToStr(tab)
    local dataBuffer = "{"
    for i, val in ipairs(tab) do
        local sVal = val
        local nVal = ", "

        if type(val) == "table" then
            sVal = tableToStr(val)
        elseif type(val) == "string" then
            sVal = representStr(val)
        end

        if i == #tab then
            nVal = ""
        end

        dataBuffer = dataBuffer .. tostring(sVal) .. nVal
    end
    dataBuffer = dataBuffer .. "}"
    return dataBuffer
end

local function allToStr(...)
    local params = table.pack(...)
    local dataBuffer = ""

    for _, val in ipairs(params) do
        local sVal = val
        if type(val) == "table" then
            -- pls don't forget to unpack the input table k thx
            sVal = tableToStr(val)
        end

        dataBuffer = dataBuffer .. tostring(sVal)
    end
    return dataBuffer
end

function print(...)
    table.insert(STDOUT_BUF, allToStr(...) .. "\n")
end

local function sendPrintBuf()
    if #STDOUT_BUF > 0 then
        local modem = component.list("modem")()
        local sendBuf = ""
        for i = 2, #STDOUT_BUF do
            sendBuf = sendBuf .. '\0' .. STDOUT_BUF[i]
        end
        local stat = invoke(modem, "broadcast", 12930, "hrf3-net", "LOG_DAT", "LOG", STDOUT_LINE, sendBuf)

        if stat == true then
            STDOUT_LINE = #STDOUT_BUF + 1
            STDOUT_BUF = {}
        end
    end
end

--- Main code
local modem = component.list("modem")()
if not invoke(modem, "isOpen", 12930) then
    invoke(modem, "open", 12930)
end

computer.beep(".")
local print_tick = 0
while true do
    if print_tick >= PRINT_INTERVAL then
        print_tick = 0
        sendPrintBuf()
    else
        print_tick = print_tick + 1
    end

    local EVENT_BUF = {}

    repeat
        local event = table.pack(computer.pullSignal(0.01))
        local type = nil
        if event and #event ~= 0 then
            type = event[0]
            local data = table.unpack(event, 2, #event)
            table.insert(EVENT_BUF, event)

            print("TYPE: ", type)
            print("DATA: ", data)
        end

    until not type

    if #EVENT_BUF ~= 0 then
        print("EVENT DUMP: ", EVENT_BUF)
    end
end
