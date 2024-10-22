--[[ data-updates.lua © Penguin_Spy 2023-2024
  Use the registered skins to create prototypes for them
  During data-final-fixes mods may use these prototypes for their own purposes
  (such as `mods.factorio.com/mod/jetpack` duplicating them for the flying character prototypes)

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  This Source Code Form is "Incompatible With Secondary Licenses", as
  defined by the Mozilla Public License, v. 2.0.
]]

local util = require "util"

local all_armors = {}
local orig_char = data.raw["character"]["character"]
for _,animation in ipairs(orig_char.animations) do
  if animation.armors then
    for _,armor in ipairs(animation.armors) do
      table.insert(all_armors, armor)
    end
  end
end

local function get_missing_armors(armors)
  local missing_armors = table.deepcopy(all_armors)
  for _,animation in ipairs(armors) do
    if animation.armors then
      for _,armor in ipairs(animation.armors) do
        util.remove_from_list(missing_armors, armor)
      end
    end
  end
  return missing_armors
end


for skin_id, skin in pairs(skins_factored_INTERNAL.registered_skins) do

  --[[ Create character prototype ]]
  log("Creating skin " .. skin_id)
  local character = table.deepcopy(data.raw["character"]["character"])
  character.name = "character-" .. skin_id  -- prototype id

  -- Inventory icon
  character.icon = skin.icon

  --[[ Set animations ]]
  local missing_armors = get_missing_armors(skin.armor_animations)

  if #missing_armors > 0 then
    log(skin_id .. " is missing armors: " .. table.concat(missing_armors, ", "))

    -- Attempt to merge the original character's animations's armors into this character's animations
    for tier, animation in ipairs(character.animations) do
      if animation.armors then
        if skin.armor_animations[tier] and skin.armor_animations[tier].armors then
          log("merging armors " .. table.concat(animation.armors, ", ") .. " into tier " .. tier)
          skin.armor_animations[tier].armors = util.merge {
            skin.armor_animations[tier].armors,
            animation.armors
          }
        end
      end
    end

    -- If that didn't clear up everything, this skin doesn't have enough armor tiers. This could be because either:
    --  1) this skin has less than 3 armor teirs or
    --  2) a mod adds more than 3 armor tiers, and this skin doesn't have those tiers
    -- either way, the solution is to just put it into the highest tier we do have
    missing_armors = get_missing_armors(skin.armor_animations)
    if #missing_armors > 0 then
      log(skin_id .. " is STILL missing armors :bruh: " .. table.concat(missing_armors, ", "))
      -- last resort, just slap it on the end
      for _, armor in ipairs(missing_armors) do
        table.insert(skin.armor_animations[#skin.armor_animations].armors, armor)
      end
    end
  end

  character.animations = skin.armor_animations

  -- Water reflection texture (optional)
  if skin.reflection then
    character.water_reflection.pictures.filename = skin.reflection
  end

  --[[ Create character-corpse prototype ]]
  if skin.corpse_animation then
    log("Creating skin " .. skin_id .. "'s corpse (rip)")
    local corpse = table.deepcopy(data.raw["character-corpse"]["character-corpse"])
    corpse.name = "character-" .. skin_id .. "-corpse"

    -- Inventory icon
    corpse.icon = skin.icon

    -- Convert corpse animation to pictures & generate the armor->tier mapping
    local corpse_armor_mapping = {}

    for tier, animation in ipairs(skin.armor_animations) do
      if animation.armors then
        for _,armor in ipairs(animation.armors) do
          corpse_armor_mapping[armor] = tier
        end
      end
    end

    -- Apply the generated picture & mappings
    corpse.pictures = skin.corpse_animation
    corpse.armor_picture_mapping = corpse_armor_mapping

    -- Set the character's corpse to their specific corpse
    character.character_corpse = corpse.name

    -- Add the corpse's prototype
    data:extend({
      corpse
    })
  end

  -- Add the character's prototype
  data:extend({
    character
  })
end