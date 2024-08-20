-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp VehicleStats UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

-- draw functions: -->
local function drawStats()
  local currentRPM = math.floor(tonumber(carp_vehicle.getEngineStatValue("currentRPM")) or 0)

  if base.uiIconImageButton(base.icons.rotate_right, im.ImVec2(24, 24)) then
  end
  im.SameLine()
  im.TextWrapped("Current RPM: " .. currentRPM)

  local currentTorque = carp_vehicle.getEngineStatValue("currentTorque")
  local maxTorqueRPM = carp_vehicle.getEngineStatValue("maxTorqueRPM")
  local maxTorque = carp_vehicle.getEngineStatValue("maxTorque")

  local torqueString =
    string.format("%.1f", currentTorque) .. " / " .. string.format("%.1f", maxTorque) .. " @ " .. maxTorqueRPM .. "RPM"

  if base.uiIconImageButton(base.icons.fitness_center, im.ImVec2(24, 24)) then
  end
  im.SameLine()
  im.TextWrapped("Torque: " .. torqueString)

  local currentPower = carp_vehicle.getEngineStatValue("currentPower")
  local maxPowerRPM = carp_vehicle.getEngineStatValue("maxPowerRPM")
  local maxPower = carp_vehicle.getEngineStatValue("maxPower")

  local powerString =
    string.format("%.1f", currentPower) .. " / " .. string.format("%.1f", maxPower) .. " @ " .. maxPowerRPM .. "RPM"

  if base.uiIconImageButton(base.icons.send, im.ImVec2(24, 24)) then
  end
  im.SameLine()
  im.TextWrapped("Power: " .. powerString)

  local currentVehicleWeight = (carp.getVehicleWeight() and string.format("%.1f", carp.getVehicleWeight())) or "unknown"

  if base.uiIconImageButton(base.icons.fg_compare, im.ImVec2(24, 24)) then
  end
  im.SameLine()
  im.TextWrapped("Weight: " .. currentVehicleWeight .. "kg")
end

local function drawVehicleStatsPopup()
  if not base.beginWindow("CarpVehicleStatsUI", "Vehicle Stats", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  drawStats()

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("CarpVehicleStatsUI", im.ImVec2(340, 200))
  base.showWindow("CarpVehicleStatsUI")

  log("I", "onExtensionLoaded", "VehicleStats UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("CarpVehicleStatsUI")
  else
    base.hideWindow("CarpVehicleStatsUI")
  end
end

local function onUpdate()
  drawVehicleStatsPopup()
end

M.onExtensionLoaded = onExtensionLoaded
M.showWindow = showWindow
M.onUpdate = onUpdate

print("VehicleStats UI loaded")
return M
