--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp WindowsToolbar UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

ICON_SIZE_MULTIPLIER = 1

local windowIcons = {
  CarpCustomUI = "weekend",
  CarpSpawningUI = "fg_vehicle_race_car",
  CarpHelpUI = "symbol_question",
  CarpPartyUI = "people",
  CarpSettingsUI = "build",
  CarpWeatherUI = "simobject_cloud_layer",
  VehicleInventoryUI = "ab_asset_prefab",
  CarpDailyMissionUI = "av_timer",
  CarpMainUI = "home",
  CarpVehicleStatsUI = "trending_up"
}

local DEFAULT_ICON = "view_compact"

local function toggleWindowVisibility(windowName)
  if base.isWindowVisible(windowName) then
    base.hideWindow(windowName)
    base.saveUISetting("hide_window_" .. windowName, true)
  else
    base.showWindow(windowName)
    base.saveUISetting("hide_window_" .. windowName, false)
  end
end

local function hideAllWindows()
  for windowName, _ in pairs(base.carpWindows) do
    base.hideWindow(windowName)
    base.saveUISetting("hide_window_" .. windowName, true)
  end
end

-- draw functions: -->
local function drawWindowsToolbarPopup()
  if not base.beginWindow("WindowsToolbarUI", "Windows", im.WindowFlags_NoTitleBar, true) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  local count = 0

  for windowName, readableTitle in pairs(base.carpWindows) do
    local windowIcon = windowIcons[windowName] or DEFAULT_ICON

    if base.uiIconImageButton(base.icons[windowIcon], base.getIconSize(ICON_SIZE_MULTIPLIER)) then
      if base.getUISetting("one_window_mode") then
        hideAllWindows()
      end

      toggleWindowVisibility(windowName)
    end
    if im.IsItemHovered() then
      im.SetTooltip(readableTitle)
    end

    if count ~= 1 then
      count = count + 1

      im.SameLine()
    else
      count = 0
    end
  end

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("WindowsToolbarUI", im.ImVec2(75, 215))

  base.showWindow("WindowsToolbarUI")

  if not base.isWindowVisible("WindowsToolbarUI") then
    M.showWindow("WindowsToolbarUI")
    M.saveUISetting("hide_window_" .. "WindowsToolbarUI", false)
  end

  log("I", "onExtensionLoaded", "WindowsToolbar UI initialized.")
end

local function onUpdate()
  drawWindowsToolbarPopup()
end

M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate

print("WindowsToolbar UI loaded")
return M
