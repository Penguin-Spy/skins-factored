--[[ control.lua © Penguin_Spy 2022
  Handles requests to swap which skin a player is using
]]
require('util')
require('swap-character')

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
  local current_prototype_name = (player.character.name == "character" and "engineer") or string.sub(player.character.name, 11)
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
  new_prototype_name = (skin == "engineer" and "character") or ("character-" .. skin)

  -- Finally attempt to swap, only updating the setting if it was successful.
  if swap_character(player.character, new_prototype_name) then
    return true
  else
    player.print{"command-output.character-unknown-error"}
    return false
  end
end

-- Add the character swap command
commands.add_command("character", "command-help.character", function(command)
  local player = game.get_player(command.player_index)

  --[[ Confirm the command is valid and safe to run ]]
  -- Check if the skin that the player requested exists
  local available_skins = util.split(settings.global["skins-factored-all-skins"].value, ";")
  local skin = is_skin_available(command.parameter, available_skins)
  if not skin then
    if command.parameter then
      player.print{"command-output.character-invalid-skin", command.parameter}
    end
    player.print{"command-output.character-available-skins", table.concat(available_skins, "\n  ")}
    return
  end

  log("Player " .. player.name .. " ran command, setting skin to " .. skin)

  if try_swap(player, skin) then
    player.print{"command-output.character-success", {"entity-name."..new_prototype_name}}

    -- Change setting, but mark that the command did it
    global.changed_setting = global.changed_setting or {}
    global.changed_setting[command.player_index] = true
    settings.get_player_settings(command.player_index)["skins-factored-selected-skin"] = {value = skin}
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
  local player = game.get_player(event.player_index)-- or {name = "unknown"}

  global.changed_setting = global.changed_setting or {}
  if not global.changed_setting[event.player_index] then
    local skin = settings.get_player_settings(event.player_index)["skins-factored-selected-skin"].value
    log("Player " .. player.name .. " changed setting, setting skin to " .. skin)

    if try_swap(player, skin) then
      player.print{"command-output.character-success", {"entity-name."..new_prototype_name}}
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
    log("se_respawn_event: " .. se_respawn_event)
    script.on_event(se_respawn_event, on_player_respawned)
  else
    script.on_event(defines.events.on_player_respawned, on_player_respawned)
  end
end)

-- on join world (for the 1st time)
script.on_event(defines.events.on_player_joined_game, function(event)
  log("on_player_joined_game")
  local player = game.get_player(event.player_index)
  local skin = settings.get_player_settings(player)["skins-factored-selected-skin"].value
  log("Player " .. player.name .. " joined, setting skin to " .. skin)

  try_swap(player, skin)
end)

-- on player created (idk what this event is)
--[[script.on_event(defines.events.on_player_created, function(event)
  log("on_player_created")
  log(serpent.block(event))
  log(game.get_player(event.player_index).name)
end) ]]

