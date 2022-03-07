--[[ data.lua © Penguin_Spy 2022
  Creates the table for mods to add their skin data through
]]

-- Temporary table for storing skins (discarded at the end of the data stage!)
--[[ FOLLOW THE BELOW FORMAT
registered_skins["skin-id"] = { -- the key is the identifier for the skin, used in programming context and localization, not shown to end user

  icon = "__base__/whatever/this/was/character.png",              -- shown on the inventory button and in the gui, REQUIRED

  water_reflection = "__base__/path/to/character-reflection.png", -- reflection thing for water, OPTIONAL, will default to the default player's texture

  armor_animation = {}, -- CharacterArmorAnimation, the character prototype's animations table, REQUIRED
                        -- ignores the `armors` table, define the animations in the same order as the default character (3 teirs: armorless/light armor, heavy/modular armor, power armor)
                        -- if only one tier is provided, it is used for all armor. if more than 3 are provided, the extras are only used if the default character has had more teirs added to it (by other mods)

  corpse_animation = {} -- AnimationVariations, the character-corpse prototype's pictures table, REQUIRED
}
]]
skins_factored = { registered_skins = {} }