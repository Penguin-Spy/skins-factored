--[[ informatron.lua © Penguin_Spy 2022
  Informatron page implementation. https://mods.factorio.com/mod/informatron
]]

-- return a function so we can yoink a reference to the GUI
return function(GUI)
  local Informatron = {}

  function Informatron.menu(data)         -- idk lol (oh it's the thing on the right [i meant left])
    return {} -- no subpages, just the main one
  end

  function Informatron.page_content(data) -- creates informatron pages
    -- main page
    if data.page_name == "skins-factored" then
      local element = data.element
      local available_skins_text = {"", {"skins-factored.available-skins"}}

      for _,skin in pairs(util.split(settings.global["skins-factored-all-skins"].value, ";")) do
        skin = (skin == "engineer" and "character") or ("character-" .. skin)
        table.insert(available_skins_text, {"skins-factored.available-skins-item", {"entity-name."..skin}})
      end

      element.add{type="label", name="text_1", caption={"skins-factored.page_about"}}
      element.add{type="label", name="text_2", caption=available_skins_text}
    end
  end

  return Informatron
end

--[[
-- Remote interface. replace "example" with your mod name
remote.add_interface("skins-factored", {
  informatron_menu = function(data)
    return {}
  end,
  informatron_page_content = function(data)
    return page_content(data.page_name, data.player_index, data.element)
  end
})

function page_content(page_name, player_index, element)
  -- main page
  if page_name == "skins-factored" then
    local available_skins_text = {"", {"skins-factored.available-skins"}}

    for _,skin in pairs(util.split(settings.global["skins-factored-all-skins"].value, ";")) do
      skin = (skin == "engineer" and "character") or ("character-" .. skin)
      table.insert(available_skins_text, {"skins-factored.available-skins-item", {"entity-name."..skin}})
    end

    element.add{type="label", name="text_1", caption={"skins-factored.page_about"}}
    element.add{type="label", name="text_2", caption=available_skins_text}
  end
end
]]