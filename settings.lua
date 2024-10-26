--[[ settings.lua © Penguin_Spy 2023-2024
  Provides the function for mods to register their skin as an available setting

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]

-- !skins API
---@diagnostic disable-next-line: lowercase-global
skins_factored = {
  schema_version = 2,
  ---@private
  create_skin = function() error("create_skin() must be called in the data stage!") end
}

-- do not touch!!
---@diagnostic disable-next-line: lowercase-global
skins_factored_INTERNAL = {
  registered_skin_ids = {}
}

-- Registers a skin id for later use with `skins_factored.create_skin()`.
---@param skin_id string  The internal identifier for the skin, must be a valid prototype name
function skins_factored.register_skin_id(skin_id)
  -- duplicate skin id protection
  for _, registered_skin in pairs(skins_factored_INTERNAL.registered_skin_ids) do
    if registered_skin == skin_id then
      error("Skin id '" .. skin_id .. "' has already been registered!")
    end
  end

  -- skin id validation
  if not string.match(skin_id, [[^[%w_-]+$]]) then
    error("Skin id '" .. skin_id .. "' is not a valid name for a prototype!")
  elseif #skin_id > 171 then  -- make sure we have space to apply prefixes/suffixes for related prototypes
    error("Skin id '" .. skin_id .. "' is too long!")
  end

  log("Registering skin: " .. skin_id)
  table.insert(skins_factored_INTERNAL.registered_skin_ids, skin_id)
end
