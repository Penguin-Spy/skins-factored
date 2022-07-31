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
skins_factored = {
  schema_version = 1,
  registered_skins = {}
}


-- DEBUG STYLE TESTING
local styles = data.raw["gui-style"].default

styles["ugg_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on"
}

styles["ugg_controls_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontal_spacing = 16
}

styles["ugg_controls_textfield"] = {
    type = "textbox_style",
    width = 36
}

styles["ugg_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}