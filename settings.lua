--[[ settings.lua © Penguin_Spy 2023-2024
  Provides the function for mods to register their skin as an available setting
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
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

-- Registers a skin id for later use with `skins_factored.create_skin()`
---@param skin_id string
function skins_factored.register_skin_id(skin_id)
  log("Registering skin: " .. skin_id)
  table.insert(skins_factored_INTERNAL.registered_skin_ids, skin_id)

  -- todo: skin options?

  -- todo: duplicate skin id protection:
  --  error("Skin ID " .. skin_id .. " has already been registered!")
end