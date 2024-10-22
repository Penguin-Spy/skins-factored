--[[ settings-updates.lua © Penguin_Spy 2023-2024
  Creates the skin dropdown menu for players to choose their skin
  
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]
local skin_ids = skins_factored_INTERNAL.registered_skin_ids

-- Mark the default engineer as an available skin
-- This does not affect prototype generation during the data stage, as this is a different table
table.insert(skin_ids, 1, "engineer")

-- List all skins
log("Registered skins: " .. table.concat(skin_ids, ", "))

local skin_ids_string = table.concat(skin_ids, ";")

-- Register all skin_ids as options for the dropdown
data:extend({
  { -- Actual setting for users to pick a skin
    type = "string-setting",
    name = "skins-factored-selected-skin",
    order = "a",
    setting_type = "runtime-per-user",
    default_value = (#skin_ids == 2 and skin_ids[2]) or "engineer", -- Default to the only custom skin if there's just 1, or to the engineer if there's multiple
    allowed_values = skin_ids
  },
  { -- Fake setting to smuggle the list of skins into the control stage
    type = "string-setting",
    name = "skins-factored-all-skins",
    setting_type = "startup",
    hidden = true,
    default_value = skin_ids_string, -- setting both default & allowed_values forces the setting to always be this value (even when it changes after it's been saved)
    allowed_values = { skin_ids_string }
  },
  { -- Should the skin selector GUI display the player's current character in the GUI or the preview character? Suggested to disable in multiplayer due to latency
    type = "bool-setting",
    name = "skins-factored-render-character",
    order = "b",
    setting_type = "runtime-per-user",
    default_value = true
  }
})