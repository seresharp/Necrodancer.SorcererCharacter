local ActionItem = require "necro.game.item.ActionItem"
local Constants = require "SorcererCharacter.scripts.Constants"
local Event = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local InventoryHelper = require "SorcererCharacter.scripts.InventoryHelper"
local ItemSlot = require "necro.game.item.ItemSlot"
local ManaWand = require "SorcererCharacter.scripts.ManaWand"

Event.inventoryAddItem.add("hideConsumablePickups", { order = "collect", sequence = Constants.sequenceFirst }, function(ev)
    if ev.holder.name ~= Constants.characterName or ev.item.spellReusable or not ev.item.itemSlot then
        return
    end

    if ev.item.itemSlot.name == ItemSlot.Type.ACTION then
        if ev.item.itemCastOnUse then
            InventoryHelper.removeSlot(ev.holder, ItemSlot.Type.ACTION, 1)
            ManaWand.placeSpellItemInBag(ev.holder, ev.item)
        else
            InventoryHelper.shiftSlot(ev.holder, ItemSlot.Type.ACTION, -1)
        end
    elseif ev.item.itemSlot.name == ItemSlot.Type.BOMB and #InventoryHelper.getSlot(ev.holder, ItemSlot.Type.BOMB) > 2 then
        ManaWand.placeSpellItemInBag(ev.holder, InventoryHelper.removeSlot(ev.holder, ItemSlot.Type.BOMB, 3))
    end
end)

Event.turn.add("useHiddenConsumables", { order = "itemPickup", sequence = Constants.sequenceLast }, function(ev)
    for _, action in pairs(ev.actionQueue) do
        if action.entity.name == Constants.characterName and action.entity.inventory then
            local lastItem = Inventory.getItemInSlot(action.entity, ItemSlot.Type.ACTION, #InventoryHelper.getSlot(action.entity, ItemSlot.Type.ACTION))
            if not lastItem then
                print("Found nil item in action slots! Possible inventory slot desync?")
                InventoryHelper.removeSlot(action.entity, ItemSlot.Type.ACTION, #InventoryHelper.getSlot(action.entity, ItemSlot.Type.ACTION))
            elseif not lastItem.spellReusable and not ManaWand.canOverrideSpell(lastItem) then
                ActionItem.activate(lastItem, action.entity)
            end
        end
    end
end)

Event.inventoryStackItem.add("hideBombMerge", { order = "despawn", sequence = Constants.sequenceLast }, function(ev)
    if ev.holder.name ~= Constants.characterName then
        return
    end
    
    local bombSlot = InventoryHelper.getSlot(ev.holder, ItemSlot.Type.BOMB)
    if #bombSlot == 0 or ev.itemStack.id ~= bombSlot[1] then
        return
    end
    
    local dummyBomb = Inventory.getItemInSlot(ev.holder, ItemSlot.Type.BOMB, 1)
    local slotItems = InventoryHelper.getSlot(ev.holder, ItemSlot.Type.ACTION)
    for i = 1, #slotItems do
        local bagItem = Inventory.getItemInSlot(ev.holder, ItemSlot.Type.ACTION, i)
        if bagItem.itemStack and bagItem.itemStack.mergeKey == dummyBomb.itemStack.mergeKey then
            bagItem.itemStack.quantity = bagItem.itemStack.quantity + dummyBomb.itemStack.quantity - 1
            dummyBomb.itemStack.quantity = 1
            return
        end
    end
    
    local newBombs = InventoryHelper.addUnequipped(ev.holder, "Bomb")
    newBombs.itemStack.quantity = dummyBomb.itemStack.quantity - 1
    
    dummyBomb.itemStack.quantity = 1
    
    ManaWand.placeSpellItemInBag(ev.holder, newBombs)
end)

-- Swapping the bomb slot to a dummy bomb during item pickup processing allows for events to happen normally
Event.turn.add("moveBombForward", { order = "frame1", sequence = -1e-14}, function(ev) alternateBombSlot(ev, -1) end)
Event.turn.add("moveBombBackward", { order = "frame1", sequence = 1e-14}, function(ev) alternateBombSlot(ev, 1) end)
function alternateBombSlot(ev, offset)
    for _, action in pairs(ev.actionQueue) do
        if action.entity.name == Constants.characterName then
            InventoryHelper.shiftSlot(action.entity, ItemSlot.Type.BOMB, offset)
        end
    end
end

-- Don't drop the dummy bomb
Event.inventoryAddItem.override("dropPreviousItem", { sequence = Constants.sequenceFirst }, function(func, ev)
    if ev.holder.name ~= Constants.characterName or ev.item.spellReusable or not ev.item.itemSlot or ev.item.itemSlot.name ~= ItemSlot.Type.BOMB then
        return func(ev)
    end
end)
