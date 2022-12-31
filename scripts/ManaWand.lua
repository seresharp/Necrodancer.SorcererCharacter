local Action = require "necro.game.system.Action"
local Components = require "necro.game.data.Components"
local Constants = require "SorcererCharacter.scripts.Constants"
local CustomEntities = require "necro.game.data.CustomEntities"
local Damage = require "necro.game.system.Damage"
local Event = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local ItemSlot = require "necro.game.item.ItemSlot"
local Kill = require "necro.game.character.Kill"
local Util = require "SorcererCharacter.scripts.Util"

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
        },
        sprite = {
            width = 23,
            height = 22,
            texture = "mods/SorcererCharacter/sprites/mana_wand.png"
        },
        DynChar_dynamicItem = {
            framesX = 4,
            framesY = 1,
            width = 24,
            height = 24,
            offsetX = 0,
            offsetY = 0,
            texture = "mods/SorcererCharacter/sprites/mana_wand_anim.png",
        }
    }
})

local ManaWand = { }

ManaWand.spellCasts = { }

function ManaWand.placeSpellItemInBag(entity, item)
    local invItem = Util.Inventory.getFromInventory(entity, item) or Util.Inventory.addUnequipped(entity, item)
    Util.Inventory.unequip(entity, invItem)
    
    if not ManaWand.canOverrideSpell(invItem) then
        Util.Inventory.insertSlot(entity, ItemSlot.Type.ACTION, invItem)
        return
    end
    
    local insertAt = 1
    local slotItems = Util.Inventory.getSlot(entity, ItemSlot.Type.ACTION)
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
            Util.Inventory.swap(entity, item, spell)
            return item, spell
        end
        
        return
    elseif spell then
        for i = 8, #entity.inventory.itemSlots.action do
            local item = Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, i)
            if ManaWand.canOverrideSpell(item, spell) then
                Util.Inventory.swap(entity, item, spell)
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
            Util.Inventory.swap(entity, item, spells[i])
            return item, spells[i]
        end
    end
end

function ManaWand.checkUndoSpellOverride(entity, item)
    for i = 8, #entity.inventory.itemSlots.action do
        local spell = Inventory.getItemInSlot(entity, ItemSlot.Type.ACTION, i)
        if ManaWand.canOverrideSpell(item, spell) then
            Util.Inventory.swap(entity, item, spell)
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
    if not Util.checkStructure(ev, {
        holder = {
            name = Constants.characterName
        },
        item = { }
    }) then return end
    
    local spell = ManaWand.checkUndoSpellOverride(ev.holder, ev.item)
    Util.Inventory.unequip(ev.holder, ev.item)
    if spell then
        ManaWand.checkSpellOverride(ev.holder, nil, spell)
    end
end)

Event.objectSpecialAction.add("checkWandReload", { order = "reload", sequence = Constants.sequenceLast }, function(ev)
    if not Util.checkStructure(ev, {
        action = Action.Special.THROW,
        entity = {
            inventory = {
                itemSlots = {
                    [ItemSlot.Type.ACTION] = { },
                    [ItemSlot.Type.BOMB] = { },
                    [ItemSlot.Type.SPELL] = { },
                    [ItemSlot.Type.WEAPON] = { }
                }
            }
        }
    }) then return end
    
    local slots = ev.entity.inventory.itemSlots
    if #slots[ItemSlot.Type.ACTION] < 7 or #slots[ItemSlot.Type.BOMB] == 0 or #slots[ItemSlot.Type.SPELL] < 2 then return end
    if not Util.checkStructure(Util.Inventory.getItemInSlot(ev.entity, ItemSlot.Type.WEAPON), { name = Constants.wandName }) then return end
    
    -- Undo spell overrides before swapping
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.BOMB, 1))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.SPELL, 1))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.SPELL, 2))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.ACTION, 1))
    ManaWand.checkUndoSpellOverride(ev.entity, Inventory.getItemInSlot(ev.entity, ItemSlot.Type.ACTION, 2))
    
    -- Swap spell loadouts
    table.insert(slots[ItemSlot.Type.ACTION], 8, slots[ItemSlot.Type.ACTION][2])
    table.insert(slots[ItemSlot.Type.ACTION], 8, slots[ItemSlot.Type.ACTION][1])
    table.insert(slots[ItemSlot.Type.ACTION], 8, slots[ItemSlot.Type.SPELL][2])
    table.insert(slots[ItemSlot.Type.ACTION], 8, slots[ItemSlot.Type.SPELL][1])
    table.insert(slots[ItemSlot.Type.ACTION], 8, slots[ItemSlot.Type.BOMB][1])
    
    slots[ItemSlot.Type.BOMB][1] = slots[ItemSlot.Type.ACTION][3]
    slots[ItemSlot.Type.SPELL][1] = slots[ItemSlot.Type.ACTION][4]
    slots[ItemSlot.Type.SPELL][2] = slots[ItemSlot.Type.ACTION][5]
    
    for i = 1, 5 do
        table.remove(slots[ItemSlot.Type.ACTION], 1)
    end
    
    -- Check for spell override items
    for i = 8, #slots[ItemSlot.Type.ACTION] do
        local item = Inventory.getItemInSlot(ev.entity, ItemSlot.Type.ACTION, i)
        ManaWand.checkSpellOverride(ev.entity, item)
    end
