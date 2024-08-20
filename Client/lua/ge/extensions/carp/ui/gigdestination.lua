--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp GigDestination UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base
local headingFont = "cairo_semibold_large"

local UI_GIG_DESTINATION_NAME = "the destination"

-- draw functions: -->
local function drawGigDestinationPopup()
  if not base.beginWindow("GigDestinationUI", "Mission Destination", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  if UI_GIG_DESTINATION_NAME then
    base.textWithFont("Welcome to " .. UI_GIG_DESTINATION_NAME .. "!", headingFont, true)
  end

  im.Spacing()

  im.TextWrapped("Click here to deliver any items that may be delivered at this destination:")
  if im.Button("Deliver!") then
    carp.sendMissionRequest()
  end

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("GigDestinationUI", im.ImVec2(500, 200))
  base.registerWindow("CarpSpawningUI", im.ImVec2(450, 300)) -- spawning stuff, lets you spawn vehicles

  log("I", "onExtensionLoaded", "GigDestination UI initialized.")
end

local function showGigDestinationPopup(show)
  if show then
    base.showWindow("GigDestinationUI")
  else
    base.hideWindow("GigDestinationUI")
  end
end

local function showWindow(show)
  if show then
    base.showWindow("CarpSpawningUI")
  else
    base.hideWindow("CarpSpawningUI")
  end
end

local function onUpdate()
  drawGigDestinationPopup()
end

M.onExtensionLoaded = onExtensionLoaded
M.showGigDestinationPopup = showGigDestinationPopup
M.showWindow = showWindow
M.onUpdate = onUpdate

print("GigDestination UI loaded")
return M
