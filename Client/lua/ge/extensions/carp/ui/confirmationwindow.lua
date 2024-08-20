--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp Confirmation UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local headingFont = "cairo_semibold_large"
local redColor = im.ImVec4(1, 0.3, 0.3, 1)
local greenishBlueColor = im.ImVec4(0.4, 0.6, 1, 255)

local windowData = {}

local function clearConfirmationWindow()
  windowData = {}
end
local function closeConfirmationWindow()
  M.showWindow(false)
end

-- draw functions: -->
local function drawConfirmationPopup()
  if not base.beginWindow("ConfirmationUI", (windowData.windowTitle or "Confirmation Required"), nil, false) then
    base.endWindow()
    return
  end

  if not windowData.onConfirmationFn then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  local confirmationHeading = windowData.confirmationHeading or "Are you sure?"
  local confirmationText = windowData.confirmationText or "Please make sure you want to do what you just meant to do."
  local onConfirmationFn = windowData.onConfirmationFn

  base.textWithFont(confirmationHeading, headingFont, true)
  im.TextWrapped(confirmationText)

  im.TextWrapped("")

  if im.Button("Confirm") then
    onConfirmationFn()
    clearConfirmationWindow()
    closeConfirmationWindow()
  end

  im.SameLine()

  if im.Button("Cancel") then
    clearConfirmationWindow()
    closeConfirmationWindow()
  end

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("ConfirmationUI", im.ImVec2(500, 200))

  log("I", "onExtensionLoaded", "Confirmation UI initialized.")
end

--[[ 
  options: {
    windowTitle = 'string',
    confirmationHeading = 'Are you sure?',
    confirmationText = 'This will have far reaching consequences. Consider them before deciding.',
    onConfirmationFn = function() ref
  }
 ]]
local function showConfirmationPopup(show, options)
  if show then
    windowData = options
    base.showWindow("ConfirmationUI")
  else
    base.hideWindow("ConfirmationUI")
  end
end

local function showWindow(show)
  if show then
    base.showWindow("ConfirmationUI")
  else
    base.hideWindow("ConfirmationUI")
  end
end

local function onUpdate()
  drawConfirmationPopup()
end

M.onExtensionLoaded = onExtensionLoaded
M.showConfirmationPopup = showConfirmationPopup
M.showWindow = showWindow
M.onUpdate = onUpdate

print("Confirmation UI loaded")
return M