end)

Event.weaponAttack.add("checkWandAttack", { order = "tickle" }, function(ev)
    if not Util.checkStructure(ev, {
        attacker = {
            inventory = { }
        },
        weapon = {
            name = Constants.wandName
        },
        result = {
            success = true,
            targets = { }
        }
    }) then return end
    
    local enemiesHit = 0
    for _, target in ipairs(ev.result.targets) do
        if Util.checkStructure(target, { victim = { SorcererCharacter_wandGrantKillCredit = { hit = false } } }) then
            enemiesHit = enemiesHit + 1
            target.victim.SorcererCharacter_wandGrantKillCredit.hit = true
            Kill.disableCredit(target.victim, Kill.Credit.SPELL_COOLDOWN)
        end
    end
    
    local spells = { }
    for _, item in ipairs(Inventory.getItems(ev.attacker)) do
        if item and item.itemIncreaseKillSpellCooldownRate then
            enemiesHit = enemiesHit * item.itemIncreaseKillSpellCooldownRate.multiplier
        elseif item and item.spellCooldownKills and item.spellCooldownKills.remainingKills > 0 then
            table.insert(spells, item)
        end
    end
    
    for _, spell in ipairs(spells) do
        spell.spellCooldownKills.remainingKills = spell.spellCooldownKills.remainingKills - enemiesHit
        if spell.spellCooldownKills.remainingKills < 0 then
            spell.spellCooldownKills.remainingKills = 0
        end
    end
end)

Event.inventoryAddItem.add("checkWandPickup", { order = "collect", sequence = Constants.sequenceFirst, filter = { "SorcererCharacter_wandGrantSpellsOnPickup" }}, function(ev)
    if not ev or not ev.holder or not ev.holder.inventory then return end
    
    Util.Inventory.replaceSlot(ev.holder, ItemSlot.Type.ACTION, { })
    Util.Inventory.replaceSlot(ev.holder, ItemSlot.Type.BOMB, { })
    Util.Inventory.replaceSlot(ev.holder, ItemSlot.Type.SPELL, { })
    
    ManaWand.spellCasts = { }
    
    -- Loadout 1
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.BOMB, "SpellTransmute").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.SPELL, "Sync_SpellDash").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.SPELL, "Sync_SpellBerzerk").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellHeal").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellShield").itemCastOnUse.spell)
    
    -- Loadout 2
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellEarth").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellFireball").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellPulse").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellBomb").itemCastOnUse.spell)
    table.insert(ManaWand.spellCasts, Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.ACTION, "SpellFreezeEnemies").itemCastOnUse.spell)
    
    -- Add a hidden bomb to receive bomb pickups
    Util.Inventory.insertSlot(ev.holder, ItemSlot.Type.BOMB, "Bomb")
end)

Event.entitySchemaLoadEntity.add("applyWandComponents", { order = "finalize", sequence = Constants.sequenceLast }, function(ev)
    if not ev or not ev.entity then return end
    
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
