--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP UI
--====================================================================================
local M = {}
print("Loading Carp Generic UI...")

M.dependencies = {"ui_imgui"}

local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui

local defaultSettings = {
  window_scale = 1,
  icon_scale = 0.8,
  sfx_volume = 5,
  mission_auto_complete = true,
  distance_lights_distance = 50,
  distance_lights_enabled = true,
  rain_enabled = true,
  disable_groundmarkers = false,
  offroad = true,
  passengers = true,
  one_window_mode = true,
  theme = {
    opacity = 0.9,
    r = 0.15,
    g = 0.35,
    b = 0.8
  }
}
local UI_SETTINGS = nil

local UI_MISSION_DESCRIPTION = nil
local UI_BANK_BALANCE = 0

local UI_EARNED = 0.0
local UI_SPENT = 0.0
local UI_MONEY_PER_MINUTE = nil

local availableDrawItems = {}

isThemePushed = false

local carpWindows = {
  CarpMainUI = "Main",
  CarpCustomUI = "Custom",
  CarpSpawningUI = "Spawn",
  CarpHelpUI = "Help",
  CarpPartyUI = "Party",
  CarpSettingsUI = "Settings",
  CarpWeatherUI = "Weather",
  VehicleInventoryUI = "Vehicle Inventory",
  CarpDailyMissionUI = "Daily Bonuses",
  CorporationUI = "Corporations",
  CarpVehicleStatsUI = "Vehicle Stats"
}

local function getUISetting(settingName)
  if UI_SETTINGS[settingName] == nil then
    return defaultSettings[settingName]
  end

  return UI_SETTINGS[settingName]
end

--theme style
local function setWindowTheme(forceThemeUpdate)
  if not isThemePushed then
    Engine.imgui.enableBeamNGStyle()
    log("I", "", "Pushing BeamNG Style")
  end

  if not isThemePushed or forceThemeUpdate then
    log("I", "", "Pushing CaRP Style")

    local bgOpacity = (getUISetting("theme") and getUISetting("theme").opacity) or defaultSettings.theme.opacity
    local r = (getUISetting("theme") and getUISetting("theme").r) or defaultSettings.theme.r
    local g = (getUISetting("theme") and getUISetting("theme").g) or defaultSettings.theme.g
    local b = (getUISetting("theme") and getUISetting("theme").b) or defaultSettings.theme.b

    local rDarker = r * 0.1
    local gDarker = g * 0.1
    local bDarker = b * 0.1

    --push style
    im.PushFont3("notosans_sc_regular")
    im.PushStyleColor2(im.Col_Button, im.ImVec4(0.2, 0.2, 0.2, 0.7))
    im.PushStyleColor2(im.Col_ButtonHovered, im.ImVec4(r, g, b, 0.7))
    im.PushStyleColor2(im.Col_Text, im.ImVec4(1, 1, 1, 1))
    im.PushStyleColor2(im.Col_TextDisabled, im.ImVec4(0.8, 0.8, 0.8, 0.5))
    im.PushStyleColor2(im.Col_WindowBg, im.ImVec4(rDarker, gDarker, bDarker, bgOpacity))
    im.PushStyleColor2(im.Col_PopupBg, im.ImVec4(0, 0, 0, bgOpacity))
    im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0, 0, 0, 0.8))
    im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0, 0, 0, bgOpacity))
    im.PushStyleColor2(im.Col_Header, im.ImVec4(0.2, 0.2, 0.2, 0.7))
    im.PushStyleColor2(im.Col_HeaderHovered, im.ImVec4(r, g, b, 0.7))

    im.PushStyleColor2(im.Col_ButtonActive, im.ImVec4(r, g, b, 0.7))
    im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(r, g, b, bgOpacity))
    im.PushStyleColor2(im.Col_HeaderActive, im.ImVec4(r, g, b, bgOpacity))

    im.PushStyleColor2(im.Col_Button, im.ImVec4(rDarker, gDarker, bDarker, 0.7))
    im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(rDarker, gDarker, bDarker, bgOpacity))
    im.PushStyleColor2(im.Col_Header, im.ImVec4(rDarker, gDarker, bDarker, bgOpacity))

    im.PushStyleVar1(im.StyleVar_WindowRounding, 5.0)
    im.PushStyleVar1(im.StyleVar_ChildRounding, 2.0)
    im.PushStyleVar1(im.StyleVar_PopupRounding, 2.0)
    im.PushStyleVar1(im.StyleVar_FrameRounding, 2.0)
    im.PushStyleVar1(im.StyleVar_ScrollbarRounding, 2.0)
    im.PushStyleVar1(im.StyleVar_GrabRounding, 2.0)
    im.PushStyleVar1(im.StyleVar_TabRounding, 2.0)

    isThemePushed = true
  end
