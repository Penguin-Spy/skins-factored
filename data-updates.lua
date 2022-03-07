--[[ data-updates.lua © Penguin_Spy 2022
  Use the registered skins to create prototypes for them
  During data-final-fixes mods may use these prototypes for their own purposes
  (such as `mods.factorio.com/mod/jetpack` duplicating them for the flying character prototypes)
]]

for skin_id, skin in pairs(skins_factored.registered_skins) do

  --[[ Create character prototype ]]
  log("Creating skin " .. skin_id)
  local character = table.deepcopy(data.raw["character"]["character"])
  character.name = "character-" .. skin_id  -- prototype id

  -- Localization
  -- (just use the default of entity-name."skin_id", maintains compatibility with Jetpack)
  -- character.localised_name = {"skin-name." .. skin_id}

  -- Inventory icon
  character.icon = skin.icon

  --[=[ Set animations ]=]
  -- Carefully copy just the animation sprites, leaving the armors (and anything else) untouched
  for teir_key in pairs(character.animations) do

    -- If we have an animation teir to match the default character's
    if skin.armor_animations[teir_key] then
      -- Copy the `armors` from the default character
      skin.armor_animation[teir_key].armors = character.animations[teir_key].armors
      -- And then set the prototype's animations to the skin's
      character.animations[teir_key] = skin.armor_animations[teir_key]
      log("  Set animations for teir " .. teir_key)
    else
      -- Copy the armors from this teir to the highest teir we do have,
      for _, armor in ipairs(character.animations[teir_key].armors) do
        table.insert(character.animations[#skin.armor_animations].armors, armor)
       end
      -- and then delete the default character's teir
      table.remove(character.animations[teir_key])
      log("  No animations for teir " .. teir_key .. ", removing it.")
    end
  end

  -- Water reflection texture (optional)
  if skin.water_reflection then
    character.water_reflection.pictures.filename = skin.water_reflection
  end

  --[[ Create character-corpse prototype ]]
  log("Creating skin " .. skin_id .. "'s corpse (rip)")
  local corpse = table.deepcopy(data.raw["character-corpse"]["character-corpse"])
  corpse.name = "character-" .. skin_id .. "-corpse"

  -- Set icon and animations
  corpse.icon = skin.icon
  corpse.pictures = skin.corpse_animation

  -- Set the character's corpse to their specific corpse
  character.character_corpse = corpse.name

  --[[ Actually add the prototypes ]]
  data:extend({
    character,
    corpse
  })
end