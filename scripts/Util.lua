local Components = require "necro.game.data.Components"
local Constants = require "SorcererCharacter.scripts.Constants"
local Event = require "necro.event.Event"
local ItemBan = require "necro.game.item.ItemBan"

local Util = {
    Array = { },
    Inventory = require "SorcererCharacter.scripts.Util_Inventory",
    ItemPool = { }
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

function Util.ItemPool.replaceItems(pool, items)
    local newPool = "SorcererCharacter_"..pool:gsub("_", "")
    Components.register({
        [newPool] = {
            Components.constant.table("weights", { 1 })
        }
    })

    Event.entitySchemaLoadEntity.add(pool:gsub("_", ""), { order = "finalize", sequence = Constants.sequenceLast }, function(ev)
        if not (ev and ev.entity) then return end

        for _, item in ipairs(items) do
            if ev.entity.name == item then
                ev.entity[newPool] = { }
                return
            end
        end
    end)
    
    Event.itemGenerate.add(pool:gsub("_", ""), { order = "initParameters", sequence = -1e14 }, function(ev)
        if not Util.checkStructure(ev, {
            player = { name = Constants.characterName },
            itemPool = pool
        }) then return end
        
        -- Safe to assume we don't care about bans for items we're explicitly telling the game to generate
        ev.banMask = bit.bor(bit.bor(ItemBan.Flag.PICKUP, ItemBan.Flag.EQUIP), ItemBan.Flag.ACTIVATE)
        ev.itemPool = newPool
    end)
end

return Util
