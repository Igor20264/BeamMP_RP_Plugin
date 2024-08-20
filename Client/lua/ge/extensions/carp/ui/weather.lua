--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP Weather UI
--====================================================================================
local M = {}
print("Loading Carp Weather UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local headingFont = "cairo_semibold_large"
local icon_size = base.getIconSize()
local hideWindow = nil
local weatherData = nil

--

local messagesAndRanges = {
  cloudCover = {
    messages = {"very few clouds", "some clouds", "many clouds", "a completely overcast sky"},
    ranges = {10, 40, 80}
  },
  windSpeed = {
    messages = {"barely any wind", "breeze winds", "gale winds", "storm winds"},
    ranges = {3, 5, 8}
  },
  rainDrops = {
    messages = {"no rain", "some rain", "strong rain", "very heavy rain"},
    ranges = {50, 70, 80}
  },
  fogDensity = {
    messages = {"no fog", "light fog", "foggy conditions", "thick fog"},
    ranges = {15, 40, 80}
  },
  gravity = {
    messages = {"extremely .. light?", "somewhat .. light?", "somewhat .. heavy?", "extremely .. heavy?"},
    ranges = {15, 40, 80} -- TODO: FILL THESE OUT BEFORE YOU ENABLE GRAVITY
  }
}

local icons = {
  sun = "wb_sunny",
  cloud = "simobject_basic_clouds",
  verycloudy = "simobject_cloud_layer",
  rain = "invert_colors"
}

local componentNames = {"cloudCover", "windSpeed", "rainDrops", "fogDensity"}

local function getForecastComponent(component)
  local componentData = messagesAndRanges[component]
  for messageIndex, treshold in ipairs(componentData.ranges) do
    if weatherData[component] <= treshold then
      return componentData.messages[messageIndex]
    end
  end

  return componentData.messages[#componentData.messages] -- return last
end

local function getForecastMessage()
  local finalMessage = "Looks like there's"

  for _, component in ipairs(componentNames) do
    finalMessage = finalMessage .. " " .. getForecastComponent(component) .. ","
  end

  finalMessage = finalMessage:sub(1, -2) .. "."

  return finalMessage
end

local function getWeatherIcon()
  if not weatherData then
    return base.uiIconImage(base.icons.error_outline, icon_size)
  end

  if weatherData.rainDrops and weatherData.rainDrops >= 50 then
    return base.uiIconImage(base.icons[icons.rain], icon_size)
  end

  if weatherData.cloudCover and weatherData.cloudCover >= 40 then
    return base.uiIconImage(base.icons[icons.verycloudy], icon_size)
  end

  if weatherData.cloudCover and weatherData.cloudCover >= 10 then
    return base.uiIconImage(base.icons[icons.cloud], icon_size)
  end

  return base.uiIconImage(base.icons[icons.sun], icon_size)
end

local function renderMessageContents()
  if not weatherData then
    return
  end

  im.Text(getForecastMessage())
end

--=============== Trader Layout Functions ===============--

startX = 10
startY = 65

rectSize = 80

stX = startX
stY = startY
edX = rectSize
edY = startY + rectSize

lineColor = 20
squareColor = 1

local function drawCircleAtPos(x, y, col, size)
  local drawlist = im.GetWindowDrawList()

  im.ImDrawList_PushClipRect(
    drawlist,
    im.ImVec2(im.GetWindowPos().x + startX, im.GetWindowPos().y + startY),
    im.ImVec2(im.GetWindowPos().x + startX + rectSize, im.GetWindowPos().y + startY + rectSize),
    false
  )

  im.ImDrawList_AddCircleFilled(
    drawlist,
    im.ImVec2(im.GetWindowPos().x + x, im.GetWindowPos().y + y),
    size or 10,
    im.GetColorU322(col),
    26
  )
end

local function windToPosition(windNum)
  return carp.mapNumberToRange(windNum, -10, 10, -33, 33)
end

local function drawWindData()
  if carp_weathersync and carp_weathersync.windSpeed then
    local drawlist = im.GetWindowDrawList()

    im.Text("")
    im.Text("")
    im.Text("")
    im.Text("")
    im.Text("")
    if windSpeed then
      im.Text("Wind Speed: " .. string.format("%.1f", carp_weathersync.windSpeed) .. "m/s")
    end

    im.ImDrawList_AddRectFilled(
      drawlist,
      im.ImVec2(im.GetWindowPos().x + startX, im.GetWindowPos().y + startY),
      im.ImVec2(im.GetWindowPos().x + startX + rectSize, im.GetWindowPos().y + startY + rectSize),
      im.GetColorU321(squareColor, 0.5)
    )

    local topLeftX = im.GetWindowPos().x + startX
    local topLeftY = im.GetWindowPos().y + startY
    local bottomRightX = im.GetWindowPos().x + startX + rectSize
    local bottomRightY = im.GetWindowPos().y + startY + rectSize

    -- TR to BL diagonal
    im.ImDrawList_AddLine(
      drawlist,
      im.ImVec2(topLeftX, topLeftY),
      im.ImVec2(bottomRightX, bottomRightY),
      im.GetColorU321(lineColor, 1.0)
    )

    local topRightX = im.GetWindowPos().x + startX + rectSize
    local topRightY = im.GetWindowPos().y + startY
    local bottomLeftX = im.GetWindowPos().x + startX
    local bottomLeftY = im.GetWindowPos().y + startY + rectSize

    -- TL to BR diagonal
    im.ImDrawList_AddLine(
      drawlist,
      im.ImVec2(topRightX, topRightY),
      im.ImVec2(bottomLeftX, bottomLeftY),
      im.GetColorU321(lineColor, 1.0)
    )

    -- circle

    drawCircleAtPos(
      startX + rectSize / 2 + windToPosition(carp_weathersync.windX),
      startY + (rectSize / 2) + windToPosition(carp_weathersync.windY),
      im.ImVec4(1, 1, 0, 1),
      4
    )
  end
end

local function drawWeatherPopup()
  if not weatherData then
    return
  end

  if not base.beginWindow("CarpWeatherUI", "Weather", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  local icon_size = base.getIconSize()

  im.Spacing()

  getWeatherIcon()
  im.SameLine()
  renderMessageContents()

  im.Spacing()

  drawWindData()

  base.endWindow()
end

--=============== Imgui Render Functions ===============--
hideWindow = function()
  weatherData = nil
  base.hideWindow("Weather")
end

local function onUpdate()
  drawWeatherPopup()
end

--=============== BeamMP Integration Functions ===============--
local function receiveWeatherFromServer(payload)
  weatherData = jsonDecode(payload)
end

local function onExtensionLoaded()
  base.registerWindow("CarpWeatherUI", im.ImVec2(500, 75))

  if base.getUISetting("hide_window_CarpWeatherUI") then
    base.showWindow("CarpSettingsUI")
  else
    base.hideWindow("CarpSettingsUI")
  end

  AddEventHandler("receiveWeatherFromServer", receiveWeatherFromServer)

  log("I", "onExtensionLoaded", "Weather UI initialized.")
end

M.onExtensionLoaded = onExtensionLoaded
--M.showWindow = showWindow -- doesn't exist
M.onUpdate = onUpdate

print("Weather UI loaded")
return M
