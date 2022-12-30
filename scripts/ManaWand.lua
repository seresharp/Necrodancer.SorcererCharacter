local Action = require "necro.game.system.Action"
local Components = require "necro.game.data.Components"
local Constants = require "SorcererCharacter.scripts.Constants"
local CustomEntities = require "necro.game.data.CustomEntities"
local Damage = require "necro.game.system.Damage"
local Event = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local InventoryHelper = require "SorcererCharacter.scripts.InventoryHelper"
local ItemSlot = require "necro.game.item.ItemSlot"
local Kill = require "necro.game.character.Kill"

Components.register({
    SorcererCharacter_wandGrantKillCredit = {
        Components.field.bool("hit", false)
    },
    SorcererCharacter_wandGrantSpellsOnPickup = { },
    SorcererCharacter_overrideCast = {
        Components.constant.string("spell", "")
    }
})

CustomEntities.extend({
    name = Constants.wandName,
    template = CustomEntities.template.item("weapon_eli"),
    components = {
        friendlyName = { name = "Wand of Mana" },
        SorcererCharacter_wandGrantSpellsOnPickup = { },
        weaponReloadable = { ammoPerReload = 0 },
        itemFlyawayOnActivation = {
            text = "Swapping Spells!"
        }
    }
})

local ManaWand = { }

ManaWand.spellCasts = { }

function ManaWand.placeSpellItemInBag(entity, item)
    local invItem = InventoryHelper.getFromInventory(entity, item) or InventoryHelper.addUnequipped(entity, item)
    InventoryHelper.unequip(entity, invItem)
    
    if not ManaWand.canOverrideSpell(invItem) then
        InventoryHelper.insertSlot(entity, ItemSlot.Type.ACTION, invItem)
        return
    end
    
    local insertAt = 1
    local slotItems = InventoryHelper.getSlot(entity, ItemSlot.Type.ACTION)
    for i = #slotItems, 1, -1 do
        local bagItem = Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, i)
        if bagItem.spellReusable or bagItem.itemCastOnUse then
            insertAt = i + 1
            break
        end
    end
    
    table.insert(slotItems, insertAt, invItem.id)
    ManaWand.checkSpellOverride(entity, invItem)
end

function ManaWand.checkSpellOverride(entity, item, spell)
    if item and spell then
        if ManaWand.canOverrideSpell(item, spell) then
            InventoryHelper.swap(entity, item, spell)
            return item, spell
        end
        
        return
    elseif spell then
        for i = 8, #entity.inventory.itemSlots.action do
            local item = Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, i)
            if ManaWand.canOverrideSpell(item, spell) then
                InventoryHelper.swap(entity, item, spell)
                return item, spell
            end
        end 
    end
    
    local spells = {
        Inventory.getItemInSlot(entity, ItemSlot.Type.BOMB, 1),
        Inventory.getItemInSlot(entity, ItemSlot.Type.SPELL, 1),
        Inventory.getItemInSlot(entity, ItemSlot.Type.SPELL, 2),
        Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, 1),
        Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, 2)
    }
    
    -- Check for the dummy bomb
    if spells[1].name == "Bomb" then
        spells[1] = Inventory.getItemInSlot(entity, ItemSlot.Type.BOMB, 2)
    end
    
    for i = 1, #spells do
        if ManaWand.canOverrideSpell(item, spells[i]) then
            InventoryHelper.swap(entity, item, spells[i])
            return item, spells[i]
        end
    end
end

function ManaWand.checkUndoSpellOverride(entity, item)
    for i = 8, #entity.inventory.itemSlots.action do
        local spell = Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, i)
        if ManaWand.canOverrideSpell(item, spell) then
            InventoryHelper.swap(entity, item, spell)
            return spell
        end
    end
end

function ManaWand.canOverrideSpell(item, spell)
    if not item or item.spellReusable or not ManaWand.getSpellcast(item) then
        return false
    end

    if spell then
        if not spell.spellReusable or not ManaWand.getSpellcast(spell) then
            return false
        end
        
        return ManaWand.getSpellcast(item) == ManaWand.getSpellcast(spell)
    end
    
    for _, spellcast in ipairs(ManaWand.spellCasts) do
        if ManaWand.getSpellcast(item) == spellcast then
            return true
        end
    end
    
    return false
end

function ManaWand.getSpellcast(item)
    if item and item.SorcererCharacter_overrideCast then
        return item.SorcererCharacter_overrideCast.spell
    elseif item and item.itemCastOnUse then
        return item.itemCastOnUse.spell
    end
    
    return nil
end

