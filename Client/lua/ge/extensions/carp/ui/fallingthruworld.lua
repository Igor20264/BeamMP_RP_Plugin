--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP fallingThruWorld UI
--====================================================================================
local M = {}
print("Loading Carp FallingThruWorld UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local headingFont = "cairo_semibold_large"

local im = ui_imgui
local base = carp_ui_base

-- draw functions: -->
local function drawFallingThruWorldMenu()
  if not base.isWindowVisible("FallingThruWorldUI") or not carp.currentIsOwned then
    return
  end

  if not base.beginWindow("FallingThruWorldUI", "Uh oh!", nil, false) then
    base.endWindow()
    return
  end
  im.SetWindowFontScale(base.getUISetting("window_scale"))
  im.Columns(1, "Asd")

  base.textWithFont("Need help?", headingFont)
  im.TextWrapped("It looks like you are falling through the world.")
  im.TextWrapped("Do you need help?")
  im.TextWrapped("Press this button to be moved to a garage:")

  if im.Button("Teleport to Garage") then
    carp.teleportToClosestGarage()
  end

  base.endWindow()
end
-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("FallingThruWorldUI", im.ImVec2(300, 450))

  log("I", "onExtensionLoaded", "FallingThruWorld UI initialized.")
end

local function showWindow(show)
  if show then -- show == 1 then
    base.showWindow("FallingThruWorldUI")
  else
    base.hideWindow("FallingThruWorldUI")
    MESSAGE_TO_SHOW = ""
  end
end

local function onUpdate()
  drawFallingThruWorldMenu()
end

M.onExtensionLoaded = onExtensionLoaded
M.showWindow = showWindow
M.onUpdate = onUpdate

print("FallingThruWorld UI loaded")
return M
