local CustomEntities = require "necro.game.data.CustomEntities"
local ItemSlot = require "necro.game.item.ItemSlot"

CustomEntities.extend({
    name = "SorcererCharacter_SpellHealMimic",
    template = CustomEntities.template.item("spell_heal"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellBombMimic",
    template = CustomEntities.template.item("spell_bomb"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellShieldMimic",
    template = CustomEntities.template.item("spell_shield"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellFreezeEnemiesMimic",
    template = CustomEntities.template.item("spell_freeze_enemies"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellTransmuteMimic",
    template = CustomEntities.template.item("spell_transmute"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellEarthMimic",
    template = CustomEntities.template.item("spell_earth"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellFireballMimic",
    template = CustomEntities.template.item("spell_fireball"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})

CustomEntities.extend({
    name = "SorcererCharacter_SpellPulseMimic",
    template = CustomEntities.template.item("spell_pulse"),
    components = {
        itemSlot = { name = ItemSlot.Type.ACTION }
    }
})
