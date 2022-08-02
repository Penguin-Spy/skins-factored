--[[ control.lua © Penguin_Spy 2022 ]]
local util = require 'util'
local swap_character = require 'swap-character'
local PreviewSurface = require 'preview_surface'
local GUI = require('gui')(PreviewSurface)

local remote_interface = {}

remote_interface.on_character_swapped = GUI.on_character_swapped

-- Register Informatron pages
--  this conditional require is safe because if one player has the mod, all must have it and so our checksum will still match.
if script.active_mods["informatron"] then
  local Informatron = require('informatron')(GUI)
  remote_interface.informatron_menu = Informatron.menu
  remote_interface.informatron_page_content = Informatron.page_content
end

remote.add_interface("skins-factored", remote_interface)

available_skins = util.split(settings.startup["skins-factored-all-skins"].value, ";")

-- [[ Local functions ]]

-- The end user sees "engineer", but internally it is called just "character", not "character-engineer"
function skin_to_prototype(skin)
  return (skin == "engineer" and "character") or ("character-" .. skin)
end
local function prototype_to_skin(prototype)
  return (
    (prototype == "character"     -- vanilla character name
    or prototype == "engineer")   -- "compatability" with Eradicator's Character Additions, will allow players to swap by going back to the engineer first
      and "engineer")
    or string.sub(prototype, 11)  -- cut off "character-" prefix
end

local function is_skin_available(skin)
  for _, available_skin in ipairs(available_skins) do
    if skin == available_skin then
      return available_skin
    end
  end
end

-- Update our tracking of which skin the player is currently using
local function update_active_skin(player, skin)
  global.active_skin[player.index] = skin

  -- Change setting, but mark that code did it (not the player)
  global.changed_setting[player.index] = true
  settings.get_player_settings(player.index)["skins-factored-selected-skin"] = {value = skin}
end

-- Safety checks used in multiple places
function try_swap(player, skin, ignore_already)
  local character = player.character or player.cutscene_character

  -- Check if the player has a character (can't swap if in god-controller or spectator mode)
  if not character then
    player.print{"command-output.character-no-character"}
    return false
  end

  -- Check if the player is already using the requested skin
  if (not ignore_already) and (skin == global.active_skin[player.index]) then
    player.print{"command-output.character-already-skin", {"entity-name."..skin_to_prototype(skin)}}
    return
  end

  -- Check if the player is currently using a registered skin's character.
  -- Prevents swapping while at jetpack height or otherwise controlling a character from a different mod.
  local current_prototype_name = prototype_to_skin(character.name)
  if not is_skin_available(current_prototype_name) then
    if string.sub(character.name, -8) == "-jetpack" then
      player.print{"command-output.character-using-jetpack"}
    else
      player.print{"command-output.character-not-using-available-skin"}
    end
    return false
  end

  --[[ Safe to swap ]]
  local new_prototype_name = skin_to_prototype(skin)

  -- Finally attempt to swap, only updating the setting if it was successful.
  if swap_character(character, new_prototype_name, player) then
    update_active_skin(player, skin)
    return new_prototype_name
  else
    player.print{"command-output.character-unknown-error"}
    return false
  end
end


-- [[ Scripting ]]

-- Add the character swap command
commands.add_command("character", "command-help.character", function(command)
  local player = game.get_player(command.player_index)

  -- Confirm the command is valid and safe to run
  if command.parameter then
    -- Check if the skin that the player requested exists
    local skin = is_skin_available(command.parameter)
    if not skin then
      player.print{"command-output.character-invalid-skin", command.parameter}
      return
    end

    log("Player " .. player.name .. " ran command, setting skin to " .. skin)

    local success = try_swap(player, skin)
    if success then
      player.print{"command-output.character-success", {"entity-name."..success}}
    end -- errors are printed by try_swap

  -- No parameter passed, list all skins
  else
    player.print{"command-output.character-available-skins", table.concat(available_skins, "\n  ")}
  end
end)

-- Add personal robots back to the player's network once it gets created
script.on_event(defines.events.on_tick, function()
  if global.orphaned_bots and #global.orphaned_bots > 0 then
    for player_index, robots in pairs(global.orphaned_bots) do
      local player = game.get_player(player_index)
      if player.character
       and player.character.logistic_cell
       and player.character.logistic_cell.logistic_network then
        for _, robot in pairs(global.orphaned_bots[player_index]) do
          robot.logistic_network = player.character.logistic_cell.logistic_network
        end
        table.remove(global.orphaned_bots, player_index)
      end
    end
  end
end)

-- If the player changed their setting & the command didn't, try to swap the player's character
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if not (event.setting == "skins-factored-selected-skin") then return end

  local player = game.get_player(event.player_index)
  local setting = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"]
  local skin = setting.value

  if not global.changed_setting[event.player_index] then
    log("Player " .. player.name .. " changed setting, setting skin to " .. skin)

    local success = try_swap(player, skin)
    if success then
      player.print{"command-output.character-success", {"entity-name."..success}}
    else
      -- Skin swap failed, we need to reset the player's setting to their current skin
      global.changed_setting[event.player_index] = true
      setting = {value = global.active_skin[event.player_index]}
    end

  else  -- the event was triggered by the command
    table.remove(global.changed_setting, event.player_index)
  end
end)

