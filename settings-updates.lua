--[[ settings-updates.lua © Penguin_Spy 2022
  Creates the skin dropdown menu for players to choose their skin
]]

-- Mark the default engineer as an available skin
-- This does not affect prototype generation during the data stage, as this is a different table
table.insert(skins_factored.registered_skin_ids, 1, "engineer")

-- List all skins
log("Registered skins: " .. table.concat(skins_factored.registered_skin_ids, ", "))

-- Register all skin_ids as options for the dropdown
data:extend({
  { -- Actual setting for users to pick a skin
    type = "string-setting",
    name = "skins-factored-selected-skin",
    setting_type = "runtime-per-user",
    default_value = (#skins_factored.registered_skin_ids == 2 and skins_factored.registered_skin_ids[2]) or "engineer", -- Default to the only custom skin if there's just 1, or to the engineer if there's multiple
    allowed_values = skins_factored.registered_skin_ids
  },
  { -- Fake setting to smuggle the list of skins into the control stage
    type = "string-setting",
    name = "skins-factored-all-skins",
    setting_type = "runtime-global",
    hidden = true,
    default_value = table.concat(skins_factored.registered_skin_ids, ";")
  }
})