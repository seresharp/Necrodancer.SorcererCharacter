local Util = {
    Array = { },
    Inventory = require "SorcererCharacter.scripts.Util_Inventory"
}

function Util.checkStructure(obj, structure)
    if type(obj) ~= type(structure) then
        return false
    elseif type(obj) ~= "table" then
        return obj == structure
    end
    
    for key, val in pairs(structure) do
        if not Util.checkStructure(obj[key], val) then
            return false
        end
    end
    
    return true
end

function Util.Array.last(array)
    if not array or #array == 0 then
        return nil
    end
    
    return array[#array]
end

return Util
