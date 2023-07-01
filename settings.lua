--[[ settings.lua © Penguin_Spy 2023
  Provides the function for mods to register their skin as an available setting
]]

-- global
---@diagnostic disable-next-line: lowercase-global
skins_factored = {
  schema_version = 2,
}

-- do not touch!!
---@diagnostic disable-next-line: lowercase-global
skins_factored_INTERNAL = {
  registered_skin_ids = {}
}

function skins_factored.register_skin_id(skin_id, options)
  log("Registering skin: " .. skin_id .. " with options: " .. serpent.block(options))
  table.insert(skins_factored_INTERNAL.registered_skin_ids, skin_id)
  
  -- todo: skin options?
  
  -- todo: duplicate skin id protection:
  --  error("Skin ID " .. skin_id .. " has already been registered!")
end