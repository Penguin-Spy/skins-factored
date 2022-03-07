# !skins
> Pronounced "`skins factored`", written as all lowercase

This is a Factorio library mod that makes it easy for other mods to add custom characters (skins), with a character picker.  
This mod takes a different approach than other skin-changer mods: instead of trying to extract the skins from multiple installed skin mods, it acts as a library for mods to include, meaning a player can install just one skin mod, or any number of them, and they'll all work as expected (if they use this library).

This library was written to be compatible with almost all mods that edit the default character prototype. It is explicitly compatible with Jetpacks & Space Exploration.

# Usage
This information is only for developers wanting to use this library! (add a link to where players should find mods that use this mod)

Adding support for this mod is simple, and can be done without losing support for other character-selecting mods.  
First, add the following line to your `settings.lua`:
```lua
table.insert(skins_factored.registered_skin_ids, "your-skin-id-here")
```
Then, add the following lines to your `data.lua`:
```lua
skins_factored.registered_skins["your-skin-id-here"] = {
  icon       = "path/to/image.png", -- shown on the inventory button and in the gui, REQUIRED
  reflection = "path/to/image.png", -- reflection for water, OPTIONAL, will default to the default player's texture
  animations = CharacterArmorAnimation, -- CharacterArmorAnimation, the character prototype's animations table, REQUIRED
            -- ignores the `armors` table, define the animations in the same order as the default character (3 teirs: armorless/light armor, heavy/modular armor, power armor)
            -- if only one tier is provided, it is used for all armor. if more than 3 are provided, the extras are only used if the default character has had more teirs added to it (by other mods)

  corpse_animation = AnimationVariations -- AnimationVariations, the character-corpse prototype's pictures table, REQUIRED
}
```

Factorio wiki documentation for types:  
- [AnimationVariations](https://wiki.factorio.com/Types/AnimationVariations)
- [CharacterArmorAnimation](https://wiki.factorio.com/Types/CharacterArmorAnimation)

Finally, create a [localization file](https://wiki.factorio.com/Tutorial:Localisation) with the following contents: 
```ini
[entity-name]
character-SKIN_ID=Name for the skins in-game character
character-SKIN_ID-corpse=Name for the skins in-game corpse

[entity-description]
character-SKIN_ID=Description for the skins in-game character
character-SKIN_ID-corpse=Description for the skins in-game corpse

[string-mod-setting]
skins-factored-selected-skin-SKIN_ID=Name for the skins setting dropdown item

[string-mod-setting-description]
skins-factored-selected-skin-SKIN_ID=Description for the skins setting dropdown item
```

# Legal stuff
Copyright (C) 2022  Penguin_Spy  
Licensed under GNU General Public License v3.0 or later. See `LICENSE` for the full text.  
