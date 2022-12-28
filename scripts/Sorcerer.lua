local Components = require "necro.game.data.Components"
local CustomEntities = require "necro.game.data.CustomEntities"
local Event = require "necro.event.Event"
local ItemBan = require "necro.game.item.ItemBan"
local ItemSlot = require "necro.game.item.ItemSlot"

CustomEntities.extend({
    name = "SorcererCharacter_Sorcerer",
    template = CustomEntities.template.player(0),
    components = {
        friendlyName = { name = "Sorcerer" },
        textCharacterSelectionMessage = { text = "Sorcerer mode!\nStart with all spells,\nbut lose other slots." },
        traitStoryBosses = { bosses = { } },
        health = {
            health = 4,
            maxHealth = 4
        },
        inventoryBannedItems = {
            components = {
                itemBanWeaponlocked = ItemBan.Type.FULL,
                itemBanNoDamage = ItemBan.Type.FULL,
                itemToggleable = ItemBan.Type.FULL, -- Winged Boots use itemConvertible instead
                SorcererCharacter_itemBanSorcerer = ItemBan.Type.FULL,
                shrineBanWeaponlocked = ItemBan.Type.FULL,
                spellReusable = ItemBan.Type.GENERATION_ALL
            }
        },
        initialInventory = {
            items = {
                "SorcererCharacter_ManaWand", "ShovelBasic", "BagHolding", "Torch1", "CharmNazar",
                "SorcererCharacter_SpellBombMimic", "SorcererCharacter_SpellFreezeEnemiesMimic", "SorcererCharacter_SpellPulseMimic",
                "SorcererCharacter_SpellFireballMimic", "SorcererCharacter_SpellEarthMimic", "SorcererCharacter_SpellShieldMimic",
                "SorcererCharacter_SpellHealMimic", "SorcererCharacter_SpellTransmuteMimic", "Sync_SpellDash", "Sync_SpellBerzerk"
            }
        },
        inventoryCursedSlots = {
            slots = { ItemSlot.Type.WEAPON, ItemSlot.Type.SHOVEL, ItemSlot.Type.HUD }
        }
    }
})

Components.register({
    SorcererCharacter_itemBanSorcerer = {},
})

local bannedItems = nil
Event.entitySchemaLoadEntity.add("itemBanSorcerer", { order = "finalize", sequence = -565656 }, function (ev)
    if bannedItems == nil then
        bannedItems = { }
        local ban = function(items)
            for i = 1, #items do
                bannedItems[items[i]] = true
            end
        end
        
        -- Consumable bans
        ban({ "HolyWater", "ThrowingStars", "FamiliarRat" })
        -- These are maybes, depending on if I can make them give spell charges instead of making new items with that effect
               ban({ "Bomb", "Bomb3", "BombInfinity", "BombGrenade", "BombGrenade3" })
            -- ban({ "ScrollFireball", "ScrollFreezeEnemies", "ScrollShield", "ScrollPulse", "ScrollTransmute", "Sync_ScrollBerzerk" })
            -- ban({ "TomeEarth", "TomeFireball", "TomeFreeze", "TomePulse", "TomeShield", "TomeTransmute" })
        
        -- Hud bans
        ban({ "HudBackpack", "Holster", "BagHolding" })
        
        -- Charm bans
        ban({ "Sync_CharmThrowing" })
        
        -- Ring bans
        ban({ "RingBecoming" })
        ban({ "RingMana", "RingWonder" }) -- Temporary until I look into changing pools instead
        
        -- Shield bans
        ban({ "Sync_ShieldShove" })
    end
    
    if bannedItems[ev.entity.name] then
        ev.entity.SorcererCharacter_itemBanSorcerer = { }
    end
end)
