--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP UI
--====================================================================================
local M = {}
print("Loading Carp UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local UI_MISSION_STREAK = nil

-- draw functions: -->

local function drawMissionStreak()
  if not UI_MISSION_STREAK or UI_MISSION_STREAK < 2 then
    return
  end

  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.fast_forward,
      tooltip = "Mission Streak: " .. UI_MISSION_STREAK,
      text = "Streak: " .. UI_MISSION_STREAK .. "x"
    }
  )

  im.TextWrapped("")
end

local function drawMissionInfo()
  if not base.getMissionDescription() then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.goat,
        text = "You are not in a mission."
      }
    )
  end

  if base.getMissionDescription() then
    im.TextWrapped("Mission: " .. base.getMissionDescription())

    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.cancel,
        tooltip = "Abandon mission (for a fee)!",
        func = function()
          UI.chatSend("/abandon")
        end,
        text = "Abandon Mission"
      }
    )
  end

  drawMissionStreak()

  im.NextColumn()
end

local function drawMainUI()
  if not base.beginWindow("CarpMainUI", "Main Menu", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  base.drawBalance()

  im.Separator()

  drawMissionInfo()

  base.endWindow()
end

-- draw functions <--

local function onClientReceiveMissionStreak(data)
  UI_MISSION_STREAK = tonumber(data)
end

local function onExtensionLoaded()
  base.registerWindow("CarpMainUI", im.ImVec2(450, 300))

  base.registerDrawItem("missionInfo", "Mission information", drawMissionInfo)

  base.showWindow("CarpMainUI")

  AddEventHandler("onClientReceiveMissionStreak", onClientReceiveMissionStreak)

  log("I", "onExtensionLoaded", "CarpUI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("CarpMainUI")
  else
    base.hideWindow("CarpMainUI")
  end
end

local function onUpdate()
  drawMainUI()
end

M.onExtensionLoaded = onExtensionLoaded
M.showWindow = showWindow
M.onUpdate = onUpdate

print("Carp UI loaded")
return M
