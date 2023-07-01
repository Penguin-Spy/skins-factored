--[[ common.lua © Penguin_Spy 2023 
  Common utilities for dealing with skin ids across the data and control phases.
]]
local util = require 'util'

-- cannot be ran during the settings phase (which is fine, we don't need this then)
local available_skins = util.split(settings.startup["skins-factored-all-skins"].value, ";")
local Common = {
  available_skins = available_skins
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
    or prototype == "engineer")   -- "compatability" with Eradicator's Character Additions, will allow players to swap by going back to the engineer first
      and "engineer")
    or string.sub(prototype, 11)  -- cut off "character-" prefix
end

return Common