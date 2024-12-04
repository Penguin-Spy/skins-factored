--[[ data-final-fixes.lua © Penguin_Spy 2024
  Mod compatibility that has to happen last

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]

-- Expanded inventory size by ko3dzi
if mods["expanded-inventory-size"] then
  local guns_inventory_size = settings.startup["slots-number"].value

  for _, character in pairs(skins_factored_INTERNAL.created_characters) do
    character.guns_inventory_size = guns_inventory_size
  end
end