end

local function loadSavedSettings()
  UI_SETTINGS = jsonReadFile("settings/carpsettings.json")

  if not UI_SETTINGS then
    UI_SETTINGS = jsonReadFile("carpsettings.json")
    if UI_SETTINGS then -- migrate old settings file
      jsonWriteFile("settings/carpsettings.json", UI_SETTINGS)
      FS:removeFile("carpsettings.json") -- dispose of the evidence
    else
      UI_SETTINGS = defaultSettings
    end
  end
end

local function saveUISetting(settingName, value)
  UI_SETTINGS[settingName] = value
  jsonWriteFile("settings/carpsettings.json", UI_SETTINGS)
end

-- draw bits
local function drawBalance()
  im.Columns(3, "balancecolumns")

  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.attach_money,
      tooltip = "Your balance is: $" .. UI_BANK_BALANCE .. ".",
      text = "Balance: $" .. UI_BANK_BALANCE,
      iconColor = im.ImVec4(1, 0.8, 0.25, 1)
    }
  )

  local earningsText = "This session, you've earned $" .. UI_EARNED .. "."
  local earningPlusDpm = ""
  local dollarSignText = ""
  local dpmText = ""

  if UI_MONEY_PER_MINUTE then -- this would use a processed UI_MONEY_PER_MINUTE, this will work if the value is eg -0.001, which is "rounded" to 0 first, then check its negativity, will display 0 properly in that case
    local formattedMoneyPerMinute = string.format("%.2f", math.abs(UI_MONEY_PER_MINUTE)) -- this should be display only

    dollarSignText = tonumber(string.format("%.2f", UI_MONEY_PER_MINUTE)) < 0 and "-$" or "$" -- use "rounded" UI_MONEY_PER_MINUTE

    earningPlusDpm = "Earnings: " .. earningsText .. " (" .. dollarSignText .. formattedMoneyPerMinute .. "/minute)"

    dpmText = " (" .. dollarSignText .. formattedMoneyPerMinute .. "/min)"
  end

  im.NextColumn()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.call_made,
      tooltip = earningPlusDpm or "Earnings",
      text = "Earned: $" .. UI_EARNED,
      iconColor = im.ImVec4(.25, 1, .25, 1)
    }
  )
  im.TextWrapped(dpmText)

  im.SameLine()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.refresh,
      tooltip = "Reset earnings per minute",
      size = 16,
      func = function()
        TriggerServerEvent("resetMoneyPerMinute", "")
        UI_MONEY_PER_MINUTE = 0
      end
    }
  )

  im.NextColumn()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.call_received, -- poopies :)
      tooltip = "This session, you've spent $" .. tostring(math.ceil(tonumber(UI_SPENT))) .. ".",
      text = "Spent: $" .. tostring(math.ceil(tonumber(UI_SPENT))),
      iconColor = im.ImVec4(1, .25, .25, 1)
    }
  )

  im.Columns(1, "balancecolumns")
end

-- event handlers: -->
local function onClientStartMission(missionData)
  local decodedData = jsonDecode(missionData)

  if (decodedData.missionMessage and decodedData.missionMessage ~= "") then
    UI_MISSION_DESCRIPTION = decodedData.missionMessage
    UI_MISSION_DESCRIPTION = UI_MISSION_DESCRIPTION:gsub("%%", "%%%%")
  end

  if (decodedData.special ~= nil and UI_MISSION_DESCRIPTION ~= nil) then
    UI_MISSION_DESCRIPTION = "Trailer Mission: " .. tostring(UI_MISSION_DESCRIPTION)
  end
end

local function onClientEndMission()
  UI_MISSION_DESCRIPTION = nil
end

local function onClientReceiveBalance(data)
  UI_BANK_BALANCE = tonumber(data)
end