Event.inventoryDetachItem.add("undoOverride", { order = "detach", sequence = Constants.sequenceFirst }, function(ev)
    if ev.holder.name == Constants.characterName then
        local spell = ManaWand.checkUndoSpellOverride(ev.holder, ev.item)
        InventoryHelper.unequip(ev.holder, ev.item)
        if spell then
            ManaWand.checkSpellOverride(ev.holder, nil, spell)
        end
    end
end)

Event.objectSpecialAction.add("checkWandReload", { order = "reload", sequence = Constants.sequenceLast }, function(ev)
    if ev.action ~= Action.Special.THROW or not ev.entity.inventory or #InventoryHelper.getSlot(ev.entity, ItemSlot.Type.ACTION) < 7 then return end
    
    local slots = ev.entity.inventory.itemSlots;
    local weapon = Inventory.getItemInSlot(ev.entity, ItemSlot.Type.WEAPON, 1)
    if weapon.name ~= Constants.wandName then return end
    
    -- Undo spell overrides before swapping
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.BOMB, 1))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.SPELL, 1))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.SPELL, 2))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.ACTION, 1))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.ACTION, 2))
    
    -- Swap spell loadouts
    table.insert(slots.action, 8, slots.action[2])
    table.insert(slots.action, 8, slots.action[1])
    table.insert(slots.action, 8, slots.spell[2])
    table.insert(slots.action, 8, slots.spell[1])
    table.insert(slots.action, 8, slots.bomb[1])
    
    slots.bomb[1] = slots.action[3]
    slots.spell = { slots.action[4], slots.action[5] }
    
    for i = 1, 5 do
        table.remove(slots.action, 1)
    end
    
    -- Check for spell override items
    if #slots.action > 7 then
        for i = 8, #slots.action do
            local item = Inventory.getItemInSlot(ev.entity, ItemSlot.Type.ACTION, i)
            ManaWand.checkSpellOverride(ev.entity, item)
        end
    end
end)

Event.objectDealDamage.add("checkWandAttack", { order = "replacementEffects" }, function(ev)
    if ev.damage > 0 or not ev.isParryable or ev.attacker == ev.victim or not ev.victim.SorcererCharacter_wandGrantKillCredit or ev.victim.SorcererCharacter_wandGrantKillCredit.hit then
        return
    end
    
    local weapon = Inventory.getItemInSlot(ev.attacker, ItemSlot.Type.WEAPON, 1)
    if not weapon or weapon.name ~= Constants.wandName then return end
    
    for _, item in ipairs(Inventory.getItems(ev.attacker)) do
        if item.spellCooldownKills and item.spellCooldownKills.remainingKills > 0 then
            item.spellCooldownKills.remainingKills = item.spellCooldownKills.remainingKills - 1
        end
    end
    
    ev.victim.SorcererCharacter_wandGrantKillCredit.hit = true
    Kill.disableCredit(ev.victim, Kill.Credit.SPELL_COOLDOWN)
end)

Event.inventoryAddItem.add("checkWandPickup", { order = "collect", sequence = Constants.sequenceFirst, filter = { "SorcererCharacter_wandGrantSpellsOnPickup" }}, function(ev)
    InventoryHelper.replaceSlot(ev.holder, ItemSlot.Type.ACTION, { })
    InventoryHelper.replaceSlot(ev.holder, ItemSlot.Type.BOMB, { })
    InventoryHelper.replaceSlot(ev.holder, ItemSlot.Type.SPELL, { })
    
    -- Loadout 1
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.BOMB, "SpellTransmute").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.SPELL, "Sync_SpellDash").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.SPELL, "Sync_SpellBerzerk").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellHeal").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellShield").itemCastOnUse.spell)
    
    -- Loadout 2
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellEarth").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellFireball").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellPulse").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellBomb").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellFreezeEnemies").itemCastOnUse.spell)
    
    -- Add a hidden bomb to receive bomb pickups
    InventoryHelper.insertSlot(ev.holder, ItemSlot.Type.BOMB, "Bomb")
end)

Event.entitySchemaLoadEntity.add("applyWandComponents", { order = "finalize", sequence = Constants.sequenceLast }, function(ev)
    if ev.entity.tickleGrantKillCredit then
        ev.entity.SorcererCharacter_wandGrantKillCredit = { }
    end
    
    if ev.entity.itemCastOnUse then 
        if ev.entity.itemCastOnUse.spell == "SpellcastBomb" or ev.entity.itemCastOnUse.spell == "SpellcastBombGrenade" then
            ev.entity.SorcererCharacter_overrideCast = {
                spell = "SpellcastMagicBomb"
            }
        elseif ev.entity.itemCastOnUse.spell == "Sync_ScrollBerzerk" then
            ev.entity.SorcererCharacter_overrideCast = {
                spell = "Sync_SpellBerzerk"
            }
        end
    end
end)

return ManaWand
