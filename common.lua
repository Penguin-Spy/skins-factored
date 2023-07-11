--[[ common.lua © Penguin_Spy 2023 
  Common utilities for dealing with skin ids across the data and control phases.
]]
local util = require 'util'
-- during the data stage the table is called mods
---@diagnostic disable-next-line: undefined-global
local active_mods = mods or script.active_mods

-- cannot be ran during the settings phase (which is fine, we don't need this then)
local available_skins = util.split(settings.startup["skins-factored-all-skins"].value, ";")

-- debug info for compatibility mode
---@diagnostic disable-next-line: undefined-field
local added_skins = table.deepcopy(available_skins)
util.remove_from_list(added_skins, "engineer")
local compatibility_mode = (active_mods["minime"] and "miniMAXIme") or (active_mods["RitnCharacters"] and "RitnCharacters") or false
local compatibility_message = {"skins-factored.compatibility-mode-instructions", compatibility_mode, table.concat(added_skins, ", ")}

-- Common utilities used in various files
local Common = {
  -- All skins a player can switch to, including the engineer
  available_skins = available_skins,
  -- All skins created by this mod (excludes the engineer)
  added_skins = added_skins,
  -- false if operating normally, otherwise the name of the mod causing compatibility mode (any string is truthy in Lua)
  compatibility_mode = compatibility_mode,
  compatibility_message = compatibility_message
}

function Common.is_skin_available(skin)
  for _, available_skin in ipairs(available_skins) do
    if skin == available_skin then
      return true
    end
  end
end

-- The end user sees "engineer", but internally it is called just "character", not "character-engineer"
function Common.skin_to_prototype(skin)
  return (skin == "engineer" and "character") or ("character-" .. skin)
end

function Common.prototype_to_skin(prototype)
  return (
    (prototype == "character"     -- vanilla character name
    or prototype == "engineer")   -- "compatibility" with Eradicator's Character Additions, will allow players to swap by going back to the engineer first
      and "engineer")
    or string.sub(prototype, 11)  -- cut off "character-" prefix
end

return Common