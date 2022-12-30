local Components = require "necro.game.data.Components"
local Constants = require "SorcererCharacter.scripts.Constants"
local Event = require "necro.event.Event"

Components.register({
    [Constants.itemBan] = { },
})

local bannedItems = nil
Event.entitySchemaLoadEntity.add("itemBanSorcerer", { order = "finalize", sequence = Constants.sequenceLast }, function(ev)
    if bannedItems == nil then
        bannedItems = { }
        local ban = function(items)
            for i = 1, #items do
                bannedItems[items[i]] = true
            end
        end
        
        -- Consumable bans
        ban({ "HolyWater", "ThrowingStars", "FamiliarRat" })
        
        -- Ring bans
        ban({ "RingBecoming" })
        ban({ "RingMana", "RingWonder" }) -- Temporary until I look into changing pools instead
        
        -- Shield bans
        ban({ "Sync_ShieldShove" })
    end
    
    if bannedItems[ev.entity.name] then
        ev.entity[Constants.itemBan] = { }
    end
end)