local function onClientReceiveProfitStats(data)
  local decodedData = jsonDecode(data)

  if not decodedData or not decodedData.totalEarned or not decodedData.totalSpent then
    return
  end

  UI_EARNED = tonumber(decodedData.totalEarned)
  UI_SPENT = tonumber(decodedData.totalSpent)

  if decodedData.moneyPerMinute then
    UI_MONEY_PER_MINUTE = decodedData.moneyPerMinute
  end
end

local function renderVisibleWindowsFromSetting()
  for name, _ in pairs(carpWindows) do
    M.hideWindow(name)
  end

  for name, _ in pairs(carpWindows) do
    local isVisible = M.getUISetting("hide_window_" .. name)

    if not isVisible then
      M.showWindow(name)
    else
      M.hideWindow(name)
    end
  end
end

local function onExtensionLoaded()
  M.guiModule = require("editor/api/gui")

  M.guiModule.initialize(M)

  loadSavedSettings()

  AddEventHandler("onClientStartMission", onClientStartMission)
  AddEventHandler("onClientEndMission", onClientEndMission)
  AddEventHandler("onClientReceiveBalance", onClientReceiveBalance)
  AddEventHandler("onClientReceiveProfitStats", onClientReceiveProfitStats)

  log("I", "onExtensionLoaded", "CaRP Base UI initialized.")

  renderVisibleWindowsFromSetting()

  M.registerDrawItem("balance", "Balance", drawBalance)
  log("I", "onExtensionLoaded", "carp_ui_base loaded.")
end

local ranWindowCleanup = false
local function onUpdate(dtReal)
  setWindowTheme()

  if not ranWindowCleanup then
    if
      core_gamestate and core_gamestate.state and core_gamestate.state.state and
        core_gamestate.state.state == "multiplayer"
     then
      ranWindowCleanup = true
      renderVisibleWindowsFromSetting()

      M.showWindow("WindowsToolbarUI")
    end
  end
end

local function textWithFont(text, fontName, isWrapped)
  im.PushFont3(fontName)

  if isWrapped then
    im.TextWrapped(text)
  else
    im.Text(text)
  end

  im.PopFont()
end

local function getBalance()
  return UI_BANK_BALANCE
end

local function getMissionDescription()
  return UI_MISSION_DESCRIPTION
end

local function getIconSize(multiplier)
  local px = 32 * getUISetting("icon_scale") * getUISetting("window_scale") * (multiplier or 1)
  return im.ImVec2(px, px)
end

local function getAvailableDrawItems()
  return availableDrawItems
end

local function registerDrawItem(name, title, fun, isVisible)
  availableDrawItems[name] = {
    title = title,
    draw = fun,
    isVisible = isVisible or function()
        return true
      end
  }
end

local function drawSmallIconWithText(params)
  local icon = params.icon
  local tooltip = params.tooltip
  local text = params.text
  local func = params.func
  local size = params.size
  local iconColor = params.iconColor
  local textColor = params.textColor
  local bgColor = params.bgColor

  if not size then
    size = 20
  end
  size = size * M.getUISetting("window_scale")

  -- uiIconImageButton(icon, size, col, label, backgroundCol, id, textColor, textBG, onRelease, highlightText)
  if func and not bgColor then
    bgColor = im.ImVec4(0.1, 0.4, 1, 0.26)
  end

  if icon and M.uiIconImageButton(icon, im.ImVec2(size, size), iconColor, nil, bgColor, nil, textColor) then
    if func then
      func()
    end
  end

  if tooltip then
    if im.IsItemHovered() then
      im.SetTooltip(tooltip)
    end
  end

  if text then
    im.SameLine()
    im.TextWrapped(tostring(text))
  end
end

M.getUISetting = getUISetting
M.saveUISetting = saveUISetting

M.getBalance = getBalance
M.getMissionDescription = getMissionDescription
M.getIconSize = getIconSize
M.getAvailableDrawItems = getAvailableDrawItems
M.registerDrawItem = registerDrawItem

M.drawShowHideMenu = drawShowHideMenu
M.textWithFont = textWithFont
M.drawBalance = drawBalance
M.setWindowTheme = setWindowTheme
M.drawSmallIconWithText = drawSmallIconWithText

M.carpWindows = carpWindows

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded

M.onEditorToolWindowHide = onEditorToolWindowHide

print("Generic UI loaded")
return M
