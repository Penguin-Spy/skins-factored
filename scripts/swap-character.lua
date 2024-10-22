--[[ swap-character.lua © Penguin_Spy 2023-2024
  Provides a utility function to swap which prototype a character is using
  You may use this file in your own mods, provided that your mod is not replacing the functionality of Skins Factored.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]

-- https://lua-api.factorio.com/latest/LuaInventory.html
local function move_entity_inventory(from_entity, to_entity, inventory)
  local from = from_entity.get_inventory(inventory)
  local to = to_entity.get_inventory(inventory)

  if from.is_filtered() then
    for i=1, math.min(#from, #to) do
      to.set_filter(i, from.get_filter(i))
    end
  end

  for i=1, math.min(#from, #to) do
    to[i].set_stack(from[i])
  end
end

-- Swap the prototype of the character a player is using
---@param old_character LuaEntity   the player's current character entity
---@param new_prototype_name string the prototype name of the new character entity to be created
---@param player LuaPlayer
local function swap_character(old_character, new_prototype_name, player)

  -- (in)sanity checks
  if not old_character.valid then
    log("Character swap failed; old_character is invalid")
    return false
  end
  if not prototypes.entity[new_prototype_name] then
    log("Character swap failed; new_prototype_name is not a valid prototype")
    return false
  end

  log("Turning " .. (player and (player.name .. "'s ") or "somebody's ") .. old_character.name .. " into " .. new_prototype_name)

  --[[ Create new character ]]

  local position = old_character.position -- save current position
  ---@diagnostic disable-next-line: param-type-mismatch
  old_character.teleport(1) -- move the old char out of the way (relative)

  -- find a safe, nearby position to put the character if they would be on top of something after swapping
  position = old_character.surface.find_non_colliding_position(
    new_prototype_name, -- prototype to check collision of
    position, -- center
    5,   -- radius limit
    0.25 -- precision
  ) or position

  -- create new entity
  local new_character = old_character.surface.create_entity{
    name = new_prototype_name,
    position = position,
    force = old_character.force
  } ---@cast new_character -nil

  -- [[ Properties ]]
  new_character.health = old_character.health
  new_character.destructible = old_character.destructible
  new_character.direction = old_character.direction

  new_character.allow_dispatching_robots = old_character.allow_dispatching_robots
  new_character.selected_gun_index = old_character.selected_gun_index

  -- [[ Robot things ]]
  -- Combat robots
  for _, robot in pairs(old_character.following_robots) do
    robot.combat_robot_owner = new_character
  end

  -- Save the table of robots in the character's personal network
  -- The new_character doesn't have a logistic_cell yet, so we have to wait for the next tick to add the bots to it
  if player
   and old_character.logistic_cell
   and old_character.logistic_cell.logistic_network
   and old_character.logistic_cell.logistic_network.robots then
    storage.orphaned_bots = storage.orphaned_bots or {} -- create table if it doesn't exist
    storage.orphaned_bots[player.index] = old_character.logistic_cell.logistic_network.robots
  end

  -- Logistics network requests
  local old_logistics_requests = old_character.get_logistic_point(defines.logistic_member_index.character_requester)
  if old_logistics_requests then
    local new_logistics_requests = new_character.get_logistic_point(defines.logistic_member_index.character_requester)  ---@cast new_logistics_requests -nil
    new_logistics_requests.enabled = old_logistics_requests.enabled
    new_logistics_requests.trash_not_requested = old_logistics_requests.trash_not_requested
    new_logistics_requests.remove_section(1) -- remove default section

    for _, old_section in pairs(old_logistics_requests.sections) do
      local new_section = new_logistics_requests.add_section(old_section.group ~= "" and old_section.group or nil)---@cast new_section -nil
      if old_section.is_manual then
        -- copy filters of section
        for slot_index, filter in pairs(old_section.filters) do
          new_section.set_slot(slot_index, filter)
        end
      else
        -- copy request group
        new_section.group = old_section.group
      end
      -- copy settings of section
      new_section.active = old_section.active
      new_section.multiplier = old_section.multiplier
    end
  end

  -- [[ Inventory ]]
  -- cannot access character.opened during a cutscene: https://forums.factorio.com/viewtopic.php?f=7&t=116516
  --local open_gui = old_character.opened
  old_character.cursor_stack.swap_stack(new_character.cursor_stack)

  -- ghost cursor (crashes game: https://forums.factorio.com/viewtopic.php?f=7&t=116484)
  --if old_character.cursor_ghost then
  --  new_character.cursor_ghost = old_character.cursor_ghost
  --end

  -- Crafting queue

  -- If an item is already crafted but blocked by full inventory, we can't un-craft it and it will be put in the buffer inventory slots (& then dropped on the ground when those are removed).
  -- We reset the crafting progress and cancel the craft anyways to prevent the item from being saved & re-crafted again by the new character.
  if(old_character.crafting_queue_progress > 1) then
    old_character.crafting_queue_progress = 0
    old_character.cancel_crafting{index = old_character.crafting_queue[1].index, count = old_character.crafting_queue[1].count}
  end

  -- Save crafting queue
  local old_crafting_queue = old_character.crafting_queue
  local old_crafting_queue_progress = old_character.crafting_queue_progress
  local new_crafting_queue = {}

  -- grant temporary bonus slots to hold crafting materials while crafting is canceled & restarted (the crafting queue itself is read-only)
  new_character.character_inventory_slots_bonus = old_character.character_inventory_slots_bonus + 999
  old_character.character_inventory_slots_bonus = old_character.character_inventory_slots_bonus + 999
  -- Cancel crafting on old_character (to return items)
  if old_crafting_queue then
    -- must go in reverse order because the table changes as we cancel craftings
    for i = old_character.crafting_queue_size, 1, -1 do
      if old_character.crafting_queue and old_character.crafting_queue[i] then
        local item = old_crafting_queue[i]
        table.insert(new_crafting_queue, item)
        old_character.cancel_crafting{ index=item.index, count=item.count }
      end
    end
  end

  -- Move inventories before beginning crafting
  -- Be careful when swapping armor, make sure to paste armor before moving items, otherwise items get dumped/deleted
  move_entity_inventory(old_character, new_character, defines.inventory.character_armor)
  move_entity_inventory(old_character, new_character, defines.inventory.character_main)
  move_entity_inventory(old_character, new_character, defines.inventory.character_trash)
  move_entity_inventory(old_character, new_character, defines.inventory.character_guns)
  move_entity_inventory(old_character, new_character, defines.inventory.character_ammo)

  -- start crafting all items in the queue again
  if old_crafting_queue then
    -- must go in reverse order because the table may change as we start crafting
    for i = #new_crafting_queue, 1, -1 do
      if new_crafting_queue and new_crafting_queue[i] then
        local item = new_crafting_queue[i]
        new_character.begin_crafting{ count=item.count, recipe=item.recipe, silent=true }
      end
    end
    -- progress is > 1 if crafting is stopped due to full inventory, but writing > 1 causes error
    new_character.crafting_queue_progress = math.min(old_crafting_queue_progress, 1)
  end
  new_character.character_inventory_slots_bonus = new_character.character_inventory_slots_bonus - 999

  -- Put new player into vehicle
  if player.vehicle then
    if player.vehicle.get_driver() == old_character then
      player.vehicle.set_driver(new_character)
    elseif player.vehicle.get_passenger and player.vehicle.get_passenger() == old_character then
      player.vehicle.set_passenger(new_character)
    end
  end

  -- Attach the player to the new character
  -- Done at the end to avoid any jank caused by having different character properties for part of the script
  if old_character.player then
    -- these get reset when we set_controller
    local hand_location = player.hand_location
    local opened_self = player.opened_self

    -- if the player is in remote view on a different surface, we must first move them back to their character's surface
    player.set_controller{type=defines.controllers.remote, surface=new_character.surface}
    player.set_controller{type=defines.controllers.character, character=new_character}

    if opened_self then player.opened = new_character end
    if hand_location then player.hand_location = hand_location end
  end

  -- assigning the gui triggers the closing event, causing the skin selector to become visible=false if it's whats open
  --if open_gui then
  --  new_character.opened = open_gui
  --end

  -- Inform all mods that we swapped characters
  for interface_name, interface_functions in pairs(remote.interfaces) do
    if interface_functions["on_character_swapped"] then
      ---@diagnostic disable-next-line: missing-fields
      remote.call(interface_name, "on_character_swapped", {
        old_unit_number = old_character.unit_number,
        new_unit_number = new_character.unit_number,
        old_character = old_character,
        new_character = new_character
      })
    end
  end

  --[[ Destroy old character ]]
  old_character.destroy()

  return new_character
end

return swap_character