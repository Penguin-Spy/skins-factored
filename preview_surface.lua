local PreviewSurface = {}

local skin_previews = {}

function PreviewSurface.initalize()
  local surface = game.surfaces["skins_factored_preview_surface"]

  if not surface then
    surface = game.create_surface("skins_factored_preview_surface", {
      default_enable_all_autoplace_controls = false,
      cliff_settings = { cliff_elevation_0 = 1024 }
    })
    surface.show_clouds = false
    surface.freeze_daytime = true
    surface.daytime = 0.95
    surface.generate_with_lab_tiles = true
    surface.request_to_generate_chunks({0,0}, 1)
  end

  -- generate a mapping of skin ids to X position offsets. used to generate preview entities. does not (need to) adjust for mod changes?
  PreviewSurface.skin_positions = PreviewSurface.skin_positions or {}
  PreviewSurface.next_skin_pos = PreviewSurface.next_skin_pos or 1

  local available_skins = util.split(settings.global["skins-factored-all-skins"].value, ";")
  for _, skin in pairs(available_skins) do
    if not PreviewSurface.skin_positions[skin] then
      local n = PreviewSurface.next_skin_pos
      PreviewSurface.skin_positions[skin] = n
      PreviewSurface.next_skin_pos = n + 1
    end
  end

  PreviewSurface.surface = surface
end

function PreviewSurface.initalize_player(player)
  skin_previews[player.index] = skin_previews[player.index] or {}
end

function PreviewSurface.get_skin_preview(skin, player)
  local players_skin_previews = skin_previews[player.index]
  local skin_preview = players_skin_previews[skin]

  if not PreviewSurface.surface then PreviewSurface.initalize() end

  if not skin_preview then
    skin_preview = PreviewSurface.surface.create_entity{
      name = skin_to_prototype(skin),
      position = {PreviewSurface.skin_positions[skin] * 4, player.index * 4},
      force = player.force,
      player = player,
      direction = defines.direction.south
    }
    players_skin_previews[skin] = skin_preview
  end

  return skin_preview
end

return PreviewSurface