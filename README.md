# !skins
> Pronounced "`skins factored`", written as "`!skins`" in all lowercase

This is a Factorio library mod that makes it easy for other mods to add custom characters (skins), with a character picker.  
This mod takes a different approach than other skin-changer mods: instead of trying to extract the skins from multiple installed skin mods, it acts as a library for mods to include, meaning a player can install just one skin mod, or any number of them, and they'll all work as expected (if they use this library).  
As of 1.3.0, this mod can also collect skins that do not use this API, but haven't overridden the default engineer character. If you are a developer of one of these mods, I still recommend you use this API as it's much simpler.

This library was written to be compatible with almost all mods that edit the default character prototype. It is explicitly compatible with [Jetpack](https://mods.factorio.com/mod/jetpack), [Space Exploration](https://mods.factorio.com/mod/space-exploration), [RPG System](https://mods.factorio.com/mod/RPGsystem), and [CharacterModHelper](https://mods.factorio.com/mod/CharacterModHelper). If you encounter any issues with compatibility with another mod, please [make an issue](https://github.com/Penguin-Spy/skins-factored/issues) or [a discussion post](https://mods.factorio.com/mod/skins-factored/discussion)!  
(Note that with the release of Factorio 2.0, mod updates may cause compatibility issues, make a discussion post if you encounter any!)


# Usage
This information is only for developers wanting to use this library! See the [mod portal](https://mods.factorio.com/mod/skins-factored) for information for players.

Adding support for this mod is simple, and can be done without losing support for other character-selecting mods.  
You can add multiple skins in one mod if you wish, just follow the steps for each skin you want to add, making sure to use a unique skin id for each.  
Before calling the functions in either phase, you may want to first check that `skins_factored.schema_version == 2` (the current version).

### `settings.lua`
First, add the following line to your `settings.lua`:
```lua
skins_factored.register_skin_id("your-skin-id-here")
```
Skin IDs must be a [valid prototype name](https://lua-api.factorio.com/latest/prototypes/PrototypeBase.html#name "PrototypeBase - Prototype Docs | Factorio"). This is what players will see when using the `/character` command. Localization files are used for all other skin changing interfaces.

### `data.lua`
Then, add the following lines to your `data.lua`:
```lua
skins_factored.create_skin("your-skin-id-here", {
  -- shown on the inventory button and in the gui, REQUIRED
  icon = "__mod-id__/path/to/character_icon.png",

  -- array of CharacterArmorAnimation, the character prototype's animations table, REQUIRED
  -- if a mod adds armors that are not specified in the armors table for any tier provided here, they are added to the highest tier available
  armor_animations = {...},

  -- optional AnimationVariations, the character-corpse prototype's pictures table; if not specified the engineer's corpse will be used
  corpse_animation = {...}

  -- optional WaterReflectionDefinition, specifies the reflection of the character in water
  water_reflection = {...},

  -- optional footprint particle definition
  footprint_particle = {
    pictures = {...},                    -- AnimationVariations, required if defining a footprint particle
    right_footprint_frames = { 10, 21 }, -- list of frames, optional
    left_footprint_frames = { 5, 16 },   -- list of frames, optional
    left_footprint_offset = { 0.1, 0 },  -- Vector, optional
    right_footprint_offset = { -0.1, 0 } -- Vector, optional
  },

  -- optional LightDefinition, the light emitted by the character, including both the circular glow *and* the flashlight
  light = {...}
})
```
The `animations` key is identical to what you would overwrite the default `character.animations` table with. The `corpse_animations` key is identical to what you would overwrite the default `character-corpse.pictures` table with.  
The number of animations and what armors they apply to must match between `animations` and `corpse_animations`. The `animations[n].armors` table is used to merge armor tiers in case your mod does not have all 3 armor tiers (or more if other mods add more tiers).  
For an example of what the `animations` key should look like, see [here](https://gist.github.com/Penguin-Spy/ab9c81511791bb90243d3e8bec2dcbd5).  
All optional properties will default to using the base game engineer's values if not specified.  

Factorio API documentation for types:  
- [AnimationVariations](https://lua-api.factorio.com/latest/types/AnimationVariations.html)
- [CharacterArmorAnimation](https://lua-api.factorio.com/latest/types/CharacterArmorAnimation.html)
- [RotatedAnimation](https://lua-api.factorio.com/latest/types/RotatedAnimation.html)
- [WaterReflectionDefinition](https://lua-api.factorio.com/latest/types/WaterReflectionDefinition.html)
- [LightDefinition](https://lua-api.factorio.com/latest/types/LightDefinition.html)

### Localization
Create a [localization file](https://wiki.factorio.com/Tutorial:Localisation) with the following contents: 
```ini
[entity-name]
character-SKIN_ID=Name for the skins in-game character, shown in the skin selector GUI
character-SKIN_ID-corpse=Name for the skins in-game corpse

[entity-description]
character-SKIN_ID=Description for the skins in-game character, shown in the skin selector GUI
character-SKIN_ID-corpse=Description for the skins in-game corpse

[string-mod-setting]
skins-factored-selected-skin-SKIN_ID=Name for the skins setting dropdown item (required, but should be the same as the entity-name)

[string-mod-setting-description]
skins-factored-selected-skin-SKIN_ID=Description for the skins setting dropdown item (required, but should be the same as the entity-description)
```
Make sure to replace the word `SKIN_ID` in the key with the same skin ID you passed to `skins_factored.register_skin_id()`.  
If your mod adds multiple skins, make sure to group all `[entity-name]`s, etc. under the same header.  

### Dependency
Finally, add the following to your mod's `info.json`:
```json
  "dependencies": [
    "skins-factored >= 1.3.0"
  ],
```
If you are creating a new skin mod and are using this library, you **must** use a hard dependency (the JSON above does that); **do not** try to overwrite the default `character` if this mod isn't found!! That will simply create the plentiful bundle of issues that this library was written to avoid.  
If you're migrating an existing mod I *highly* recommend you also make this a hard dependency and remove any code that generates the prototype yourself or interacts with other skin changing mods. !skins is designed to make this no longer necessary, improving compatibility with other mods that edit the base character, and providing automatic compatibility with miniMAXIme and RitnCharacters.

### Migration
If you are porting an existing mod to work with !skins, you must create a .json migration to convert the old character prototype name to the new one generated by !skins.
```json
{
  "entity": [
    ["your_old_prototype_name", "character-SKIN_ID"]
  ]
}
```
`your_old_prototype_name` is the name of the old prototype your mod defined, and `SKIN_ID` is replaced with the skin's id that you passed to `skins_factored.register_skin_id()`.  
For more information, see [the Factorio Lua API documentation for Migrations](https://lua-api.factorio.com/latest/auxiliary/migrations.html "Migrations - Auxiliary Docs | Factorio").  
One exception is that this is not needed if your mod *just* overwrote the default engineer's sprites and didn't add any prototypes.


# License
Copyright © Penguin_Spy 2023-2024  

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/.  
This Source Code Form is "Incompatible With Secondary Licenses", as
defined by the Mozilla Public License, v. 2.0.  
