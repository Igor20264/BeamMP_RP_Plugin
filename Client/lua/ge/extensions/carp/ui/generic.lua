--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP generic UI (used for mission contacts)
--====================================================================================
local M = {}
print("Loading Carp Generic UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local UI_MISSION_DESCRIPTION = nil
local MESSAGE_TO_SHOW = ""

local function printMissionMessage() -- helper function
  if UI_MISSION_DESCRIPTION then
    --return
    im.TextWrapped("Mission: " .. UI_MISSION_DESCRIPTION)
    im.NextColumn()

    if im.Button("Complete Mission") then
      carp.sendMissionRequest()
    end
    im.NextColumn()
  else
    --return
    im.TextWrapped("To start, press the CaRP Mission Button or this:")
    im.NextColumn()

    if im.Button("Start Mission") then
      carp.sendMissionRequest()
    end
    im.NextColumn()
  end
end

-- draw functions: -->
local function drawGenericMenu()
  if not base.isWindowVisible("GenericUI") or not carp.currentIsOwned then
    return
  end

  -- expects this format:  " windowtitle|toprowheader|numofcolumns|type^text^function^argument+repeatsxxxxxxxxxxxxx then ends each row with < "
  if (MESSAGE_TO_SHOW ~= "" and MESSAGE_TO_SHOW ~= nil) then
    local menuLayout = stringToTable(MESSAGE_TO_SHOW, "|")

    if not base.beginWindow("GenericUI", tostring(menuLayout[1]), nil, false) then
      base.endWindow()
      return
    end

    im.SetWindowFontScale(base.getUISetting("window_scale"))

    im.Columns(1, "Asd")

    im.TextWrapped(menuLayout[2])
    im.NextColumn()
    im.Separator()

    if (menuLayout[1] == "Mission Menu") then
      im.Columns(2, "Asd")
      printMissionMessage()
      im.Separator()
    end

    im.Columns(tonumber(menuLayout[3] or 2), "Asd")

    if (menuLayout[4] ~= "" and menuLayout[4] ~= nil) then
      local menuRows = stringToTable(menuLayout[4], "<")

      for i, j in pairs(menuRows) do
        local menuColumns = stringToTable(j, "+")

        for k, v in pairs(menuColumns) do
          local menuObject = stringToTable(v, "^")

          if (menuObject[1] == "text") then
            im.TextWrapped(tostring(menuObject[2]))
          else
            if im.Button(tostring(menuObject[2])) then
              if (menuObject[3] ~= "" and menuObject[4] ~= "") then
                TriggerServerEvent(menuObject[3], menuObject[4])
              end
            end
          end

          im.NextColumn()
        end

        im.NextColumn()
        im.Separator()
      end
    end

    im.Columns(1, "Asd")
    base.endWindow()
  end
end
-- draw functions <--

-- event handlers: -->
local function onClientReceiveGenericMenu(data)
  MESSAGE_TO_SHOW = data
end
-- event handlers <--

local function onExtensionLoaded()
  base.registerWindow("GenericUI", im.ImVec2(300, 450))

  AddEventHandler("onClientReceiveGenericMenu", onClientReceiveGenericMenu)

  -- showCarpUI()

  log("I", "onExtensionLoaded", "Generic UI initialized.")
end

local function showWindow(show)
  if show then -- show == 1 then
    base.showWindow("GenericUI")
  else
    base.hideWindow("GenericUI")
    MESSAGE_TO_SHOW = ""
  end
end

local function onUpdate()
  drawGenericMenu()
end

M.onExtensionLoaded = onExtensionLoaded
M.showWindow = showWindow
M.onUpdate = onUpdate

print("Generic UI loaded")
return M
