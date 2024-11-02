--[[ gui.lua © Penguin_Spy 2023-2024
  Returns a table containing functions used to create and interact with the skin picker GUI

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]
local mod_gui = require "mod-gui"

local function tags(table)
  table.mod = script.mod_name
  return table
end

local selector_open_name = "skins_factored_selector_open"
local selector_window_name = "skins_factored_selector_window"


-- Creates the independent gui window containing the picker frame
---@param player LuaPlayer
local function create_window(player)
  local screen_element = player.gui.screen
  local main = screen_element.add{ type = "frame", style = "skins_factored_selector_window", name = selector_window_name, direction = "vertical" }
  main.auto_center = true

  local titlebar = main.add{ type = "flow", name = "titlebar" }
  titlebar.drag_target = main

  -- Titlebar
  titlebar.add{ type = "label", style = "frame_title", caption = { "skins-factored.title_skins-factored" }, ignored_by_interaction = true }
  titlebar.add{ type = "empty-widget", style = "skins_factored_titlebar_drag", ignored_by_interaction = true }
  titlebar.add{ type = "sprite-button", style = "frame_action_button", tooltip = { "gui.close-instruction" },
    sprite = "utility/close", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black",
    tags = tags{ action = "toggle_window" }
  }

  -- Content
  local body = main.add{ type = "frame", name = "body", style = "inside_shallow_frame", direction = "vertical" }
  local header = body.add{ type = "frame", style = "skins_factored_subheader_frame", direction = "vertical" }

  header.add{ type = "label", style = "skins_factored_skin_selector_label", caption = { "skins-factored.about" } }

  if not Common.compatibility_mode then  -- instructions & frame for skins table
    header.add{ type = "label", style = "skins_factored_skin_selector_label", caption = { "skins-factored.skin-selector-instructions" } }

    -- need "scroll-pane" to put picker frame in
    local picker_pane = body.add{ type = "scroll-pane", name = "picker_pane", style = "skins_factored_scroll_pane", vertical_scroll_policy = "always" }
    picker_pane.add{ type = "frame", style = "deep_frame_in_shallow_frame_for_description", direction = "vertical", name = "picker_frame" }
  else  -- just compat instructions
    body.add{ type = "label", style = "skins_factored_skin_selector_label", caption = Common.compatibility_message }
  end

  main.visible = false
  return main
end


return function(PreviewSurface)
  local GUI = {}

  -- Recreates the independent skin selector window
  function GUI.initalize_player(player)
    log("gui initalize for " .. player.name)

    -- destroy window if it exists
    local selector_window = player.gui.screen[selector_window_name]
    if selector_window then
      selector_window.destroy()
    end

    -- then create the window
    selector_window = create_window(player)
    if not Common.compatibility_mode then
      GUI.attach_skins_table(selector_window.body.picker_pane.picker_frame, player)
    end
  end

  -- Creates (if not present) the inner frame containing just the skin selector buttons
  function GUI.attach_skins_table(parent, player)
    if not parent.skins_table then
      local skins_table = parent.add{ type = "table", column_count = 5, style = "skins_factored_skins_table", name = "skins_table" }
      storage.open_skins_table[player.index] = skins_table

      for skin in pairs(Common.available_skins) do
        local skin_preview_entity = PreviewSurface.get_skin_preview(skin, player)

        local skin_button = skins_table.add{ type = "button", style = "skins_factored_skin_button", caption = { "entity-description." .. skin_preview_entity.name },
          tags = tags{ action = "try_swap", skin = skin }
        }

        local entity_frame = skin_button.add{ type = "frame", style = "skins_factored_skin_button_inner_frame", ignored_by_interaction = true, name = "entity_frame" }

        local entity_camera = entity_frame.add{ type = "camera", style = "skins_factored_skin_button_camera", name = "entity_camera",
          position = skin_preview_entity.position, surface_index = skin_preview_entity.surface.index, zoom = 2
        }
        entity_camera.entity = skin_preview_entity

        skin_button.add{ type = "label", style = "skins_factored_skin_label", caption = { "entity-name." .. skin_preview_entity.name }, ignored_by_interaction = true }
      end
    end
  end

  -- Ran every time the window is opened or the player changes skin via GUI (window is guaranteed to exist)
  function GUI.update_skins_table(skins_table, player)
    storage.open_skins_table[player.index] = skins_table

    for _, skin_button in pairs(skins_table.children) do
      local is_active_skin = skin_button.tags.skin == storage.active_skin[player.index]
      skin_button.enabled = not is_active_skin

      if is_active_skin and settings.get_player_settings(player)["skins-factored-render-character"].value then
        skin_button.entity_frame.entity_camera.entity = player.character
      else
        skin_button.entity_frame.entity_camera.entity = PreviewSurface.get_skin_preview(skin_button.tags.skin, player)
      end
    end
  end

  -- Show/Hide the independent skin selector window
  function GUI.set_window_visible(player, visible)
    local selector_window = player.gui.screen[selector_window_name]
    selector_window.visible = visible

    if visible then
      player.opened = selector_window
      if not Common.compatibility_mode then
        GUI.update_skins_table(selector_window.body.picker_pane.picker_frame.skins_table, player)
      end
    else
      player.opened = defines.gui_type.none
      storage.open_skins_table[player.index] = nil
    end
  end

  function GUI.toggle_window(player)
    GUI.set_window_visible(player, not player.gui.screen[selector_window_name].visible)
  end

  -- Creates top-left mod-gui button to open the gui
  function GUI.create_button(player)
    local buttons = mod_gui.get_button_flow(player)
    if not buttons[selector_open_name] then
      buttons.add{
        type = "sprite-button",
        name = selector_open_name,
        sprite = "entity/character",
        tooltip = { "skins-factored.skin-selector" },
        tags = tags{ action = "toggle_window" }
      }
    end
  end

  -- Removes top-left mod-gui button if it's present
  function GUI.remove_button(player)
    local buttons = mod_gui.get_button_flow(player)
    if buttons[selector_open_name] then
      buttons[selector_open_name].destroy()
    end
  end

  -- Handles all button clicks (checks if they're relevant)
  ---@param event EventData.on_gui_click
  function GUI.on_clicked(event)
    local element = event.element
    if not (element and element.valid) then return end

    if element.tags.mod == script.mod_name then
      local player = game.players[event.player_index]

      if element.tags.action == "toggle_window" then
        GUI.toggle_window(player)
      elseif element.tags.action == "try_swap" then
        local success = try_swap(player, element.tags.skin)
        -- only refresh the window if it's necessary and still valid (and thus is the standalone skin selector)
        if success and element and element.valid and element.parent and element.parent.valid then
          GUI.set_window_visible(player, true)
          GUI.update_skins_table(element.parent, player)  -- the skins_table is the parent of the skin_button that was clicked
        end
      end
    end
  end

  -- Handles closing the gui (checks if ours is open)
  function GUI.on_closed(event)
    local element = event.element
    if not element then return end

    if element.name == selector_window_name and element.visible then
      local player = game.players[event.player_index]
      GUI.set_window_visible(player, false)
    end
  end

  -- Update the GUI when other mods swap the character (namely Jetpack)
  function GUI.on_character_swapped(event)
    local player = event.new_character.player

    if player and player.valid then
      -- reset our GUI as being opened, fixes Jetpack not saving that field
      local selector_window = player.gui.screen[selector_window_name]
      if selector_window and selector_window.visible then player.opened = selector_window end

      -- Update the currently open skins_table
      local skins_table = storage.open_skins_table[player.index]
      if skins_table and skins_table.valid then
        GUI.update_skins_table(skins_table, player)
      end
    end
  end

  return GUI
end
