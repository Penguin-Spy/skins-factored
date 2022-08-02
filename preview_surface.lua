local PreviewSurface = {}

function PreviewSurface.initalize()
  log("Initalizing PreviewSurface")
  local data = global.preview_surface_data or { skin_previews = {} }

  local surface = game.surfaces["skins_factored_preview_surface"]

  if not surface then
    log("Creating skins_factored_preview_surface")
    surface = game.create_surface("skins_factored_preview_surface", {
      default_enable_all_autoplace_controls = false,
      cliff_settings = { cliff_elevation_0 = 1024 }
    })
    surface.show_clouds = false
    surface.freeze_daytime = true
    surface.daytime = 0.95
    surface.generate_with_lab_tiles = true
    surface.request_to_generate_chunks({0,0}, 1) -- make sure the lab tile background exists
  end

  -- generate a mapping of skin ids to X position offsets. used to position preview entities. does not (need to) adjust for mod changes (?)
  data.skin_positions = data.skin_positions or {}
  data.next_skin_pos = data.next_skin_pos or 1

  for _, skin in pairs(available_skins) do
    if not data.skin_positions[skin] then
      local n = data.next_skin_pos
      data.skin_positions[skin] = n
      data.next_skin_pos = n + 1
    end
  end

  log(serpent.line(data))

  data.surface = surface

  global.preview_surface_data = data
end

function PreviewSurface.initalize_player(player)
  local data = global.preview_surface_data

  data.skin_previews[player.index] = data.skin_previews[player.index] or {}
end

function PreviewSurface.remove_player(player_index)
  local data = global.preview_surface_data

  for i, skin_preview in pairs(data.skin_previews[player_index]) do
    if skin_preview.valid then
      skin_preview.destroy()
    end
  end
  data.skin_previews[player_index] = nil
end

function PreviewSurface.get_skin_preview(skin, player)
  local data = global.preview_surface_data

  local skin_previews_data = data.skin_previews[player.index]
  local skin_preview = skin_previews_data[skin]

  if not (skin_preview and skin_preview.valid) then
    log("Creating skin preview of " .. skin .. " for " .. player.name .. " [" .. player.index .. "]")
    skin_preview = data.surface.create_entity{
      name = skin_to_prototype(skin),
      position = {data.skin_positions[skin] * 4, player.index * 4},
      force = player.force,
      direction = defines.direction.south
    }
    skin_previews_data[skin] = skin_preview
  end

  -- update preview entity properites
  skin_preview.color = player.color
  if player.character and player.character.valid then
    local from = player.character.get_inventory(defines.inventory.character_armor)
    local to = skin_preview.get_inventory(defines.inventory.character_armor)

    for i=1, math.min(#from, #to) do
      to[i].set_stack(from[i])
    end
  end

  return skin_preview
end

return PreviewSurface