--[[ data.lua © Penguin_Spy 2023-2024
  Creates the table for mods to add their skin data through

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]
local Common = require 'common'

--- Data for a character skin
---@class skins_factored_skin_data
---@field icon string
---@field water_reflection string?
---@field armor_animations data.CharacterArmorAnimation
---@field corpse_animation data.AnimationVariations?

-- global
---@diagnostic disable-next-line: lowercase-global
skins_factored = {
  schema_version = 2,
}

-- do not touch!!
---@diagnostic disable-next-line: lowercase-global
skins_factored_INTERNAL = {
  registered_skins = {}
}

-- Creates a character skin. 
---```lua
---skins_factored.create_skin("skin-id", {
---  -- shown on the inventory button and in the gui, REQUIRED
---  icon = "__base__/path/to/character.png",
--- 
---  -- reflection thing for water, OPTIONAL, will default to the default player's texture
---  water_reflection = "__base__/path/to/character-reflection.png", 
--- 
---  -- CharacterArmorAnimation, the character prototype's animations table, REQUIRED
---  -- ignores the `armors` table, you should define the animations in the same order as the default character
---  --   (3 teirs: armorless/light armor, heavy/modular armor, power armor/power armor mk2)
---  -- if only one tier is provided, it is used for all armor. if more than 3 are provided, the extras are only used if the default character has had more teirs added to it (by other mods)
---  armor_animations = {...}, 
--- 
---  -- AnimationVariations, the character-corpse prototype's pictures table, OPTIONAL, will default to using the vanilla engineer's corpse
---  corpse_animation = {...}
---})
---```
---@param skin_id string  the identifier for the skin, used in programming context and localization, not shown to the end user
---@param data skins_factored_skin_data   data for the character skin
function skins_factored.create_skin(skin_id, data)
  if not Common.is_skin_available(skin_id) then
    error("Unknown skin id: '" .. skin_id .. "', did you forget to register it in settings.lua?")
  end

  if not data.icon then
    error("Unable to create skin '" .. skin_id .. "' - 'icon' property is missing.")
  elseif not data.armor_animations then
    error("Unable to create skin '" .. skin_id .. "' - 'armor_animations' property is missing.")
  --[[else
    -- check for hr_version & warn if present
    local idle_anim = data.armor_animations[1].idle
    if idle_anim.layers then idle_anim = idle_anim.layers[1] end
    if idle_anim.hr_version then
      error("Unable to create skin '" .. skin_id .. "' - 'hr_version' is specified, but is not used in Factorio 2.0.")
    end]]
  end

  log("Registering skin creation: " .. skin_id .. " with data: " .. serpent.block(data, { maxlevel = 1 }))
  skins_factored_INTERNAL.registered_skins[skin_id] = data
end

-- [[ Internal data stuff ]]

data:extend({
  {
    type = "custom-input",
    name = "skins_factored_toggle_interface",
    key_sequence = "ALT + S",
    order = "a",
    consuming = "game-only"
  } --[[@as data.CustomInputPrototype]],
  {
    type = "shortcut",
    name = "skins_factored_toggle_interface",
    associated_control_input = "skins_factored_toggle_interface",
    action = "lua",
    icon = "__core__/graphics/icons/entity/character.png",
    icon_size = 64,
    small_icon = "__core__/graphics/icons/entity/character.png",
    small_icon_size = 64
  } --[[@as data.ShortcutPrototype]]
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
  top_padding = 8,
  disabled_graphical_set = {  -- When the button is disabled, it's selected; render it as green.
    base = {position = {68, 17}, corner_size = 8},
  }
}

styles["skins_factored_skin_label"] = {
  type = "label_style",
  parent = "label",
  width = skin_preview_size[1],           -- preview width
  top_padding = skin_preview_size[2] + 4, -- preview height + 4 top_margin
  horizontal_align = "center",
  vertical_align = "center",
  font = "default-dialog-button",
  font_color = {28, 28, 28}
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
  },
  size = skin_preview_size,
  padding = -4
}

styles["skins_factored_skin_button_camera"] = {
  type = "camera_style",
  parent = "camera",
  size = {skin_preview_size[1], skin_preview_size[2] + 96} -- offset height to center camera when focused on entity
}
