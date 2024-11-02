--[[ common.lua © Penguin_Spy 2023-2024
  Common utilities for dealing with skin ids.

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

-- Common utilities used in various files
local Common = {
  -- All skins a player can switch to, including the engineer
  available_skins = available_skins,
  get_available_skins_message = function() return concat_keys(available_skins, "\n  ") end,
  -- All skins created by this mod (excludes the engineer)
  added_skins = added_skins,
  -- false if operating normally, otherwise the name of the mod causing compatibility mode (any string is truthy in Lua)
  compatibility_mode = compatibility_mode,
  compatibility_message = compatibility_message
}

-- The end user sees "engineer", but internally it is called just "character", not "character-engineer"
function Common.skin_to_prototype(skin)
  return (skin == "engineer" and "character") or ("character-" .. skin)
end

function Common.prototype_to_skin(prototype)
  return (prototype == "character" and "engineer")  -- vanilla character name
      or string.sub(prototype, 11)                  -- cut off "character-" prefix
end

return Common
