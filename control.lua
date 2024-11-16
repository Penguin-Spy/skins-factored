--[[ control.lua © Penguin_Spy 2023-2024

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]

local swap_character = require 'scripts.swap-character'
local PreviewSurface = require 'scripts.preview-surface'
local GUI = require('scripts.gui')(PreviewSurface)
Common = require 'common'

local remote_interface = {}

if not Common.compatibility_mode then
  remote_interface.on_character_swapped = GUI.on_character_swapped
end

-- Register Informatron pages
--  this conditional require is safe because if one player has the mod, all must have it and so our checksum will still match.
if script.active_mods["informatron"] then
  local Informatron = require('scripts.informatron')(GUI)
  remote_interface.informatron_menu = Informatron.menu
  remote_interface.informatron_page_content = Informatron.page_content
end

remote.add_interface("skins-factored", remote_interface)

if script.active_mods["gvv"] then require("__gvv__.gvv")() end

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


-- [[ Local functions ]]

-- Update our tracking of which skin the player is currently using
local function update_active_skin(player, skin)
  storage.active_skin[player.index] = skin

  -- Change setting, but mark that code did it (not the player)
  storage.changed_setting[player.index] = true

  -- If the skin isn't one of the ones added by !skins, it's either external or the engineer
  -- since external skins can't be valid values for the setting, just store them as the engineer :/
  if Common.added_skins[skin] then
    settings.get_player_settings(player.index)["skins-factored-selected-skin"] = {value = skin}
  else
    settings.get_player_settings(player.index)["skins-factored-selected-skin"] = {value = "engineer"}
  end
end

-- Safety checks used in multiple places
--- i'm too lazy to put this where it should go; it's global so that gui.lua can use it. whatever.
---@diagnostic disable-next-line: lowercase-global
function try_swap(player, skin, ignore_already)
  local character = player.character  -- can't also check player.cutscene_character; we can't reliably tell the cutscene to use the new character

  -- Check if the player has a character (can't swap if in god-controller or spectator mode)
  if not character then
    player.print{"command-output.character-no-character"}
    return false
  end

  -- Check if the player is already using the requested skin
  if (not ignore_already) and (skin == storage.active_skin[player.index]) then
    player.print{"command-output.character-already-skin", {"entity-name."..Common.skin_to_prototype(skin)}}
    return false
  end

  -- Check if the player is currently using a registered skin's character.
  -- Prevents swapping while at jetpack height or otherwise controlling a character from a different mod.
  local current_prototype_name = Common.prototype_to_skin(character.name)
  if not Common.available_skins[current_prototype_name] then
    if string.sub(character.name, -8) == "-jetpack" then
      player.print{"command-output.character-using-jetpack"}
    else
      player.print{"command-output.character-not-using-available-skin"}
    end
    return false
  end

  --[[ Safe to swap ]]
  local new_prototype_name = Common.skin_to_prototype(skin)

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
commands.add_command("character", {"command-help.character"}, function (command)
  local player = game.get_player(command.player_index) ---@cast player -nil

  if Common.compatibility_mode then
    player.print(Common.compatibility_message)
    return
  end

  -- Confirm the command is valid and safe to run
  if command.parameter then
    local skin = command.parameter
    -- Check if the skin that the player requested exists
    if not Common.available_skins[command.parameter] then
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
    player.print{"command-output.character-available-skins", Common.get_available_skins_message()}
  end
end)

-- Add personal robots back to the player's network once it gets created
local function on_tick()
  if storage.orphaned_bots and #storage.orphaned_bots > 0 then
    for player_index, robots in pairs(storage.orphaned_bots) do
      local player = game.get_player(player_index)
      if player and player.character
      and player.character.logistic_cell
      and player.character.logistic_cell.logistic_network then
        for _, robot in pairs(robots) do
          robot.logistic_network = player.character.logistic_cell.logistic_network
        end
        table.remove(storage.orphaned_bots, player_index)
      end
    end
  end
end

-- If the player changed their setting & the command didn't, try to swap the player's character
local function on_runtime_mod_setting_changed(event)
  if event.setting == "skins-factored-mod-gui-button" then
    if settings.get_player_settings(event.player_index)["skins-factored-mod-gui-button"].value then
      GUI.create_button(game.get_player(event.player_index))
    else
      GUI.remove_button(game.get_player(event.player_index))
    end
  elseif not (event.setting == "skins-factored-selected-skin") then
    return
  end

  if not (event.setting == "skins-factored-selected-skin") then return end

  local player = game.get_player(event.player_index)  ---@cast player -nil
  local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value

  if not storage.changed_setting[event.player_index] then
    log("Player " .. player.name .. " changed setting, setting skin to " .. skin)

    local success = try_swap(player, skin)
    if success then
      player.print{"command-output.character-success", {"entity-name."..success}}
    else
      -- Skin swap failed, we need to reset the player's setting to their current skin
      storage.changed_setting[event.player_index] = true

      -- If the skin isn't one of the ones added by !skins, it's either external or the engineer
      -- since external skins can't be valid values for the setting, just store them as the engineer :/
      local old_skin = storage.active_skin[event.player_index]
      if Common.added_skins[old_skin] then
        settings.get_player_settings(event.player_index)["skins-factored-selected-skin"] = {value = old_skin}
      else
        settings.get_player_settings(event.player_index)["skins-factored-selected-skin"] = {value = "engineer"}
      end
    end

  else  -- the event was triggered by the command
    table.remove(storage.changed_setting, event.player_index)
  end
end

local function on_force_created(event)
  PreviewSurface.ensure_hidden()
end

--[[ Swapping to chosen character again (these should not display any confirmation message) ]]

-- When the player respawns
local function swap_on_player_respawned(event)
  local player = game.get_player(event.player_index)  ---@cast player -nil
  local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value
  log("Player " .. player.name .. " respawned, setting skin to " .. skin)

  try_swap(player, skin, true)
end

-- When the starting cutscene ends (activates on all, logic only runs when ending the intro)
local function on_cutscene_cancelled(event)
  local player = game.get_player(event.player_index)  ---@cast player -nil

  -- If the player doesn't have a character at the end of the cutscene, and we have a stored character for them to use
  --  then we must be at the end of the intro crash site cutscene
  if not player.character then
    local character = storage.cutscene_character[event.player_index]

    if character and character.valid then
      log("Crash site cutscene ended, setting "..player.name.."'s character to saved "..character.name)
      player.set_controller{type=defines.controllers.character, character=character}
      character.destructible = true -- the cutscene should reset this value at the end, but since we changed characters it's reference is outdated
      storage.cutscene_character[event.player_index] = nil
    end
  end
end

-- When a player joins a save for the first time
local function swap_on_player_created(player)
  local skin = settings.get_player_settings(player.index)["skins-factored-selected-skin"].value

  -- For when the crash site cutscene isn't active (mutiplayer join, debug map, mod disabled cutscene)
  local old_character = player.cutscene_character or player.character
  if not old_character then return end  -- abort if ran in a scenario without a character

  -- Don't swap if we're already the skin we want to be (usually engineer)
  local new_prototype_name = Common.skin_to_prototype(skin)
  if new_prototype_name == old_character.name then return end

  log("Player " .. player.name .. " created, setting skin to " .. skin)
  local character = swap_character(old_character, new_prototype_name, player)

  if character then -- if swapping was a success
    -- if we're in the crash site cutscene, save the new character to use at the end of it
    if player.controller_type == defines.controllers.cutscene then
      storage.cutscene_character[player.index] = character
    end

    -- Regardless of controller, update our tracking of which skin the player is currently using
    update_active_skin(player, skin)
  end -- if swapping failed, leave the players active_skin as "engineer"; the character could be any prototype, not just one of our skins

end


-- [[ Initalization ]]

-- used to invoke remote calls to other mods once the game and all mods have fully initalized and loaded
--  does not run on every load, only loads that run initalize()!
local function runtime_initalize()
  -- unregister this event
  script.on_nth_tick(1, nil)
  log("Runtime initalizing")

  if Common.compatibility_mode then
    -- list of all character prototypes we've added
    local available_prototypes = {}
    for _, skin_id in ipairs(Common.added_skins) do
      table.insert(available_prototypes, Common.skin_to_prototype(skin_id))
    end

    -- miniMAXIme compat
    if script.active_mods["minime"] then
      log("minime compat: " .. serpent.line(available_prototypes))
      remote.call("minime", "register_characters", available_prototypes)
      log("called")

    -- RitnCharacters compat
    elseif script.active_mods["RitnCharacters"] then
      for _, prototype in ipairs(available_prototypes) do
        local name = {"entity-name." .. prototype}
        log("adding skin " .. prototype .. " to RitnCharacters: " .. serpent.line(name))
        remote.call("RitnCharacters", "remove_character", prototype) -- remove the auto-generated entry (it has an untranslated name)
        remote.call("RitnCharacters", "add_character", name, prototype)
      end

    -- disabled because scenario doesn't support characters
    else
      log("Skin switching disabled, no compat loaded.")
    end
  end
end

-- Ensures players have GUI & PreviewSurface properly set up
local function initalize_player(player)
  log("Initalizing player "..player.name.."["..player.index.."]")

  PreviewSurface.initalize_player(player)
  GUI.initalize_player(player)

  local show_mod_gui_button = settings.get_player_settings(player.index)["skins-factored-mod-gui-button"].value
  -- if Informatron isn't present, add our own button for the GUI
  if not script.active_mods["informatron"] and not Common.compatibility_mode and show_mod_gui_button then
    GUI.create_button(player)
  else  -- if it is, remove our button (if it exists)
    GUI.remove_button(player)
  end

  -- If the player doesn't have an active skin, assume it's the engineer (this only happens when adding the mod to a preexisting save)
  --  if the player does have a chosen skin in the settings, it will be applied later (in swap_on_player_created)
  if not storage.active_skin[player.index] then
    storage.active_skin[player.index] = "engineer"
  end

  -- If the player does have an active skin, but it's prototype no longer exists (mod adding it was removed),
  --  warn the player to load with the mod active & change skins to prevent losing inventory (by the time we can run code, the entity has already been deleted)
  local intended_prototype = Common.skin_to_prototype(storage.active_skin[player.index])
  if not prototypes.entity[intended_prototype] then
    player.print{"skins-factored.error-skin-removed", player.name, storage.active_skin[player.index]}
  end
end

-- Runs once on new save, as well as when configuration changes. ensures All The Things are set up, including all players
-- intentionally not local to allow calling from /c
function initalize()
  log("Initalizing global data")
  -- All are tables indexed by player_index
  storage.active_skin = storage.active_skin or {}               -- permanent list of what this player's current skin is. may be not present for a player if they haven't changed skins yet

  storage.changed_setting = storage.changed_setting or {}       -- temporary indicator for the on_runtime_mod_setting_changed handler that code changed the setting, not a player. prevents recursive setting update handling
  storage.orphaned_bots = storage.orphaned_bots or {}           -- temporary storage for bots that need to be attached to a player's personal logistics network once it becomes available
  storage.cutscene_character = storage.cutscene_character or {} -- temporary list for setting a player's character after the intro cutscene

  storage.open_skins_table = storage.open_skins_table or {}     -- temporary list for getting the element of the skins_table for the player's current open GUI

  PreviewSurface.initalize()

  for _, player in pairs(game.players) do
    initalize_player(player)
  end

  -- Initalize function that runs during runtime, once everything is done loading (on_init_final_fixes if you will)
  script.on_nth_tick(1, runtime_initalize)
end

-- Runs every time the save is loaded (including the first time). Can't edit the game state
local function loadalize()
  -- register event handlers for skin switching related stuff
  if not Common.compatibility_mode then
    -- Space Exploration overrides players dying with its own respawn system
    if script.active_mods["space-exploration"] then
      script.on_event(remote.call("space-exploration", "get_on_player_respawned_event"), swap_on_player_respawned)
    else
      script.on_event(defines.events.on_player_respawned, swap_on_player_respawned)
    end

    script.on_event(defines.events.on_tick, on_tick)
    script.on_event(defines.events.on_runtime_mod_setting_changed, on_runtime_mod_setting_changed)
    script.on_event(defines.events.on_cutscene_cancelled, on_cutscene_cancelled)
    script.on_event(defines.events.on_force_created, on_force_created)
    log("Added all event listeners")
  else
    log("Loading in compatibility mode; event listeners disabled")
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

  if not Common.compatibility_mode then
    swap_on_player_created(player)
  end
end)

-- Runs when a player is removed from a save. Only occurs in multiplayer, and is very uncommon. This code will probably never run outside of me testing it. Still important tho!
script.on_event(defines.events.on_player_removed, function(event)
  log("Removing player [" .. event.player_index .. "]")

  PreviewSurface.remove_player(event.player_index)

  -- Delete all of this players' data in the global tables
  for _, value in pairs(storage) do
    if type(value) == "table" then
      value[event.player_index] = nil
    end
  end
end)