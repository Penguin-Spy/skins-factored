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

data:extend({
  {
    type = "custom-input",
    name = "skins_factored_toggle_interface",
    key_sequence = "ALT + S",
    order = "a",
    consuming = "game-only"
  },
  {
    type = "shortcut",
    name = "skins_factored_toggle_interface",
    associated_control_input = "skins_factored_toggle_interface",
    action = "lua",
    icon = {
      filename = "__core__/graphics/icons/entity/character.png",
      priority = "extra-high-no-scale",
      size = 64,
      mipmap_count = 4,
      flags = {"gui-icon"}
    }
  }
})

local styles = data.raw["gui-style"].default

styles["skins_factored_selector_window"] = {
  type = "frame_style",
  parent = "frame",
  minimal_height = 328,
  maximal_height = 676,
  width = 868
}

styles["skins_factored_titlebar_drag"] = {
  type = "empty_widget_style",
  parent = "draggable_space",
  left_margin = 4,
  right_margin = 4,
  height = 24,
  horizontally_stretchable = "on",
}
styles["skins_factored_skin_selector_label"] = {
  type = "label_style",
  parent = "label",
  single_line = false
}

styles["skins_factored_skins_table"] = {
  type = "table_style",
  parent = "table",
  horizontally_stretchable = "on",
  horizontally_squashable = "on",
  horizontal_spacing = 10,
  vertical_spacing = 16
}

-- 2x3 tiles, width*height
local skin_preview_size = {128, 196}

local skin_button_size = {
  12 + skin_preview_size[1] + 12,       -- left margin+padding, skin_preview, right margin+padding
  8 + skin_preview_size[2] + 8 + 24 + 8 -- top  margin+padding, skin_preview, padding, skin_name, bottom padding/margin
}

styles["skins_factored_skin_button"] = {
  type = "button_style",
  parent = "button",
  size = skin_button_size,
  horizontal_align = "center",
  vertical_align = "center",
  font_color = {1,1,1},
  top_padding = 8
}

styles["skins_factored_skin_button_selected"] = {
  type = "button_style",
  parent = "green_button",
  size = skin_button_size,
  horizontal_align = "center",
  vertical_align = "center",
  top_padding = 8,
  left_click_sound = {{ filename = "__core__/sound/gui-click.ogg", volume = 1 }}
}

styles["skins_factored_skin_label"] = {
  type = "label_style",
  parent = "label",
  width = skin_preview_size[1],           -- preview width
  top_padding = skin_preview_size[2] + 4, -- preview height + 4 top_margin
  horizontal_align = "center",
  vertical_align = "center",
  font = "heading-2"
}

styles["skins_factored_skin_button_inner_frame"] = {
  type = "frame_style",
  default_graphical_set = {
    base = {
      position = {200, 128},
      corner_size = 8,
      tint = {0, 0, 0, 1},
      scale = 0.5
    },
    shadow = default_shadow
  },
  size = skin_preview_size,
  padding = -4
}

styles["skins_factored_skin_button_camera"] = {
  type = "camera_style",
  parent = "camera",
  size = {skin_preview_size[1], skin_preview_size[2] + 96} -- offset height to center camera when focused on entity
}