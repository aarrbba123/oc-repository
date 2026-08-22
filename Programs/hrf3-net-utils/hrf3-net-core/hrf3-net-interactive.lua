-- Common interactive code shared between hrf3-net programs
-- OpenOS-only, obviously.

local net = require("hrf3-net-core")

local interactive = {}

interactive.chooseAddr = function(modem, timeout)
    local res = net.scan(modem, timeout)
    if #res == 0 then
        return nil
    elseif #res == 1 then
        return res[1]
    end

    -- Get info
    -- TODO: Finish this
    net.sendSysReq(modem, )

    -- Print number, address, and distance, info, version


end

return interactive
