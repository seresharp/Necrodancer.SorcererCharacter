local Constants = require "SorcererCharacter.scripts.Constants"
local CustomEntities = require "necro.game.data.CustomEntities"
local Event = require "necro.event.Event"
local ItemBan = require "necro.game.item.ItemBan"
local ItemSlot = require "necro.game.item.ItemSlot"
local Util = require "SorcererCharacter.scripts.Util"

CustomEntities.extend({
    name = Constants.characterName,
    template = CustomEntities.template.player(0),
    components = {
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
        }
    }
})

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
