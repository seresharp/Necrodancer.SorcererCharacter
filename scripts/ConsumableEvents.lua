local Consumable = require "necro.game.item.Consumable"
local Event = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local ItemSlot = require "necro.game.item.ItemSlot"

Event.inventoryAddItem.add("consumeOnPickup", { order = "collect", sequence = -565656 }, function (ev)
    if ev.holder.name ~= "SorcererCharacter_Sorcerer" or ev.item.spellReusable then return end
    
    if ev.item.activeItemConsumable then
        local amount = 1
        if ev.item.itemStack and ev.item.itemStack.quantity then
            amount = ev.item.itemStack.quantity
        end
        
        for i = 1, amount do
            Consumable.consume(ev.item, amount, ev.holder)
        end
    end
end)
