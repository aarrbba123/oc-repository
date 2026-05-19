-- Library used to interact with the 'kernel'

_G.klib = {}

function klib.registerModule(moduleFunc)
    table.insert(_G.main, moduleFunc)
end
