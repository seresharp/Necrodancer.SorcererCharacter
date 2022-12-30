local Entities = require "system.game.Entities"
local Inventory = require "necro.game.item.Inventory"
local ItemSlot = require "necro.game.item.ItemSlot"

local InventoryHelper = { }

function InventoryHelper.addUnequipped(holder, item)
    if type(item) == "number" then
        local invItem = InventoryHelper.getFromInventory(holder, item)
        if not invItem then
            invItem = Entities.getEntityByID(item)
            table.insert(holder.inventory.items, item)
            return invItem
        end
        
        InventoryHelper.unequip(item, holder)
        return item
    end
    
    local slot
    if type(item) == "string" then
        slot = Entities.getEntityPrototype(item).itemSlot.name
    else
        slot = item.itemSlot.name
    end
    
    local items = InventoryHelper.replaceSlot(holder, slot, { })
    local addedItem = Inventory.replace(item, holder)
    InventoryHelper.replaceSlot(holder, slot, items)
    table.insert(holder.inventory.items, addedItem.id)
    
    return addedItem
end

function InventoryHelper.insertSlot(holder, slot, item)
    local invItem = InventoryHelper.getFromInventory(holder, item)
    if not invItem then
        invItem = InventoryHelper.addUnequipped(holder, item)
    end
    
    table.insert(InventoryHelper.getSlot(holder, slot), invItem.id)
    return invItem
end

function InventoryHelper.removeSlot(holder, slot, i)
    local slotItems = InventoryHelper.getSlot(holder, slot)
    local id = slotItems[i]
    table.remove(slotItems, i)
    return id
end

function InventoryHelper.getFromInventory(holder, item)
    for _, invItemID in ipairs(holder.inventory.items) do
        if itemMatchesID(item, invItemID) then
            return Entities.getEntityByID(invItemID)
        end
    end
    
    return nil
end

function InventoryHelper.unequip(holder, item)
    for _, slot in pairs(ItemSlot.Type) do
        if type(slot) == "string" then
            local slotItems = InventoryHelper.getSlot(holder, slot)
            if slotItems then
                for i = #slotItems, 1, -1 do
                    if itemMatchesID(item, slotItems[i]) then
                        table.remove(slotItems, i)
                    end
                end
            end
        end
    end
end

function InventoryHelper.shiftSlot(holder, slot, offset)
    local slotItems = InventoryHelper.getSlot(holder, slot)
    if offset < 0 then
        for i = 1, math.abs(offset) do
            table.insert(slotItems, slotItems[1])
            table.remove(slotItems, 1)
        end
    else
        for i = 1, offset do
            table.insert(slotItems, 1, slotItems[#slotItems])
            table.remove(slotItems, #slotItems)
        end
    end
end

function InventoryHelper.swap(holder, item1, item2)
    local slotName1
    local slotName2
    local slotIndex1
    local slotIndex2
    
    for _, slotName in pairs(ItemSlot.Type) do
        if type(slotName) == "string" then
            local slotItems = InventoryHelper.getSlot(holder, slotName)
            for i = 1, #slotItems do
                if itemMatchesID(item1, slotItems[i]) then
                    slotName1 = slotName
                    slotIndex1 = i
                end
                
                if itemMatchesID(item2, slotItems[i]) then
                    slotName2 = slotName
                    slotIndex2 = i
                end
            end
        end
    end
    
    if not slotName1 or not slotName2 or not slotIndex1 or not slotIndex2 then
        return
    end
    
    local slotItems1 = InventoryHelper.getSlot(holder, slotName1)
    local slotItems2 = InventoryHelper.getSlot(holder, slotName2)
    
    local tempVal = slotItems1[slotIndex1]
    slotItems1[slotIndex1] = slotItems2[slotIndex2]
    slotItems2[slotIndex2] = tempVal
end

function InventoryHelper.replaceSlot(holder, slot, items)
    local origItems = InventoryHelper.getSlot(holder, slot)
    holder.inventory.itemSlots[slot] = items
    
    local nonUnique = { }
    
    for i = #holder.inventory.items, 1, -1 do
        local canRemoveItem = true
        for j = 1, #items do
            if holder.inventory.items[i] == items[j] then
                canRemoveItem = false
                nonUnique[items[j]] = true
                break
            end
        end
        
        if canRemoveItem then
            for j = 1, #origItems do
                if holder.inventory.items[i] == origItems[j] then
                    table.remove(holder.inventory.items, i)
                    break
                end
            end
        end
    end
    
    for i = 1, #items do
        if not nonUnique[items[i]] then
            table.insert(holder.inventory.items, items[i])
        end
    end
    
    return origItems
end

function InventoryHelper.getSlot(holder, slot)
    if not holder.inventory.itemSlots then
        holder.inventory.itemSlots = { }
    end
    
    if not holder.inventory.itemSlots[slot] then
        holder.inventory.itemSlots[slot] = { }
    end
    
    return holder.inventory.itemSlots[slot]
end

function InventoryHelper.print(holder)
    local inv = {
        slotItems = { },
        items = { }
    }
    for _, slot in pairs(ItemSlot.Type) do
        if type(slot) == "string" then
            inv.slotItems[slot] = { }
            for _, id in ipairs(InventoryHelper.getSlot(holder, slot)) do
                local item = Entities.getEntityByID(id)
                local name = "nil"
                if item ~= nil then
                    name = item.name.."#"..id
                end
                
                table.insert(inv.slotItems[slot], name)
            end
        end
    end
    
    for _, id in ipairs(holder.inventory.items) do
        local item = Entities.getEntityByID(id)
        local name = "nil"
        if item ~= nil then
            name = item.name.."#"..id
        end
        
        table.insert(inv.items, name)
    end
    
    print(inv)
end

function itemMatchesID(item, invID)
    if type(item) == "number" then
        return item == invID
    elseif type(item) == "string" then
        return Entities.getEntityByID(invID).name == item
    else
        return item and item.id == invID
    end
end

return InventoryHelper