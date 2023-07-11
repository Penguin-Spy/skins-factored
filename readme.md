# !skins
> Pronounced "`skins factored`", written as "`!skins`" in all lowercase

This is a Factorio library mod that makes it easy for other mods to add custom characters (skins), with a character picker.  
This mod takes a different approach than other skin-changer mods: instead of trying to extract the skins from multiple installed skin mods, it acts as a library for mods to include, meaning a player can install just one skin mod, or any number of them, and they'll all work as expected (if they use this library).

This library was written to be compatible with almost all mods that edit the default character prototype. It is explicitly compatible with [Jetpack](https://mods.factorio.com/mod/jetpack), [Space Exploration](https://mods.factorio.com/mod/space-exploration), and [RPG System](https://mods.factorio.com/mod/RPGsystem). If you encounter any issues with compatibility with another mod, please [make an issue](https://github.com/Penguin-Spy/skins-factored/issues)!


# Usage
This information is only for developers wanting to use this library! See the [mod portal](https://mods.factorio.com/mod/skins-factored) for information for players.

Adding support for this mod is simple, and can be done without losing support for other character-selecting mods.  
You can add multiple skins in one mod if you wish, just follow the steps for each skin you want to add, making sure to use a unique skin id for each.  
Before calling the functions in either phase, you should first check that `skins_factored.schema_version == 2` (the current version).

### `settings.lua`
First, add the following line to your `settings.lua`:
```lua
skins_factored.register_skin_id("your-skin-id-here")
```
Skin IDs must be a [valid prototype name](https://wiki.factorio.com/PrototypeBase#name "PrototypeBase - Factorio Wiki"). This is what players will see when using the `/character` command. Localization files are used for all other skin changing interfaces.

### `data.lua`
Then, add the following lines to your `data.lua`:
```lua
skins_factored.create_skin("your-skin-id-here", {
  icon       = "path/to/image.png", -- shown on the inventory button and in the gui, REQUIRED
  reflection = "path/to/image.png", -- reflection for water, OPTIONAL, will default to the default player's texture
  armor_animations = {},  -- table of CharacterArmorAnimation, REQUIRED
                          -- see below for what this should look like
  corpse_animations = {}  -- table of AnimationVariations, OPTIONAL
                          -- if not present the default character corpse entity is used (no custom corpse is generated)
})
```
The `animations` key is identical to what you would overwrite the default `character.animations` table with. The `corpse_animations` key is identical to what you would overwrite the default `character-corpse.pictures` table with.  
The number of animations and what armors they apply to must match between `animations` and `corpse_animations`. The `animations[n].armors` table is used to merge armor tiers in case your mod does not have all 3 armor tiers (or more if other mods add more tiers).  
For an example of what the `animations` key should look like, see [here](https://gist.github.com/Penguin-Spy/ab9c81511791bb90243d3e8bec2dcbd5).

Factorio wiki documentation for types:  
- [AnimationVariations](https://wiki.factorio.com/Types/AnimationVariations)
- [CharacterArmorAnimation](https://wiki.factorio.com/Types/CharacterArmorAnimation)
- [RotatedAnimation](https://wiki.factorio.com/Types/RotatedAnimation)

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

### Dependency
Finally, add the following to your mod's `info.json`:
```json
  "dependencies": [
    "skins-factored >= 1.0.0"
  ],
```
If you are creating a new skin mod and are using this library, you **must** use a hard dependency (the JSON above does that); **do not** try to overwrite the default `character` if this mod isn't found!! That will simply create the plentiful bundle of issues that this library was written to avoid.  
If you're migrating an existing mod I *highly* recommend you also make this a hard dependency and remove any code that generates the prototype yourself or interacts with other skin changing mods. !skins is designed to make this no longer necessary, improving compatibility with other mods that edit the base character, and providing automatic compatibility with miniMAXIme and RitnCharacters.

### Migration
If you are porting an existing mod to work with !skins, you must create a .json migration to convert the old character prototype name to the new one generated by !skins.
```json
{
  "entity":
  [
    ["your_old_prototype_name", "character-SKIN_ID"]
  ]
}
```
`your_old_prototype_name` is the name of the old prototype your mod generated, and `SKIN_ID` is replaced with the skin's id that you passed to `skins_factored.register_skin_id()`.  
For more information, see [the Factorio Lua API documentation for Migrations](https://lua-api.factorio.com/latest/Migrations.html "Migrations - Runtime Docs | Factorio").  
One exception is that this is not needed if your mod *just* overwrote the default engineer's sprites and didn't add any prototypes.


# Legal stuff
Copyright (C) 2023  Penguin_Spy  
Licensed under GNU General Public License v3.0 or later. See `LICENSE` for the full text.  
