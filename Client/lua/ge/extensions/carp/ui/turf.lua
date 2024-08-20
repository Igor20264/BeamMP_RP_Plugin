local M = {}

M.dependencies = {"ui_imgui", "carp_ui_base"}

local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui
local base = carp_ui_base
local headingFont = "cairo_semibold_large"

local turfName = nil

local canShowPopup = false
local timerDeltas = {popupFrequency = 0, checkHidePopup = 0}
local updateRates = {popupFrequency = 30, checkHidePopup = 5}

local function tryToShowPopup()
  if timerDeltas.popupFrequency > updateRates.popupFrequency then
    canShowPopup = true
    timerDeltas.popupFrequency = 0
  end
end

local function setNewTurf(name)
  turfName = name

  tryToShowPopup()
end

local sizeX, sizeY = 350, 60

local extraSizeYtagline = 30

local posX, posY = 0, 50

local function renderPopup()
  if not turfName then
    return
  end

  local decodedTurfData = json.decode(turfName)
  local name = decodedTurfData.name or ""
  local tag = decodedTurfData.tag or ""
  local color = decodedTurfData.color or ""
  local tagline = decodedTurfData.tagline or ""
  local location = decodedTurfData.location or ""

  local screenSize = GFXDevice.getVideoMode()
  local popupPos = im.ImVec2(posX, posY)

  local finalXSize = math.max(sizeX, string.len(name) * 5)
  finalXSize = math.max(finalXSize, string.len(tagline) * 10)

  popupPos.x = (screenSize.width / 2) - (finalXSize / 2)
  popupPos.y = posY

  popupPos.x = popupPos.x + im.GetWindowPos().x
  popupPos.y = im.GetWindowPos().y

  local splitColor = splitString(color, "|")
  local colorR = (splitColor[1] and tonumber(splitColor[1])) or 1
  local colorG = (splitColor[2] and tonumber(splitColor[2])) or 1
  local colorB = (splitColor[3] and tonumber(splitColor[3])) or 1

  if tagline and tagline == "" then
    tagline = nil
  end

  local effectiveHeight = sizeY + ((tagline and extraSizeYtagline) or 0)

  local calculatedSizeShrink =
    math.max((effectiveHeight) - carp.mapNumberToRange(timerDeltas.checkHidePopup, 4, 5, 0, effectiveHeight, true), 0)
  local calculatedSizeGrow =
    math.min(carp.mapNumberToRange(timerDeltas.checkHidePopup, 0, 2, 0, effectiveHeight, true), effectiveHeight)

  local finalYSize = (timerDeltas.checkHidePopup > 4 and calculatedSizeShrink) or calculatedSizeGrow

  gui.setupWindow("CarpTurfPopup")

  im.Begin("Turf", nil, im.WindowFlags_NoTitleBar + im.WindowFlags_NoResize + im.WindowFlags_NoScrollbar)

  im.SetWindowPos1(popupPos, im.Cond_FirstUseEver)
  im.SetWindowSize1(im.ImVec2(finalXSize, finalYSize), im.Cond_Always)

  im.Columns(1, "tradercolumns")
  im.SetWindowFontScale(base.getUISetting("window_scale"))

  im.SameLine()

  base.drawSmallIconWithText({icon = base.icons.store_mall_directory, size = 16})
  im.SameLine(16, 20)

  uiTextColoredWithFont(im.ImVec4(1, 1, 1, 1), "Entering turf: " .. location, "cairo_bold")
  uiTextColoredWithFont(im.ImVec4(colorR, colorG, colorB, 1), "   " .. "[" .. tag .. "] " .. name, "cairo_bold")

  if tagline then
    uiTextColoredWithFont(
      im.ImVec4(math.min(1, colorR * 1.3), math.min(1, colorG * 1.3), math.min(1, colorB * 1.3), 1),
      "   " .. tagline
    )
  end

  im.End()
end

local function onUpdate(dtReal, dtSim, dtRaw)
  for k, v in pairs(timerDeltas) do
    timerDeltas[k] = timerDeltas[k] + dtReal
  end

  if not canShowPopup then
    timerDeltas.checkHidePopup = 0
  end

  if timerDeltas.checkHidePopup > updateRates.checkHidePopup and be:getPlayerVehicle(0) then
    timerDeltas.checkHidePopup = 0

    canShowPopup = false
    turfName = nil
  end

  renderPopup()
end

local function onExtensionLoaded()
  gui_module.initialize(gui)
  gui.registerWindow("CarpTurfPopup", im.ImVec2(sizeX, sizeY))

  log("I", "onExtensionLoaded", "CarpTurfPopup initialized.")
end

M.onUpdate = onUpdate
M.setNewTurf = setNewTurf
M.onExtensionLoaded = onExtensionLoaded

return M
