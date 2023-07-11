--[[ informatron.lua © Penguin_Spy 2023
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
      local player = game.players[data.player_index]
      local element = data.element

      element.add{type="label", name="about", caption={"skins-factored.about"}}

      if not Common.compatibility_mode then
        element.add{type="label", name="instructions", caption={"skins-factored.informatron-instructions"}}

        local picker_flow = element.add{type="flow"}
        picker_flow.style.horizontal_align = "center"
        picker_flow.style.horizontally_stretchable = true

        local picker_frame = picker_flow.add{type="frame", style="blueprint_header_frame", direction="vertical", name="picker_frame"}
        picker_frame.style.width = 824
        picker_frame.style.horizontally_stretchable = false

        GUI.attach_skins_table(picker_frame, player)
        GUI.update_skins_table(picker_frame, player)
      else
        element.add{type="label", name="instructions", caption=Common.compatibility_message}
      end
    end
  end

  return Informatron
end