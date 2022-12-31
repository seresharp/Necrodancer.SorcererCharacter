local ActionItem = require "necro.game.item.ActionItem"
local Constants = require "SorcererCharacter.scripts.Constants"
local Event = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local ItemSlot = require "necro.game.item.ItemSlot"
local ManaWand = require "SorcererCharacter.scripts.ManaWand"
local Util = require "SorcererCharacter.scripts.Util"

Event.inventoryAddItem.add("hideConsumablePickups", { order = "collect", sequence = Constants.sequenceFirst }, function(ev)
    if not Util.checkStructure(ev, {
        holder = {
            name = Constants.characterName,
            inventory = { }
        },
        item = {
            itemSlot = { }
        }
    }) or ev.item.spellReusable then return end

    if ev.item.itemSlot.name == ItemSlot.Type.ACTION then
        if ev.item.itemCastOnUse then
            Util.Inventory.removeSlot(ev.holder, ItemSlot.Type.ACTION, 1)
            ManaWand.placeSpellItemInBag(ev.holder, ev.item)
        else
            Util.Inventory.shiftSlot(ev.holder, ItemSlot.Type.ACTION, -1)
        end
    elseif ev.item.itemSlot.name == ItemSlot.Type.BOMB and #Util.Inventory.getSlot(ev.holder, ItemSlot.Type.BOMB) > 2 then
        ManaWand.placeSpellItemInBag(ev.holder, Util.Inventory.removeSlot(ev.holder, ItemSlot.Type.BOMB, 3))
    end
end)

Event.turn.add("useHiddenConsumables", { order = "itemPickup", sequence = Constants.sequenceLast }, function(ev)
    if not ev or not ev.actionQueue then return end
    
    for _, action in pairs(ev.actionQueue) do
        if not Util.checkStructure(action, {
            entity = {
                name = Constants.characterName,
                inventory = {
                    itemSlots = {
                        [ItemSlot.Type.ACTION] = { }
                    }
                }
            }
        }) then goto continue end
        
        local lastItem = Inventory.getItemInSlot(action.entity, ItemSlot.Type.ACTION, #action.entity.inventory.itemSlots[ItemSlot.Type.ACTION])
        if not lastItem then
            print("Found nil item in action slots! Possible inventory slot desync?")
            Util.Inventory.removeSlot(action.entity, ItemSlot.Type.ACTION, #Util.Inventory.getSlot(action.entity, ItemSlot.Type.ACTION))
        elseif not lastItem.spellReusable and not ManaWand.canOverrideSpell(lastItem) then
            ActionItem.activate(lastItem, action.entity)
        end
    ::continue:: end
end)

Event.inventoryStackItem.add("hideBombMerge", { order = "despawn", sequence = Constants.sequenceLast }, function(ev)
    if not Util.checkStructure(ev, {
        holder = {
            name = Constants.characterName,
            inventory = {
                itemSlots = {
                    [ItemSlot.Type.BOMB] = { }
                }
            }
        },
        itemStack = { }
    }) then return end
    
    local bombSlots = ev.holder.inventory.itemSlots.bomb
    if #bombSlots == 0 or ev.itemStack.id ~= bombSlots[1] then
        return
    end
    
    local dummyBomb = Inventory.getItemInSlot(ev.holder, ItemSlot.Type.BOMB, 1)
    local slotItems = Util.Inventory.getSlot(ev.holder, ItemSlot.Type.ACTION)
    for i = 1, #slotItems do
        local bagItem = Inventory.getItemInSlot(ev.holder, ItemSlot.Type.ACTION, i)
        if bagItem.itemStack and bagItem.itemStack.mergeKey == dummyBomb.itemStack.mergeKey then
            bagItem.itemStack.quantity = bagItem.itemStack.quantity + dummyBomb.itemStack.quantity - 1
            dummyBomb.itemStack.quantity = 1
            return
        end
    end
    
    local newBombs = Util.Inventory.addUnequipped(ev.holder, "Bomb")
    newBombs.itemStack.quantity = dummyBomb.itemStack.quantity - 1
    dummyBomb.itemStack.quantity = 1
    
    ManaWand.placeSpellItemInBag(ev.holder, newBombs)
end)

-- Swapping the bomb slot to a dummy bomb during item pickup processing allows for events to happen normally
Event.turn.add("moveBombForward", { order = "frame1", sequence = -1e-14}, function(ev) alternateBombSlot(ev, -1) end)
Event.turn.add("moveBombBackward", { order = "frame1", sequence = 1e-14}, function(ev) alternateBombSlot(ev, 1) end)
function alternateBombSlot(ev, offset)
    if not ev or not ev.actionQueue then return end
    
    for _, action in pairs(ev.actionQueue) do
        if Util.checkStructure(action, {
            entity = {
                name = Constants.characterName,
                inventory = { }
            }
        }) then
            Util.Inventory.shiftSlot(action.entity, ItemSlot.Type.BOMB, offset)
        end
    end
end

-- Don't drop the dummy bomb
Event.inventoryAddItem.override("dropPreviousItem", { sequence = Constants.sequenceFirst }, function(func, ev)
    if not Util.checkStructure(ev, {
        holder = {
            name = Constants.characterName
        },
        item = {
            itemSlot = {
                name = ItemSlot.Type.BOMB
            }
        }
    }) then func(ev) end
end)
