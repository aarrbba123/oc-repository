--- A library whose sole purpose is to serialize and unserialize data

_G.serialization = {}

function serialization.serializeBasic(tblData, sepChar)
    if #tblData ~= 0 then
        local retData = tblData[1]
        for i = 2, #tblData do
            local val = tblData[i]
            retData = retData .. sepChar .. val
        end

        return retData
    else
        return ""
    end
end
