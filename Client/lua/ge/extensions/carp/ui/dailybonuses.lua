--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP DailyMission UI
--====================================================================================
local M = {}
print("Loading Carp Daily Mission UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local headingFont = "cairo_semibold_large"
local icon_size = base.getIconSize()
local hideWindow = nil
local dailyMissionData = nil

--
local function getDailyMissionIcon(completed)
  local iconName = completed and "check_box" or "check_box_outline_blank"

  base.uiIconImage(base.icons[iconName], icon_size)
end

local function getTimeUntilNextDailyBonus()
  if not dailyMissionData or not dailyMissionData[1] or not dailyMissionData[1].lastDailyBonusTimestamp then
    return
  end

  local lastTime = tonumber(dailyMissionData[1].lastDailyBonusTimestamp)
  local currentTime = os.time()
  local oneDayInSeconds = 86400

  local timeSinceStamp = currentTime - tonumber(lastTime)
  local timeUntilNextBonus = oneDayInSeconds - timeSinceStamp
  local truncateToTwoDigits = string.format("%.2f", timeUntilNextBonus / 3600)

  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.timer,
      text = "You can get new bonuses in " .. truncateToTwoDigits .. " hours."
    }
  )
end

local function getBeautifiedTimeString(s)
  local h = math.floor(s / 3600)
  s = s % 3600
  local m = math.floor(s / 60)
  s = s % 60
  return string.format("%02d:%02d:%02d", h, m, s)
end

local function renderMessageContents()
  if not dailyMissionData then
    return im.TextWrapped("Loading daily bonuses...")
  end

  for _, data in pairs(dailyMissionData) do
    getDailyMissionIcon(tonumber(data.completed) == 1)
    im.SameLine()
    im.TextWrapped("" .. data.readableMessage)
  end
end

--=============== Layout Functions ===============--
local function drawDailyMissionPopup()
  if not dailyMissionData then
    return
  end

  if not base.beginWindow("CarpDailyMissionUI", "Daily Missions", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  local icon_size = base.getIconSize()

  im.Spacing()

  if dailyMissionData[1] and dailyMissionData[1]["targetMap"] then
    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.map,
        text = "Your lucky map for the day: " .. dailyMissionData[1]["targetMap"]
      }
    )

    im.TextWrapped(
      "Finish these dailies on this map to get some nice bonuses (and extra money on EVERY mission you complete!)"
    )
    im.TextWrapped("")
  end

  if dailyMissionData[1] and dailyMissionData[1]["speedBonusVehicleName"] then
    local name = dailyMissionData[1]["speedBonusVehicleName"]

    if carp_vehiclenames.vehicleNames and carp_vehiclenames.vehicleNames[name] then
      name = carp_vehiclenames.vehicleNames[name]
    end

    carp_ui_base.drawSmallIconWithText(
      {
        icon = carp_ui_base.icons.directions_car,
        text = "Your lucky vehicle for the day: " .. name,
        tooltip = "Using this vehicle will give you the speed bonuses for your highest tier vehicle!"
      }
    )

    im.TextWrapped("")
  end

  --

  renderMessageContents()

  --

  im.Separator()

  getTimeUntilNextDailyBonus()

  base.endWindow()
end

local function onUpdate()
  drawDailyMissionPopup()
end

--=============== BeamMP Integration Functions ===============--
local function receiveDailyMissionFromServer(payload)
  dailyMissionData = jsonDecode(payload)
end

local function showWindow(show)
  if show then
    base.showWindow("CarpDailyMissionUI")
  else
    base.hideWindow("CarpDailyMissionUI")
  end
end

local function onExtensionLoaded()
  base.registerWindow("CarpDailyMissionUI", im.ImVec2(500, 75))

  if not base.getUISetting("hide_window_CarpDailyMissionUI") then
    base.showWindow("CarpDailyMissionUI")
  end

  AddEventHandler("onClientReceiveDailyBonuses", receiveDailyMissionFromServer)

  log("I", "onExtensionLoaded", "DailyMission UI initialized.")
end

M.onExtensionLoaded = onExtensionLoaded
M.showWindow = showWindow
M.onUpdate = onUpdate

print("DailyMission UI loaded")
return M
