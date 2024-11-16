--[[ preview-surface.lua © Penguin_Spy 2023-2024
  Manages the surface that holds the preview character entities.
  Each player has their own copy of each skin, arranged in a grid:
  Y is player_index * 4, X is (the skin's position in the mod load order) * 4
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]


local PreviewSurface = {}

function PreviewSurface.initalize()
  log("Initalizing PreviewSurface")
  local data = storage.preview_surface_data or { skin_previews = {} }

  local surface = game.get_surface("skins_factored_preview_surface")

  if not surface then
    log("Creating skins_factored_preview_surface")
    ---@diagnostic disable-next-line: missing-fields
    surface = game.create_surface("skins_factored_preview_surface", {
      default_enable_all_autoplace_controls = false,
      cliff_settings = { cliff_elevation_0 = 1024 } ---@diagnostic disable-line: missing-fields
    })
    surface.show_clouds = false
    surface.freeze_daytime = true
    surface.daytime = 0.95
    surface.generate_with_lab_tiles = true
    surface.request_to_generate_chunks({0,0}, 1) -- make sure the lab tile background exists
  end
  PreviewSurface.ensure_hidden()

  -- generate a mapping of skin ids to X position offsets. used to position preview entities. does not (need to) adjust for mod changes (?)
  data.skin_positions = data.skin_positions or {}
  data.next_skin_pos = data.next_skin_pos or 1

  for skin in pairs(Common.available_skins) do
    if not data.skin_positions[skin] then
      local n = data.next_skin_pos
      data.skin_positions[skin] = n
      data.next_skin_pos = n + 1
    end
  end

  log(serpent.line(data))

  data.surface = surface

  storage.preview_surface_data = data
end

function PreviewSurface.initalize_player(player)
  local data = storage.preview_surface_data

  data.skin_previews[player.index] = data.skin_previews[player.index] or {}
end

function PreviewSurface.remove_player(player_index)
  local data = storage.preview_surface_data
  if not data then -- handle an edge case when restarting the map (i think this was caused by RitnCharacters)
    log("Attempting to remove player before preview surface was initalized!")
    return
  end

  for _, skin_preview in pairs(data.skin_previews[player_index]) do
    if skin_preview.valid then
      skin_preview.destroy()
    end
  end
  data.skin_previews[player_index] = nil
end

function PreviewSurface.get_skin_preview(skin, player)
  local data = storage.preview_surface_data

  local skin_previews_data = data.skin_previews[player.index]
  local skin_preview = skin_previews_data[skin]

  if not (skin_preview and skin_preview.valid) then
    log("Creating skin preview of " .. skin .. " for " .. player.name .. " [" .. player.index .. "]")
    skin_preview = data.surface.create_entity{
      name = Common.skin_to_prototype(skin),
      position = {data.skin_positions[skin] * 4, player.index * 4},
      force = player.force,
      direction = defines.direction.south
    } ---@cast skin_preview -nil
    skin_previews_data[skin] = skin_preview
  end

  -- update preview entity properites
  skin_preview.color = player.color
  if player.character and player.character.valid then
    local from = player.character.get_inventory(defines.inventory.character_armor)  ---@cast from -nil
    local to = skin_preview.get_inventory(defines.inventory.character_armor)  ---@cast to -nil

    for i=1, math.min(#from, #to) do
      to[i].set_stack(from[i])
    end
  end

  return skin_preview
end

function PreviewSurface.ensure_hidden()
  if game.get_surface("skins_factored_preview_surface") then
    for _, force in pairs(game.forces) do
      force.set_surface_hidden("skins_factored_preview_surface", true)
    end
  end
end

-- reveals the area of the map that the characters are in
function PreviewSurface.chart()
  local surface = game.get_surface("skins_factored_preview_surface")
  if surface then
    for _, force in pairs(game.forces) do
      force.chart(surface, {{0,0}, {0,0}})
    end
  end
end

return PreviewSurface