local Constants = require "SorcererCharacter.scripts.Constants"
local CustomEntities = require "necro.game.data.CustomEntities"
local Event = require "necro.event.Event"
local ItemBan = require "necro.game.item.ItemBan"
local ItemSlot = require "necro.game.item.ItemSlot"
local Util = require "SorcererCharacter.scripts.Util"

CustomEntities.extend({
    name = Constants.characterName,
    template = CustomEntities.template.player(0),
    components = {{
        friendlyName = { name = "Sorcerer" },
        textCharacterSelectionMessage = { text = "Sorcerer mode!\nStart with all spells,\nbut lose other slots." },
        traitStoryBosses = { bosses = { } },
        inventoryBannedItems = {
            components = {
                itemBanWeaponlocked   = ItemBan.Type.FULL,
                shrineBanWeaponlocked = ItemBan.Type.FULL,
                itemBanNoDamage       = ItemBan.Type.FULL,
                itemToggleable        = ItemBan.Type.FULL, -- Winged Boots use itemConvertible instead
                itemBag               = ItemBan.Type.FULL,
                itemHolster           = ItemBan.Type.FULL,
                spellReusable         = ItemBan.Type.LOCK,
                [Constants.itemBan]   = ItemBan.Type.GENERATION_ALL
            }
        },
        initialInventory = {
            items = { Constants.wandName, "ShovelBasic", "BagHolding", "Torch1", "CharmNazar" }
        },
        inventoryCursedSlots = {
            slots = {
                [ItemSlot.Type.WEAPON] = true,
                [ItemSlot.Type.HUD] = true
            }
        },
        extraModeDancepadGrantItems = {
            types = { "RingMana", "ArmorChainmail", "FoodMagicCarrot" }
        },
        sprite = {
            texture = "mods/SorcererCharacter/sprites/sorcerer_body.png"
        },
        cloneSprite = {
            texture = "mods/SorcererCharacter/sprites/sorcerer_clone.png"
        },
        bestiary = {
            image = "ext/bestiary/bestiary_electricmage.png"
        }
    },
    {
        sprite = {
            texture = "mods/SorcererCharacter/sprites/sorcerer_head.png"
        }
    }}
})

-- Cadence voice lines sound off with the sprite I made
-- Could inherit from bard instead, but I'd rather not make a major change like that right now
Event.entitySchemaLoadNamedEntity.add("swapVoiceLines", { key = Constants.characterName }, function(ev)
    if not ev or not ev.entity then return end
    
    for _, component in pairs(ev.entity) do
        if type(component) == "table" and type(component.sound) == "string" and component.sound:find("^cadence") then
            component.sound = component.sound:gsub("^cadence", "bard")
        end
    end
    
    ev.entity.voiceMeleeAttack = {
        sounds = { "bardMelee1", "bardMelee2", "bardMelee3", "bardMelee4" }
    }
    ev.entity.voiceSpellCasterPrefix = {
        fallback = "bardMelee3",
        prefix = "bard"
    }
end)

-- Blood magic doesn't reset cooldowns. Hopefully will make the character more fast paced
Event.spellItemActivate.override("resetKillCooldown", { sequence = Constants.sequenceFirst }, function(func, ev)
    if not Util.checkStructure(ev, {
        caster = {
            name = Constants.characterName
        },
        cooldowns = { }
    }) or #ev.cooldowns == 0 then func(ev) end
end)

Util.ItemPool.replaceItems("Sync_itemPoolSpecialOffer", { "BombInfinity", "RingMana", "RingWonder" })
