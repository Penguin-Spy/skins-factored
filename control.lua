--[[ control.lua © Penguin_Spy 2022
  Handles requests to swap which skin a player is using
]]
require('util')
require('swap-character')

--[[
  all three are tables indexed by player_index
  global.changed_setting = temporary indicator for the on_runtime_mod_setting_changed handler that code changed the setting, not a player
  global.orphaned_bots   = temporary storage for bots that need to be attached to a player's personal logistics network once it becomes available
  global.active_skin     = permanent list of what this player's current skin is. may be not present for a player if they haven't changed skins yet
--]]


function is_skin_available(skin, available_skins)
  for _, available_skin in ipairs(available_skins) do
    if skin == available_skin then
      return available_skin
    end
  end
end

-- Safety checks used in multiple places
function try_swap(player, skin)
  local available_skins = util.split(settings.global["skins-factored-all-skins"].value, ";")

  -- Check if the player has a character (can't swap if in god-controller or spectator mode)
  if not player.character then
    player.print{"command-output.character-no-character"}
    return false
  end

  -- Check if the player is currently using a registered skin's character.
  -- Prevents swapping while at jetpack height or otherwise controlling a character from a different mod.
  local current_prototype_name = (player.character.name == "character" and "engineer")
   or (player.character.name == "engineer" and "engineer")  -- "compatability" with Eradicator's Character Additions, will allow players to swap by going back to the engineer first
   or string.sub(player.character.name, 11)
  if not is_skin_available(current_prototype_name, available_skins) then
    if string.sub(player.character.name, -8) == "-jetpack" then
      player.print{"command-output.character-using-jetpack"}
    else
      player.print{"command-output.character-not-using-available-skin"}
    end
    return false
  end

  --[[ Safe to swap ]]
  -- The end user sees "engineer", but internally it is called just "character", not "character-engineer"
  local new_prototype_name = (skin == "engineer" and "character") or ("character-" .. skin)

  -- Finally attempt to swap, only updating the setting if it was successful.
  if swap_character(player.character, new_prototype_name) then
    -- Update our tracking of which skin the player is currently using
    global.active_skin = global.active_skin or {}
    global.active_skin[player.index] = skin

    -- Change setting, but mark that code did it (not the player)
    global.changed_setting = global.changed_setting or {}
    global.changed_setting[player.index] = true
    settings.get_player_settings(player.index)["skins-factored-selected-skin"] = {value = skin}
    return new_prototype_name
  else
    player.print{"command-output.character-unknown-error"}
    return false
  end
end

-- Add the character swap command
commands.add_command("character", "command-help.character", function(command)
  local player = game.get_player(command.player_index)
  local available_skins = util.split(settings.global["skins-factored-all-skins"].value, ";")

  -- Check if the player is already using the requested skin
  if command.parameter == global.active_skin[command.player_index] then
    player.print{"command-output.character-already-skin", {"entity-name.character-"..command.parameter}}
    return

  -- Confirm the command is valid and safe to run
  elseif command.parameter then
    -- Check if the skin that the player requested exists
    local skin = is_skin_available(command.parameter, available_skins)
    if not skin then
      player.print{"command-output.character-invalid-skin", command.parameter}
      return
    end

    log("Player " .. player.name .. " ran command, setting skin to " .. skin)

    local success = try_swap(player, skin)
    if success then
      player.print{"command-output.character-success", {"entity-name."..success}}
    end

  -- No parameter passed, list all skins
  else
    player.print{"command-output.character-available-skins", table.concat(available_skins, "\n  ")}
  end
end)

-- Add personal robots back to the player's network once it gets created
script.on_event(defines.events.on_tick, function()
  if global.orphaned_bots then
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
-- Can fail for all the reasons the command can, we can't reset the setting because we don't know
--   what it was before.
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  local player = game.get_player(event.player_index)
  local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value

  if skin == global.active_skin[event.player_index] then
    table.remove(global.changed_setting, event.player_index)
    return
  end

  global.changed_setting = global.changed_setting or {}
  if not global.changed_setting[event.player_index] then
    log("Player " .. player.name .. " changed setting, setting skin to " .. skin)

    local success = try_swap(player, skin)
    if success then
      player.print{"command-output.character-success", {"entity-name."..success}}
    else
      -- Skin swap failed, we need to reset the player's setting to their current skin (or the default skin)
      global.active_skin = global.active_skin or {}
      local previous_skin = global.active_skin[event.player_index] or settings.player["skins-factored-selected-skin"]

      global.changed_setting[event.player_index] = true
      settings.get_player_settings(event.player_index)["skins-factored-selected-skin"] = {value = previous_skin}
    end

  else  -- the event was triggered by the command
    table.remove(global.changed_setting, event.player_index)
  end
end)


--[[ Swap to chosen character again (these should not display any confirmation message) ]]

-- on respawn
function on_player_respawned(event)
  local player = game.get_player(event.player_index)
  local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value
  log("Player " .. player.name .. " respawned, setting skin to " .. skin)

  try_swap(player, skin)
end
script.on_load(function()
  -- Space Exploration overrides players dying with its own respawn system
  if script.active_mods["space-exploration"] then
    local se_respawn_event = remote.call("space-exploration", "get_on_player_respawned_event")
    script.on_event(se_respawn_event, on_player_respawned)
  else
    script.on_event(defines.events.on_player_respawned, on_player_respawned)
  end
end)

-- on join world (for the 1st time)
script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  local skin = settings.get_player_settings(player)["skins-factored-selected-skin"].value
  log("Player " .. player.name .. " joined, setting skin to " .. skin)

  try_swap(player, skin)
end)