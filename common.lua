--[[ common.lua © Penguin_Spy 2023-2024
  Common utilities for dealing with skin ids.
  These values are safe to calculate in the main chunk & not store in storage because
  they're based entirely on active mods, startup settings and prototypes, all of which
  must already match for the CRC to pass.

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]
local util = require "util"

local function concat_keys(t, sep)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return table.concat(keys, sep)
end

---@diagnostic disable-next-line: param-type-mismatch
local available_skins = util.list_to_map(util.split(settings.startup["skins-factored-all-skins"].value, ";"))

-- info for compatibility mode
local added_skins = table.deepcopy(available_skins)
added_skins["engineer"] = nil
local compatibility_mode = (script.active_mods["minime"] and "miniMAXIme") or (script.active_mods["RitnCharacters"] and "RitnCharacters") or false
local compatibility_message = { "skins-factored.compatibility-mode-instructions", compatibility_mode, concat_keys(added_skins, ", ") }

-- enable support for "external" skins; the skin id is the prototype name prefixed with "external:"
local external_skins = {}
if not compatibility_mode then
  for prototype, data in pairs(prototypes.get_entity_filtered{{filter = "type", type = "character"}}) do
    -- by convention, most skin mods have the word "skin" somewhere in them
    -- we exclude any skins already registered through our API, as well as hidden characters
    if prototype:match("skin") and not available_skins[prototype:sub(11)] and not data.hidden then
      external_skins[prototype] = true
      available_skins["external:" .. prototype] = true
    end
  end
  log("Found external skins: " .. concat_keys(external_skins, ", "))
end

-- Common utilities used in various files
local Common = {
  -- All skins a player can switch to, including the engineer & skins not created by this mod
  available_skins = available_skins,
  get_available_skins_message = function() return concat_keys(available_skins, "\n  ") end,
  -- All skins created by this mod (excludes the engineer)
  added_skins = added_skins,
  -- All skins NOT created by this mod (also excludes the engineer)
  external_skins = external_skins,
  -- false if operating normally, otherwise the name of the mod causing compatibility mode (any string is truthy in Lua)
  compatibility_mode = compatibility_mode,
  compatibility_message = compatibility_message
}

-- The end user sees "engineer", but internally it is called just "character", not "character-engineer"
function Common.skin_to_prototype(skin)
  return (skin == "engineer" and "character") or (skin:sub(1, 9) == "external:" and skin:sub(10))  or ("character-" .. skin)
end

function Common.prototype_to_skin(prototype)
  return (prototype == "character" and "engineer")  -- vanilla character name
      or (external_skins[prototype] and "external:" .. prototype)
      or prototype:sub(11)                          -- cut off "character-" prefix
end

return Common