-- Pass events to GUI
script.on_event(defines.events.on_gui_click, GUI.on_clicked)
script.on_event(defines.events.on_gui_closed, GUI.on_closed)
-- keybind
script.on_event("skins_factored_toggle_interface", function(event)
    local player = game.get_player(event.player_index)
    GUI.toggle_window(player)
end)
-- shortcut bar button
script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "skins_factored_toggle_interface" then
    local player = game.get_player(event.player_index)
    GUI.toggle_window(player)
  end
end)


--[[ Swapping to chosen character again (these should not display any confirmation message) ]]

-- When the player respawns
local function swap_on_player_respawned(event)
  local player = game.get_player(event.player_index)
  local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value
  log("Player " .. player.name .. " respawned, setting skin to " .. skin)

  try_swap(player, skin, true)
end

-- When the starting cutscene ends (activates on all, logic only runs when ending the intro)
script.on_event(defines.events.on_cutscene_cancelled, function (event)
  local player = game.get_player(event.player_index)
  local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value

  -- If the player doesn't have a character at the end of the cutscene, and we have a stored character for them to use
  --  then we must be at the end of the intro crash site cutscene
  if not player.character then
    local character = global.cutscene_character[event.player_index]

    if character and character.valid then
      log("Crash site cutscene ended, setting "..player.name.."'s character to saved "..character.name)
      player.set_controller{type=defines.controllers.character, character=character}
      character.destructible = true -- the cutscene should reset this value at the end, but since we changed characters it's reference is outdated
      global.cutscene_character[event.player_index] = nil
    end
  end
end)

-- When a player joins a save for the first time
local function swap_on_player_created(player)
  local skin = settings.get_player_settings(player.index)["skins-factored-selected-skin"].value

  -- For when the crash site cutscene isn't active (mutiplayer join, debug map, mod disabled cutscene)
  local old_character = player.cutscene_character or player.character
  if not old_character then return end  -- abort if ran in a scenario without a character

  -- Don't swap if we're already the skin we want to be (usually engineer)
  local new_prototype_name = skin_to_prototype(skin)
  if new_prototype_name == old_character.name then return end

  log("Player " .. player.name .. " created, setting skin to " .. skin)
  local character = swap_character(old_character, new_prototype_name, player)

  if character then -- if swapping was a success
    -- if we're in the crash site cutscene, save the new character to use at the end of it
    if player.controller_type == defines.controllers.cutscene then
      global.cutscene_character[player.index] = character
    end

    -- Regardless of controller, update our tracking of which skin the player is currently using
    update_active_skin(player, skin)

  else  -- swapping failed, set skin to current character
    update_active_skin(player, prototype_to_skin(old_character.name))
  end

end


-- [[ Initalization ]]

-- Ensures players have GUI & PreviewSurface properly set up
local function initalize_player(player)
  log("Initalizing player "..player.name.."["..player.index.."]")

  PreviewSurface.initalize_player(player)

  -- if Informatron isn't present, add our own button for the GUI
  if not script.active_mods["informatron"] then
    GUI.create_button(player)
  else  -- if it is, remove our button (if it exists)
    GUI.remove_button(player)
  end

  -- If the player doesn't have an active skin, assume it's the engineer (this only happens when adding the mod to a preexisting save)
  --  if the player does have a chosen skin in the settings, it will be applied later (in swap_on_player_created)
  if not global.active_skin[player.index] then
    global.active_skin[player.index] = "engineer"
  end
end

-- Runs once on new save, as well as when configuration changes. ensures All The Things are set up, including all players
local function initalize()
  log("Initalizing global data")
  -- All are tables indexed by player_index
  global.active_skin = global.active_skin or {}               -- permanent list of what this player's current skin is. may be not present for a player if they haven't changed skins yet

  global.changed_setting = global.changed_setting or {}       -- temporary indicator for the on_runtime_mod_setting_changed handler that code changed the setting, not a player. prevents recursive setting update handling
  global.orphaned_bots = global.orphaned_bots or {}           -- temporary storage for bots that need to be attached to a player's personal logistics network once it becomes available
  global.cutscene_character = global.cutscene_character or {} -- temporary list for setting a player's character after the intro cutscene

  global.open_skins_table = global.open_skins_table or {}     -- temporary list for getting the element of the skins_table for the player's current open GUI

  PreviewSurface.initalize()

  for _, player in pairs(game.players) do
    initalize_player(player)
  end
end

-- Runs every time the save is loaded (including the first time). Can't edit the global table
local function loadalize()
  -- Space Exploration overrides players dying with its own respawn system
  if script.active_mods["space-exploration"] then
    script.on_event(remote.call("space-exploration", "get_on_player_respawned_event"), swap_on_player_respawned)
  else
    script.on_event(defines.events.on_player_respawned, swap_on_player_respawned)
  end
end

script.on_load(loadalize)  -- Runs every time the save is loaded (except for the first time)
script.on_init(function () -- Runs once on new save
  initalize()
  loadalize()
end)
script.on_configuration_changed(initalize) -- When loaded mods change, update GUI & PreviewSurface


-- Runs when a player joins a save for the first time, only runs once (or again if they were removed, see below)
script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)

  initalize_player(player)

  swap_on_player_created(player)
end)

-- Runs when a player is removed from a save. Only occurs in multiplayer, and is very uncommon. This code will probably never run outside of me testing it. Still important tho!
script.on_event(defines.events.on_player_removed, function(event)
  log("Removing player [" .. player_index .. "]")

  PreviewSurface.remove_player(event.player_index)

  -- Delete all of this players' data in the global tables
  for _, table in pairs(global) do
    if type(value) == "table" then
      table[event.player_index] = nil
    end
  end
end)