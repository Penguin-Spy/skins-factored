--[[ gui.lua © Penguin_Spy 2022
  Returns a table containing functions used to create and interact with the skin picker GUI
]]
local mod_gui = require 'mod-gui'
local Common = require 'Common'

local function tags(table)
  table.mod = script.mod_name
  return table
end

local selector_open_name = "skins_factored_selector_open"
local selector_window_name = "skins_factored_selector_window"


-- Creates the independent gui window containing the picker frame
local function create_window(player)
  local screen_element = player.gui.screen
  local main = screen_element.add{type="frame", style="skins_factored_selector_window", name=selector_window_name, direction = "vertical"}
  main.auto_center = true

  local titlebar = main.add{type="flow", name="titlebar"}
  titlebar.drag_target = main

  local title = titlebar.add{type="label", style="frame_title", caption={"skins-factored.title_skins-factored"}, ignored_by_interaction = true}
  local drag  = titlebar.add{type="empty-widget", style = "skins_factored_titlebar_drag", ignored_by_interaction = true}
  local close = titlebar.add{type="sprite-button", style = "frame_action_button", tooltip={"gui.close-instruction"},
    sprite = "utility/close_white", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black",
    tags = tags{action = "toggle_window"}
  }

  main.add{type="label", style="skins_factored_skin_selector_label", caption={"skins-factored.about"}}
  main.add{type="label", style="skins_factored_skin_selector_label", caption={"skins-factored.skin_selector_instructions"}}

  -- need "scroll-pane" to put picker frame in
  local picker_pane = main.add{type="scroll-pane", name="picker_pane", vertical_scroll_policy = "auto-and-reserve-space"}

  local picker_frame = picker_pane.add{type="frame", style="inside_shallow_frame_with_padding", direction="vertical", name="picker_frame"}

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
    GUI.attach_skins_table(selector_window.picker_pane.picker_frame, player)

  end

  -- Creates (if not present) the inner frame containing just the skin selector buttons
  function GUI.attach_skins_table(parent, player)

    if not parent.skins_table then
      local skins_table = parent.add{type="table", column_count=5, style="skins_factored_skins_table", name="skins_table"}
      global.open_skins_table[player.index] = skins_table

      for _, skin in pairs(Common.available_skins) do
        local skin_preview_entity = PreviewSurface.get_skin_preview(skin, player)

        local skin_button = skins_table.add{type="button", style="skins_factored_skin_button", caption={"entity-description."..skin_preview_entity.name},
          tags=tags{action="try_swap", skin=skin}
        }

        local entity_frame = skin_button.add{type="frame", style="skins_factored_skin_button_inner_frame", ignored_by_interaction = true, name="entity_frame"}

        local entity_camera = entity_frame.add{type="camera", style="skins_factored_skin_button_camera", name="entity_camera",
          position=skin_preview_entity.position, surface_index=skin_preview_entity.surface.index, zoom=2
        }
        entity_camera.entity = skin_preview_entity

        skin_button.add{type="label", style="skins_factored_skin_label", caption={"entity-name."..skin_preview_entity.name}, ignored_by_interaction = true}
      end
    end
  end

  -- Ran every time the window is opened or the player changes skin via GUI (window is guaranteed to exist)
  function GUI.update_skins_table(parent, player)
    local skins_table = parent.skins_table
    global.open_skins_table[player.index] = skins_table

    for _, skin_button in pairs(skins_table.children) do
      local is_active_skin = skin_button.tags.skin == global.active_skin[player.index]
      skin_button.enabled = not is_active_skin

      if is_active_skin and settings.get_player_settings(player)["skins-factored-render-character"].value then
        skin_button.entity_frame.entity_camera.entity = player.character
      else
        skin_button.entity_frame.entity_camera.entity = PreviewSurface.get_skin_preview(skin_button.tags.skin, player)
      end
    end
  end

  -- Show/Hide the independent skin selector window
  function GUI.toggle_window(player)
    local selector_window = player.gui.screen[selector_window_name]

    -- toggle window visiblity
    selector_window.visible = not selector_window.visible
    if selector_window.visible then
      player.opened = selector_window
      GUI.update_skins_table(selector_window.picker_pane.picker_frame, player)
    else
      player.opened = defines.gui_type.none
      global.open_skins_table[player.index] = nil
    end
  end

  -- Creates top-left mod-gui button to open the gui
  function GUI.create_button(player)
    local buttons = mod_gui.get_button_flow(player)
    if not buttons[selector_open_name] then
      buttons.add{
        type="sprite-button",
        name=selector_open_name,
        sprite ="entity/character",
        tooltip = {"skins-factored.skin_selector"},
        tags = tags{action = "toggle_window"}
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
  function GUI.on_clicked(event)
    local element = event.element
    if not element then return end

    if element.tags.mod == script.mod_name then
      local player = game.players[event.player_index]

      if element.tags.action == "toggle_window" then
        GUI.toggle_window(player)
      elseif element.tags.action == "try_swap" then
        try_swap(player, element.tags.skin)
        GUI.update_skins_table(element.parent.parent, player) -- march back up the element tree to get the correct parent frame
      end
    end
  end

  -- Handles closing the gui (checks if ours is open)
  function GUI.on_closed(event)
    local element = event.element
    if not element then return end

    if element.name == selector_window_name and element.visible then
      local player = game.players[event.player_index]

      GUI.toggle_window(player)
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
      local skins_table = global.open_skins_table[player.index]
      if skins_table and skins_table.valid then
        GUI.update_skins_table(skins_table.parent, player)
      end
    end

  end

  return GUI
end