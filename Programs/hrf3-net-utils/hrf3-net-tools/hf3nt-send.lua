--- A low-level send+recieve command

local argv = table.pack(...)

local net = require("hrf3-net-core")
local inv = require("hrf3-net-interactive")
local ser = require("monos-serialization")
local comp = require("component")

if comp.list("modem")() == nil then
    print("ERROR: A valid network card is needed to run this program!")
    return
end

if #argv < 1 then
    print("hf3nt-send [<COMMAND>], ...")
    return
end

local mdm = comp.modem
local locallyManaged = false

if mdm.isOpen(12930) == false then
    locallyManaged = true
    mdm.open(12930)
end

local num, packets = inv.chooseAddr(mdm, 2)
if num == nil then
    print("ERROR: No networks found!")
end

if locallyManaged == true then
    mdm.close(12930)
end
