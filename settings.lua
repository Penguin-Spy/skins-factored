--[[ settings.lua © Penguin_Spy 2022
  Creates the table for mods to register their skin as an available setting
]]

--[[ TEMPORARY TABLE discarded at the end of the settings stage
  Add your skin's skin_id to this table as a string to register it as an available skin for the settings menu!
  Do not add any other data, simply
    table.insert(skins_factored.registered_skin_ids, "your-skin-id-here")
  THIS MUST BE THE SAME skin_id YOU GIVE IN THE DATA STAGE!
]]

skins_factored = {
  schema_version = 1,
  registered_skin_ids = {}
}