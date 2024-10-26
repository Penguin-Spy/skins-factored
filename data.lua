--[[ data.lua © Penguin_Spy 2023-2024
  Provides the function for mods to create their skin

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]
local Common = require "common"

--- Data for a character skin
---@class skins_factored_skin_data
---@field icon string
---@field armor_animations data.CharacterArmorAnimation[]
---@field water_reflection data.WaterReflectionDefinition?
---@field corpse_animation data.AnimationVariations?
---@field footprint_particle { pictures: data.AnimationVariations, left_footprint_frames?: double[], right_footprint_frames?: double[], left_footprint_offset?: data.Vector, right_footprint_offset?: data.Vector }?
---@field light data.LightDefinition?

-- !skins API
---@diagnostic disable-next-line: lowercase-global
skins_factored = {
  schema_version = 2,
  ---@private
  register_skin_id = function() error("register_skin_id() must be called in the settings stage!") end
}

-- do not touch!!
---@diagnostic disable-next-line: lowercase-global
skins_factored_INTERNAL = {
  ---@type table<string, skins_factored_skin_data>
  registered_skins = {}
}

-- Creates a character skin.
---```lua
---skins_factored.create_skin("your-skin-id-here", {
---  -- shown on the inventory button and in the gui, REQUIRED
---  icon = "__mod-id__/path/to/character_icon.png",
---
---  -- array of CharacterArmorAnimation, the character prototype's animations table, REQUIRED
---  -- if a mod adds armors that are not specified in the armors table for any tier provided here, they are added to the highest tier available
---  armor_animations = {...},
---
---  -- optional AnimationVariations, the character-corpse prototype's pictures table; if not specified the engineer's corpse will be used
---  corpse_animation = {...}
---
---  -- optional WaterReflectionDefinition, specifies the reflection of the character in water
---  water_reflection = {...},
---
---  -- optional footprint particle definition
---  footprint_particle = {
---    pictures = {...},                    -- AnimationVariations, required if defining a footprint particle
---    right_footprint_frames = { 10, 21 }, -- list of frames, optional
---    left_footprint_frames = { 5, 16 },   -- list of frames, optional
---    left_footprint_offset = { 0.1, 0 },  -- Vector, optional
---    right_footprint_offset = { -0.1, 0 } -- Vector, optional
---  },
---
---  -- optional LightDefinition, the light emitted by the character, including both the circular glow *and* the flashlight
---  light = {...}
---})
---```
---@param skin_id string                  The internal identifier for the skin, as previously registered with `skins_factored.register_skin_id()`
---@param data skins_factored_skin_data   Data for the character skin
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

data:extend{
  {
    type = "custom-input",
    name = "skins_factored_toggle_interface",
    key_sequence = "ALT + S",
    order = "a",
    consuming = "game-only"
  }  --[[@as data.CustomInputPrototype]],
  {
    type = "shortcut",
    name = "skins_factored_toggle_interface",
    associated_control_input = "skins_factored_toggle_interface",
    action = "lua",
    icon = "__core__/graphics/icons/entity/character.png",
    icon_size = 64,
    small_icon = "__core__/graphics/icons/entity/character.png",
    small_icon_size = 64
  }  --[[@as data.ShortcutPrototype]]
}

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
local skin_preview_size = { 128, 196 }

local skin_button_size = {
  12 + skin_preview_size[1] + 12,        -- left margin+padding, skin_preview, right margin+padding
  8 + skin_preview_size[2] + 8 + 24 + 8  -- top  margin+padding, skin_preview, padding, skin_name, bottom padding/margin
}

styles["skins_factored_skin_button"] = {
  type = "button_style",
  parent = "button",
  size = skin_button_size,
  horizontal_align = "center",
  vertical_align = "center",
  top_padding = 8,
  disabled_graphical_set = {  -- When the button is disabled, it's selected; render it as green.
    base = { position = { 68, 17 }, corner_size = 8 },
  }
}

styles["skins_factored_skin_label"] = {
  type = "label_style",
  parent = "label",
  width = skin_preview_size[1],            -- preview width
  top_padding = skin_preview_size[2] + 4,  -- preview height + 4 top_margin
  horizontal_align = "center",
  vertical_align = "center",
  font = "default-dialog-button",
  font_color = { 28, 28, 28 }
}

styles["skins_factored_skin_button_inner_frame"] = {
  type = "frame_style",
  default_graphical_set = {
    base = {
      position = { 200, 128 },
      corner_size = 8,
      tint = { 0, 0, 0, 1 },
      scale = 0.5
    },
  },
  size = skin_preview_size,
  padding = -4
}

styles["skins_factored_skin_button_camera"] = {
  type = "camera_style",
  parent = "camera",
  size = { skin_preview_size[1], skin_preview_size[2] + 96 }  -- offset height to center camera when focused on entity
}
