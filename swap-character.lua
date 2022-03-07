--[[ swap-character.lua © Penguin_Spy 2022
  Provides a utility function to swap which prototype a character is using
]]

-- https://lua-api.factorio.com/latest/LuaInventory.html
function move_entity_inventory(from_entity, to_entity, inventory)
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

-- https://lua-api.factorio.com/latest/LuaControl.html
function swap_character(old_character, new_prototype_name)
  local player = old_character.player
  log("Turning " .. player.name .. "'s " .. old_character.name .. " into " .. new_prototype_name)

  if not game.entity_prototypes[new_prototype_name] then
    log("  FAILED! invalid prototype!")
    return false
  end

  --[[ Create new character ]]
  local new_character = old_character.surface.create_entity{
    name = new_prototype_name,
    position = old_character.position,
    force = old_character.force,
    direction = old_character.direction
  }

  -- [[ Properties ]]
  new_character.health = old_character.health

  -- [[ Robot things ]]
  -- Combat robots
  for _, robot in pairs(old_character.following_robots) do
    robot.combat_robot_owner = new_character
  end

  -- Save the table of robots in the character's personal network
  -- The new_character doesn't have a logistic_cell yet, so we have to wait for the next tick to add the bots to it
  if old_character.logistic_cell
   and old_character.logistic_cell.logistic_network
   and old_character.logistic_cell.logistic_network.robots then
    global.orphaned_bots = global.orphaned_bots or {} -- create table if it doesn't exist
    global.orphaned_bots[player.index] = old_character.logistic_cell.logistic_network.robots
  end

  -- Copy (hopefully) all logistics requests. A bit jank because indexes can point to blank spots, and we can't know how many filled slots there are.
  -- This loops until we run past 50 consecutive blank slots.
  local i, consecutive_blanks = 1, 0
  repeat
    local slot = old_character.get_personal_logistic_slot(i)
    if slot.name then
      new_character.set_personal_logistic_slot(i, slot)
    else
      consecutive_blanks = consecutive_blanks + 1
    end
    i = i + 1
  until consecutive_blanks > 50

  new_character.character_personal_logistic_requests_enabled = old_character.character_personal_logistic_requests_enabled
  new_character.allow_dispatching_robots = old_character.allow_dispatching_robots

  new_character.selected_gun_index = old_character.selected_gun_index




  -- [[ Inventory ]]
  local hand_location = player.hand_location
  local open_gui = old_character.opened
  old_character.cursor_stack.swap_stack(new_character.cursor_stack)

  -- Crafting queue
  -- Save crafting queue
  local old_crafting_queue = old_character.crafting_queue
  local new_crafting_queue = {}
  -- Cancel crafting on old_character (to return items)
  old_character.character_inventory_slots_bonus = old_character.character_inventory_slots_bonus + 999
  new_character.character_inventory_slots_bonus = new_character.character_inventory_slots_bonus + 999
  if old_crafting_queue then
    -- must go in reverse order because the table changes as we cancel craftings
    for i=old_character.crafting_queue_size, 1, -1 do
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
    for _, item in pairs(new_crafting_queue) do
      new_character.begin_crafting{ count=item.count, recipe=item.recipe }
    end
  end
  new_character.character_inventory_slots_bonus = new_character.character_inventory_slots_bonus - 999

  -- Attach the player to the new character
  -- Done at the end to avoid any jank caused by having different character properties for part of the script
  if player then
    local opened_self = player.opened_self  -- this gets reset when we set_controller
    player.set_controller{type=defines.controllers.character, character=new_character}
    if opened_self then player.opened = new_character end
  end
  if open_gui then
    new_character.opened = open_gui
  end
  player.hand_location = hand_location

  --[[ Destroy old character ]]
  old_character.destroy()

  return true
end