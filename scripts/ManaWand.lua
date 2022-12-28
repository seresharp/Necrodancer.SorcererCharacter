local Action = require "necro.game.system.Action"
local Components = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"
local Damage = require "necro.game.system.Damage"
local Event = require "necro.event.Event"
local Inventory = require "necro.game.item.Inventory"
local ItemSlot = require "necro.game.item.ItemSlot"
local ItemStorage = require "necro.game.item.ItemStorage"
local Kill = require "necro.game.character.Kill"

local GameXML = require "necro.game.data.GameXML"

Components.register({
    SorcererCharacter_wandGrantKillCredit = {
        Components.field.bool("hit", false)
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_ManaWand",
    template = CustomEntities.template.item("weapon_eli"),
    components = {
        friendlyName = { name = "Wand of Mana" },
        weaponKnockback = { distance = 0 },
        weaponReloadable = { ammoPerReload = 0 },
        itemFlyawayOnActivation = {
            text = "Swapping Spells!"
        }
    }
})

-- This makes BIG assumptions about inventory layout, but I'm probably too lazy to figure out a better implementation
Event.objectSpecialAction.add("checkWandReload", { order = "reload", sequence = 565656 }, function (ev)
    if ev.action ~= Action.Special.THROW then return end
    
    local weapon = Inventory.getItemInSlot(ev.entity, ItemSlot.Type.WEAPON, 1)
    if weapon.name ~= "SorcererCharacter_ManaWand" then return end
    
    if #ev.entity.inventory.itemSlots.action == 8 then
        ev.entity.inventory.itemSlots.bomb = { ev.entity.inventory.itemSlots.action[1] }
        table.remove(ev.entity.inventory.itemSlots.action, 1)
    elseif #ev.entity.inventory.itemSlots.action == 7 then
        table.insert(ev.entity.inventory.itemSlots.action, ev.entity.inventory.itemSlots.bomb[1])
        table.insert(ev.entity.inventory.itemSlots.action, ev.entity.inventory.itemSlots.spell[1])
        table.insert(ev.entity.inventory.itemSlots.action, ev.entity.inventory.itemSlots.spell[2])
        table.insert(ev.entity.inventory.itemSlots.action, ev.entity.inventory.itemSlots.action[1])
        table.insert(ev.entity.inventory.itemSlots.action, ev.entity.inventory.itemSlots.action[2])
        
        ev.entity.inventory.itemSlots.bomb = { ev.entity.inventory.itemSlots.action[3] }
        ev.entity.inventory.itemSlots.spell = { ev.entity.inventory.itemSlots.action[4], ev.entity.inventory.itemSlots.action[5] }
        
        for i = 1, 5 do
            table.remove(ev.entity.inventory.itemSlots.action, 1)
        end
    end
end)

Event.objectDealDamage.add("checkWandAttack", { order = "replacementEffects" }, function (ev)
    if ev.damage > 0 or not ev.isParryable or ev.attacker == ev.victim or not ev.victim.SorcererCharacter_wandGrantKillCredit or ev.victim.SorcererCharacter_wandGrantKillCredit.hit then
        return
    end
    
    local weapon = Inventory.getItemInSlot(ev.attacker, ItemSlot.Type.WEAPON, 1)
    if not weapon or weapon.name ~= "SorcererCharacter_ManaWand" then return end
    
    for _, item in ipairs(Inventory.getItems(ev.attacker)) do
        if item.spellCooldownKills and item.spellCooldownKills.remainingKills > 0 then
            item.spellCooldownKills.remainingKills = item.spellCooldownKills.remainingKills - 1
        end
    end
    
    ev.victim.SorcererCharacter_wandGrantKillCredit.hit = true
    Kill.disableCredit(ev.victim, Kill.Credit.SPELL_COOLDOWN)
end)

Event.entitySchemaLoadEntity.add("applyMonsterWandComponents", { order = "finalize", sequence = 565656 }, function (ev)
    if ev.entity.tickleGrantKillCredit then
        ev.entity.SorcererCharacter_wandGrantKillCredit = { }
    end
end)
