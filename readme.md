# !skins
> Pronounced "`skins factored`", written as "`!skins`" in all lowercase

This is a Factorio library mod that makes it easy for other mods to add custom characters (skins), with a character picker.  
This mod takes a different approach than other skin-changer mods: instead of trying to extract the skins from multiple installed skin mods, it acts as a library for mods to include, meaning a player can install just one skin mod, or any number of them, and they'll all work as expected (if they use this library).

This library was written to be compatible with almost all mods that edit the default character prototype. It is explicitly compatible with Jetpacks & Space Exploration.

# Usage
This information is only for developers wanting to use this library! See the [mod portal](https://mods.factorio.com/mod/skins-factored) for information for players.

Adding support for this mod is simple, and can be done without losing support for other character-selecting mods.  

### `settings.lua`
First, add the following line to your `settings.lua`:
```lua
table.insert(skins_factored.registered_skin_ids, "your-skin-id-here")
```
Skin IDs must be a [valid prototype name](https://wiki.factorio.com/PrototypeBase#name "PrototypeBase - Factorio Wiki"). This is what players will see when using the `/character` command. Localization files are used for all other skin changing interfaces.

### `data.lua`
Then, add the following lines to your `data.lua`:
```lua
skins_factored.registered_skins["your-skin-id-here"] = {
  icon       = "path/to/image.png", -- shown on the inventory button and in the gui, REQUIRED
  reflection = "path/to/image.png", -- reflection for water, OPTIONAL, will default to the default player's texture
  animations = {  -- table of CharacterArmorAnimation, REQUIRED
    {
      idle = { -- RotatedAnimation
        layers = {
          { -- an Animation
            filename = "path/to/image.png",
            etc...
          },
          {
            etc...
          }
        }
      },
      idle_with_gun = RotatedAnimation,
      running = RotatedAnimation,
      running_with_gun = RotatedAnimation,
      mining_with_tool = RotatedAnimation,
      armors = {"light-armor", "another-armor-id"}  -- Don't define this if you want these animations to be used for the player without armor.
    },
    {
      etc...
    }
  },
  corpse_animations = {} -- table of AnimationVariations, OPTIONAL
                         -- if not present the default character corpse entity is used (no custom corpse is generated)
}
```
The `animations` key is identical to what you would overwrite the default `character.animations` table with. The `corpse_animations` key is identical to what you would overwrite the default `character-corpse.pictures` table with.  
The number of animations and what armors they apply to must match between `animations` and `corpse_animations`.

Factorio wiki documentation for types:  
- [Animation](https://wiki.factorio.com/Types/Animation)
- [RotatedAnimation](https://wiki.factorio.com/Types/RotatedAnimation)
- [AnimationVariations](https://wiki.factorio.com/Types/AnimationVariations)
- [CharacterArmorAnimation](https://wiki.factorio.com/Types/CharacterArmorAnimation)


### Localization
Create a [localization file](https://wiki.factorio.com/Tutorial:Localisation) with the following contents: 
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

### Dependency
Finally, add the following to your mod's `info.json`:
```json
  "dependencies": [
    "skins-factored >= 0.1.3"
  ],
```
If you're migrating an existing mod and don't want to make it a hard dependency, prefix the string with `? `. This library is *technically* compatable with other character selector mods, but it's very jank; players have to choose the default character (usually the engineer) before changing to a !skins character.  
If you are creating a new skin mod and are using this library, *please* use a hard dependency, and **do not** try to overwrite the default `character` if this mod isn't found, that will simply create the plentiful bundle of issues that this library was written to avoid.

# Legal stuff
Copyright (C) 2022  Penguin_Spy  
Licensed under GNU General Public License v3.0 or later. See `LICENSE` for the full text.  
