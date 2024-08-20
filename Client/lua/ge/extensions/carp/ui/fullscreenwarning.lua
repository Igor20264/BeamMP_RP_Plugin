--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP FullScreenInfo UI
--====================================================================================
local M = {}
print("Loading Carp FullScreenInfo UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local headingFont = "cairo_semibold_large"
local icon_size = base.getIconSize()
local hideWindow = nil
local messageContents = nil

--
local function renderMessageContents()
  if not messageContents.contents then
    return
  end

  for _, message in pairs(messageContents.contents) do
    if type(message) ~= "string" and message.type == "button" then
      if im.Button(message.text) then
        local func, err = load(message.func)

        if func then
          func()
        end
      end
    else
      im.TextWrapped(message)
    end
  end
end

--=============== Trader Layout Functions ===============--
local function drawFullscreenInfoPopup()
  if not messageContents then
    return
  end
  if not base.beginWindow("FullscreenInfo", "Info", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  local icon_size = base.getIconSize()

  im.Spacing()

  --
  base.uiIconImage(base.icons.error_outline, icon_size)
  im.SameLine()
  base.textWithFont(messageContents.heading or "Important information!", headingFont, true)
  im.Separator()
  --
  renderMessageContents()
  im.Separator()
  --

  if base.uiIconImageButton(base.icons.check_circle, icon_size) then
    hideWindow()
  end
  im.SameLine()
  if im.Button("Got it!") then
    hideWindow()
  end

  base.endWindow()
end

--=============== Imgui Render Functions ===============--
hideWindow = function()
  messageContents = nil
  base.hideWindow("FullscreenInfo")
end

local function onUpdate()
  drawFullscreenInfoPopup()
end

--=============== BeamMP Integration Functions ===============--
local function onReceiveFullscreenInfo(payload)
  messageContents = jsonDecode(payload)

  base.showWindow("FullscreenInfo")
end

local function onExtensionLoaded()
  base.registerWindow("FullscreenInfo", im.ImVec2(1200, 600))

  AddEventHandler("onReceiveFullscreenInfo", onReceiveFullscreenInfo)

  log("I", "onExtensionLoaded", "FullScreenInfo UI initialized.")
end

M.onExtensionLoaded = onExtensionLoaded
--M.showWindow = showWindow -- does not exist
M.onUpdate = onUpdate

print("FullScreenInfo UI loaded")
return M
