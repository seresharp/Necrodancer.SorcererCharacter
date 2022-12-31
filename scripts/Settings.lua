local Constants = require "SorcererCharacter.scripts.Constants"
local Entities = require "system.game.Entities"
local Event = require "necro.event.Event"
local GameState = require "necro.client.GameState"
local Inventory = require "necro.game.item.Inventory"
local PlayerList = require "necro.client.PlayerList"
local Settings = require "necro.config.Settings"
local Util = require "SorcererCharacter.scripts.Util"

startingHealth = Settings.entitySchema.number({
    id = "startingHealth",
    name = "Starting Hearts",
    desc = "The amount of hearts the Sorcerer starts with",
    default = 3,
    minimum = .5,
    maximum = 10,
    step = .5,
    cheat = true
})

beatSpeed = Settings.entitySchema.number({
    id = "beatSpeed",
    name = "Beat Speed",
    desc = "The amount of turns per beat",
    default = 1,
    minimum = 1,
    cheat = true
})

cooldownMultiplier = Settings.entitySchema.number({
    id = "cooldownMultiplier",
    name = "Cooldown Multiplier",
    desc = "A multiplier applied to spell cooldown rate",
    default = 1,
    minimum = 0,
    cheat = true
})

cooldownBetweenLevels = Settings.shared.bool({
    id = "resetCooldownBetweenLevels",
    name = "Reset Cooldowns Between Levels",
    desc = "If spell cooldowns should reset before each new level",
    default = false,
    cheat = true
})

cooldownMaxPercent = Settings.shared.percent({
    id = "cooldownMaxPercent",
    name = "Cooldown Required Kills",
    desc = "A multiplier applied to the required kills for each spell cooldown (rounds up)",
    default = .75,
    maximum = 2,
    step = .05,
    cheat = true
})

wandKnockback = Settings.entitySchema.number({
    id = "wandKnockback",
    name = "Wand Knockback",
    desc = "The amount of tiles to knock an enemy backwards on hit",
    default = 1,
    minimum = 0,
    cheat = true
})

wandRange = Settings.entitySchema.number({
    id = "wandRange",
    name = "Wand Range",
    desc = "The range of the Sorcerer's wand attack",
    default = 1,
    minimum = 1,
    cheat = true
})

Event.entitySchemaLoadNamedEntity.add("applyCharacterComponents", { key = Constants.characterName }, function(ev)
    if not ev or not ev.entity then return end
    
    ev.entity.health = {
        health = startingHealth * 2,
        maxHealth = startingHealth * 2
    }
    
    if beatSpeed > 1 then
        ev.entity.rhythmSubdivision = {
            factor = beatSpeed
        }
    end
end)

Event.entitySchemaLoadNamedEntity.add("applyWandComponents", { key = Constants.wandName }, function(ev)
    if not ev or not ev.entity then return end
    
    ev.entity.itemIncreaseKillSpellCooldownRate = {
        multiplier = cooldownMultiplier
    }
    
    ev.entity.weaponKnockback = {
        distance = wandKnockback
    }
    
    if wandKnockback == 0 then
        ev.entity.weaponOverrideBeatDelay = {
            delay = 1
        }
    end
    
    if wandRange > 1 then
        ev.entity.weaponPattern = { pattern = {
            multiHit = false,
            passWalls = false,
            swipe = (wandRange == 2 and "spear") or nil,
            multiSwipe = (wandRange > 2 and "trail") or nil,
            repeatTiles = (wandRange > 2 and wandRange) or nil,
            tiles = {
                {
                    offset = { 1, 0 },
                    swipe = (wandRange == 2 and "dagger") or nil
                }, 
                {
                    offset = { 2, 0 }
                }
            }
        }}
    end
end)

Event.levelLoad.add("applyCooldownBetweenLevels", { order = "spawnPlayers", sequence = 1e14 }, function(ev)
    if not cooldownBetweenLevels then return end
    
    for _, player in ipairs(Entities.getEntitiesByType(Constants.characterName)) do
        for _, item in ipairs(Inventory.getItems(player)) do
            if item.spellCooldownKills then
                item.spellCooldownKills.remainingKills = 0
            end
        end
    end
end)

Event.spellItemActivate.add("setMaxCooldown", { order = "killCooldown", sequence = 1e14, filter = { "spellCooldownKills" } }, function(ev)
    if not Util.checkStructure(ev, {
        caster = {
            name = Constants.characterName
        },
        entity = {
            spellCooldownKills = { }
        }
    }) then return end
    
    ev.entity.spellCooldownKills.remainingKills = math.ceil(ev.entity.spellCooldownKills.remainingKills * cooldownMaxPercent)
end)
