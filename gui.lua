--[[ gui.lua © Penguin_Spy 2022
  Returns a table containing functions used to create and interact with the skin picker GUI
]]
local mod_gui = require 'mod-gui'

local GUI = {}


local item_sprites = {"inserter", "transport-belt", "stone-furnace", "assembling-machine-3", "logistic-chest-storage", "sulfur", "utility-science-pack", "laser-turret"}


local function build_sprite_buttons(player)
    local player_global = global.players[player.index]

    local button_table = player.gui.screen["skins_factored_selector_window"].content_frame.button_frame.button_table
    button_table.clear()

    local number_of_buttons = player_global.button_count
    for i = 1, number_of_buttons do
        local sprite_name = item_sprites[i]
        local button_style = (sprite_name == player_global.selected_item) and "yellow_slot_button" or "recipe_slot_button"
        button_table.add{type="sprite-button", sprite=("item/" .. sprite_name), tags={action="ugg_select_button", item_name=sprite_name}, style=button_style}
    end
end

local function create_window(player)    -- creates independent gui window containing the picker frame

  -- init these things
  global.players = global.players or {}
  global.players[player.index] = global.players[player.index] or { controls_active = true, button_count = 0, selected_item = nil }

  -- create GUI
  local screen_element = player.gui.screen
  local main = screen_element.add{type="frame", name="skins_factored_selector_window", direction = "vertical"}
  main.style.size = {385, 165}
  main.auto_center = true

  local titlebar = main.add{type="flow", name="titlebar"}
  titlebar.drag_target = main

  local title = titlebar.add{type="label", name="title", caption={"skins-factored.title_skins-factored"}, style="frame_title", ignored_by_interaction = true}
  --title.style.horizontally_stretchable = true
  local drag = titlebar.add{type = "empty-widget", style = "flib_titlebar_drag_handle", ignored_by_interaction = true}
  --drag.style.horizontally_stretchable = "on"

  local close = titlebar.add{type="sprite-button", style="frame_action_button",
    sprite = "utility/close_white", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black",
    tags = {action = "toggle", mod = "skins-factored"}
  }

  -- gui.close-instruction

  local content_frame = main.add{type="frame", name="content_frame", direction="vertical", style="ugg_content_frame"}
  local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="horizontal", style="ugg_controls_flow"}

  controls_flow.add{type="button", name="ugg_controls_toggle", caption="Deactivate"}

  controls_flow.add{type="slider", name="ugg_controls_slider", value=0, minimum_value=0, maximum_value=#item_sprites, style="notched_slider"}
  controls_flow.add{type="textfield", name="ugg_controls_textfield", text="0", numeric=true, allow_decimal=false, allow_negative=false, style="ugg_controls_textfield"}

  local button_frame = content_frame.add{type="frame", name="button_frame", direction="horizontal", style="ugg_deep_frame"}
  button_frame.add{type="table", name="button_table", column_count=#item_sprites, style="filter_slot_table"}

  build_sprite_buttons(player)

  return main
end

-- DEBUG
GUI.show_window = show_window

local function toggle_window(player)
  local selector_window = player.gui.screen["skins_factored_selector_window"]

  if not selector_window then -- if the window doesn't exist, create it
    player.opened = create_window(player)

  else  -- otherwise, toggle its visiblity
    selector_window.visible = not selector_window.visible

    if selector_window.visible then
      player.opened = selector_window
    else
      player.opened = nil
    end
  end

end

function GUI.create_button(player)        -- creates top-left button to open the gui
  local buttons = mod_gui.get_button_flow(player)
  if not buttons["skins_factored_selector_open"] then
    buttons.add{
      type="sprite-button",
      name="skins_factored_selector_open",
      sprite ="entity/character",
      tooltip = {"skins-factored.skin_selector"},
      tags = {action = "toggle", mod = "skins-factored"}
    }
  end
end

function GUI.remove_button(player)        -- removes top-left button if it's present
  local buttons = mod_gui.get_button_flow(player)
  if buttons["skins_factored_selector_open"] then
    buttons["skins_factored_selector_open"].destroy()
  end
end

function GUI.create_picker_frame(player)  -- creates inner frame containing just the skin selector buttons

end

function GUI.on_clicked(event)            -- handles all button clicks (checks if they're relevant)
  local element = event.element
  if not element then return end

  if --[[util.string_starts_with(element.name, "skins_factored") or]] element.tags.mod == "skins-factored" then
    local player = game.players[event.player_index]

    if --[[element.name == "skins_factored_selector_open" or]] element.tags.action == "toggle" then
      toggle_window(player)
    end
  end
end

function GUI.on_closed(event)             -- handles closing the gui (checks if ours is open)
  local element = event.element
  if not element then return end

  if element.name == "skins_factored_selector_window" and element.visible then
    local player = game.players[event.player_index]

    toggle_window(player)
  end
end


return GUI


--[[
local item_sprites = {"inserter", "transport-belt", "stone-furnace", "assembling-machine-3", "logistic-chest-storage", "sulfur", "utility-science-pack", "laser-turret"}


local function build_sprite_buttons(player)
    local player_global = global.players[player.index]

    local button_table = player.gui.screen.ugg_main_frame.content_frame.button_frame.button_table
    button_table.clear()

    local number_of_buttons = player_global.button_count
    for i = 1, number_of_buttons do
        local sprite_name = item_sprites[i]
        local button_style = (sprite_name == player_global.selected_item) and "yellow_slot_button" or "recipe_slot_button"
        button_table.add{type="sprite-button", sprite=("item/" .. sprite_name), tags={action="ugg_select_button", item_name=sprite_name}, style=button_style}
    end
end

local function create_gui(player)

  -- init these things
  global.players = global.players or {}
  global.players[player.index] = global.players[player.index] or { controls_active = true, button_count = 0, selected_item = nil }

  -- create GUI
  local screen_element = player.gui.screen
  local main_frame = screen_element.add{type="frame", name="ugg_main_frame", caption={"skins-factored.title_skins-factored"}}
  main_frame.style.size = {385, 165}
  main_frame.auto_center = true

  local content_frame = main_frame.add{type="frame", name="content_frame", direction="vertical", style="ugg_content_frame"}
  local controls_flow = content_frame.add{type="flow", name="controls_flow", direction="horizontal", style="ugg_controls_flow"}

  controls_flow.add{type="button", name="ugg_controls_toggle", caption="Deactivate"}

  controls_flow.add{type="slider", name="ugg_controls_slider", value=0, minimum_value=0, maximum_value=#item_sprites, style="notched_slider"}
  controls_flow.add{type="textfield", name="ugg_controls_textfield", text="0", numeric=true, allow_decimal=false, allow_negative=false, style="ugg_controls_textfield"}

  local button_frame = content_frame.add{type="frame", name="button_frame", direction="horizontal", style="ugg_deep_frame"}
  button_frame.add{type="table", name="button_table", column_count=#item_sprites, style="filter_slot_table"}

  build_sprite_buttons(player)
end

commands.add_command("gui", "command-help.gui", function(command)
  local player = game.get_player(command.player_index)
  create_gui(player)
end)






script.on_event(defines.events.on_gui_click, function(event)
  if event.element.name == "ugg_controls_toggle" then
    local player_global = global.players[event.player_index]
    player_global.controls_active = not player_global.controls_active

    local control_toggle = event.element
    control_toggle.caption = (player_global.controls_active) and "deactivate" or "activate"

    local player = game.get_player(event.player_index)
    local controls_flow = player.gui.screen.ugg_main_frame.content_frame.controls_flow
    controls_flow.ugg_controls_slider.enabled = player_global.controls_active
    controls_flow.ugg_controls_textfield.enabled = player_global.controls_active

  elseif event.element.tags.action == "ugg_select_button" then
    local player = game.get_player(event.player_index)
    local player_global = global.players[player.index]

    local clicked_item_name = event.element.tags.item_name
    player_global.selected_item = clicked_item_name

    build_sprite_buttons(player)
  end
end)

script.on_event(defines.events.on_gui_value_changed, function(event)
    if event.element.name == "ugg_controls_slider" then
        local player = game.get_player(event.player_index)
        local player_global = global.players[player.index]

        local new_button_count = event.element.slider_value
        player_global.button_count = new_button_count

        local controls_flow = player.gui.screen.ugg_main_frame.content_frame.controls_flow
        controls_flow.ugg_controls_textfield.text = tostring(new_button_count)

        build_sprite_buttons(player)
    end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
    if event.element.name == "ugg_controls_textfield" then
        local player = game.get_player(event.player_index)
        local player_global = global.players[player.index]

        local new_button_count = tonumber(event.element.text) or 0
        local capped_button_count = math.min(new_button_count, #item_sprites)
        player_global.button_count = capped_button_count

        local controls_flow = player.gui.screen.ugg_main_frame.content_frame.controls_flow
        controls_flow.ugg_controls_slider.slider_value = capped_button_count

        build_sprite_buttons(player)
    end
end)

]]