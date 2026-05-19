_G.utils = {}

function utils.inBounds(val, min, max)
    if val > max or val < min then
        return false
    end

    return true
end
