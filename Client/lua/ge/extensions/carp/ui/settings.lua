--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP settings UI
--====================================================================================
local M = {}
print("Loading Carp settings UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local icon_size = base.getIconSize()

local settings = {}
settings.oneWindowMode = im.BoolPtr(base.getUISetting("one_window_mode")) or im.BoolPtr(true)
settings.volume = im.IntPtr(base.getUISetting("sfx_volume")) or im.IntPtr(5)
settings.distanceLights = im.IntPtr(base.getUISetting("distance_lights_distance")) or im.IntPtr(50)
settings.distanceLightsEnabled = im.BoolPtr(base.getUISetting("distance_lights_enabled")) or im.BoolPtr(true)
settings.groundMarkersDisabled = im.BoolPtr(base.getUISetting("disable_groundmarkers")) or im.BoolPtr(false)
settings.missionAutoFinishEnabled = im.BoolPtr(base.getUISetting("mission_auto_complete")) or im.BoolPtr(true)
settings.rainEnabled = im.BoolPtr(base.getUISetting("rain_enabled")) or im.BoolPtr(true)
settings.offroad = im.BoolPtr(base.getUISetting("offroad")) or im.BoolPtr(true)
settings.passengers = im.BoolPtr(base.getUISetting("passengers")) or im.BoolPtr(true)

local themeSettings = base.getUISetting("theme")
settings.uiColor = im.ArrayFloat(3)
settings.uiColor[0] = im.Float(themeSettings.r) or im.Float(0.15)
settings.uiColor[1] = im.Float(themeSettings.g) or im.Float(0.35)
settings.uiColor[2] = im.Float(themeSettings.b) or im.Float(0.8)
settings.backgroundOpacity = im.FloatPtr(themeSettings.opacity) or im.FloatPtr(0.9)

local hasSentPreferences = false

-- setting helper functions: -->
local function sendMissionPreferences()
  local payload = jsonEncode({offroad = settings.offroad[0], passengers = settings.passengers[0]})
  if MPGameNetwork.launcherConnected() then
    TriggerServerEvent("receiveMissionPreferences", payload)
    log("I", "sendMissionPreferences", "Carp settings UI has sent mission preferences.")
  end
end

local function onVehicleResetted()
  if not hasSentPreferences then
    sendMissionPreferences()
    hasSentPreferences = true
  end
end

-- setting helper functions <--

-- draw functions: -->
local function drawPassengerVolumeSetting()
  im.Text("Passenger SFX Volume")

  if im.SliderInt("Volume", settings.volume, 0, 10) then
    base.saveUISetting("sfx_volume", settings.volume[0])
  end

  im.Text("")
end

local function drawDistanceLightsSetting()
  im.Text("Dynamic Distance Lights")

  if im.Checkbox("Enabled?", settings.distanceLightsEnabled) then
    base.saveUISetting("distance_lights_enabled", settings.distanceLightsEnabled[0])
  end

  if im.SliderInt("Distance", settings.distanceLights, 5, 500) then
    base.saveUISetting("distance_lights_distance", settings.distanceLights[0])
  end

  im.Text("")
end

local function drawOneWindowModeSetting()
  im.TextWrapped("Allow for only one window open at a time when using the toolbar:")

  if im.Checkbox("Enabled?", settings.oneWindowMode) then
    base.saveUISetting("one_window_mode", settings.oneWindowMode[0])
  end

  im.Text("")
end

local function drawSizeOptions()
  if im.CollapsingHeader1("Window options") then
    if im.Button("Larger Text") then
      base.saveUISetting("window_scale", base.getUISetting("window_scale") + 0.05)
    end
    if im.Button("Smaller Text") then
      base.saveUISetting("window_scale", base.getUISetting("window_scale") - 0.05)
    end
    im.Separator()

    if im.Button("Larger Icons") then
      base.saveUISetting("icon_scale", base.getUISetting("icon_scale") + 0.05)
    end
    if im.Button("Smaller Icons") then
      base.saveUISetting("icon_scale", base.getUISetting("icon_scale") - 0.05)
    end
  end
end

local function drawMissionPreferences()
  im.TextWrapped("Mission Preferences:")

  if im.Checkbox("Offer offroad missions when possible?", settings.offroad) then
    print("setting to:", settings.offroad[0])
    base.saveUISetting("offroad", settings.offroad[0])

    sendMissionPreferences()
  end

  if im.Checkbox("Allow passenger missions?", settings.passengers) then
    print("setting to:", settings.passengers[0])
    base.saveUISetting("passengers", settings.passengers[0])

    sendMissionPreferences()
  end
end

local function drawOtherSettings()
  im.TextWrapped("Other settings:")

  if im.Checkbox("Hide groundmarkers?", settings.groundMarkersDisabled) then
    base.saveUISetting("disable_groundmarkers", settings.groundMarkersDisabled[0])
  end

  if im.Checkbox("Mission auto-finish", settings.missionAutoFinishEnabled) then
    base.saveUISetting("mission_auto_complete", settings.missionAutoFinishEnabled[0])
  end

  if im.Checkbox("Raindrops effect", settings.rainEnabled) then
    base.saveUISetting("rain_enabled", settings.rainEnabled[0])
  end

  drawSizeOptions()
end

local function drawThemeOptions()
  im.TextWrapped("Theme options:")

  if im.SliderFloat("Background Opacity", settings.backgroundOpacity, 0, 1) then
    local existingTheme = base.getUISetting("theme")

    local newTheme = {
      r = existingTheme.r,
      g = existingTheme.g,
      b = existingTheme.b,
      opacity = settings.backgroundOpacity[0]
    }

    base.saveUISetting("theme", newTheme)

    base.setWindowTheme(true)
  end

  if im.ColorEdit3("UI Color##1", settings.uiColor) then
    local existingTheme = base.getUISetting("theme")

    local newTheme = {opacity = existingTheme.opacity}
    newTheme.r = settings.uiColor[0]
    newTheme.g = settings.uiColor[1]
    newTheme.b = settings.uiColor[2]

    base.saveUISetting("theme", newTheme)

    base.setWindowTheme(true)
  end
end

local function drawSettingsUI()
  if not base.beginWindow("CarpSettingsUI", "Settings") then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  im.Columns(1, "Asd")

  im.TextWrapped("Settings:")
  im.Text("")

  drawOneWindowModeSetting()
  im.Separator()
  drawMissionPreferences()
  im.Separator()
  drawPassengerVolumeSetting()
  im.Separator()
  drawDistanceLightsSetting()
  im.Separator()
  drawOtherSettings()
  im.Separator()
  drawThemeOptions()

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("CarpSettingsUI", im.ImVec2(450, 300)) -- settings!

  if base.getUISetting("hide_window_CarpSettingsUI") then
    base.showWindow("CarpSettingsUI")
  else
    base.hideWindow("CarpSettingsUI")
  end

  log("I", "onExtensionLoaded", "Carp settings UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("CarpSettingsUI")
  else
    base.hideWindow("CarpSettingsUI")
  end
end

local function onUpdate()
  drawSettingsUI()
end

M.showWindow = showWindow
M.onExtensionLoaded = onExtensionLoaded
M.onUpdate = onUpdate
M.onVehicleResetted = onVehicleResetted
M.sendMissionPreferences = sendMissionPreferences

print("Carp UI loaded")
return M
