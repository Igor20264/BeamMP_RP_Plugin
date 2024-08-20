--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP spawn UI
--====================================================================================
local M = {}
print("Loading Carp Garage UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base

local slotKeys = {"configSlotOne", "configSlotTwo", "configSlotThree"}
local slotNames = {}
local UI_GARAGE_NAME = nil
local editingSlotID = nil
local buf_size = 64
local slotnamebuf = im.ArrayChar(buf_size)

local headingFont = "cairo_semibold_large"
local redColor = im.ImVec4(1, 0.3, 0.3, 1)
local greenishBlueColor = im.ImVec4(0.4, 0.6, 1, 255)

local synchroWear
local synchroWearPercentage

-- not pretty, i know
-- TODO: move this to the DB
local function loadSlotNames()
  slotNames = {
    base.getUISetting("configSlotName_one"),
    base.getUISetting("configSlotName_two"),
    base.getUISetting("configSlotName_three")
  }
end

local function saveSlotNames()
  base.saveUISetting("configSlotName_one", slotNames[1])
  base.saveUISetting("configSlotName_two", slotNames[2])
  base.saveUISetting("configSlotName_three", slotNames[3])
end

local function getSynchroWearPercentage()
  if synchroWear then
    local synchroWearTable = splitString(synchroWear, "&")
    local worstWear = 0

    for _, value in pairs(synchroWearTable) do
      if tonumber(value) and tonumber(value) > worstWear then
        worstWear = tonumber(value)
      end
    end

    if worstWear and worstWear ~= 0 then
      synchroWearPercentage = math.floor((worstWear * 100) + 0.5)
    end
  end
end

-- draw functions: -->
local function drawGaragePopup()
  if not base.beginWindow("GarageUI", "Garage!", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  if UI_GARAGE_NAME then
    base.textWithFont("Welcome to " .. UI_GARAGE_NAME .. "!", headingFont, true)
    im.TextWrapped("You are now in a garage.")
  else
    im.TextWrapped("Welcome! You are now in a garage.")
  end

  im.TextWrapped("Costs for car repairs and installing/uninstalling parts are reduced while you're here.")

  im.TextWrapped("Press Ctrl+W to buy and install parts on your vehicle.")

  im.Spacing()
  im.Separator()
  im.Spacing()

  getSynchroWearPercentage()
  local wearPercentageString = ""
  if synchroWearPercentage and synchroWearPercentage ~= 0 then
    wearPercentageString = " (" .. synchroWearPercentage .. "%%" .. ")"
  end

  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.loyalty,
      tooltip = "Fixes a broken synchro if you haven't been careful with gear shifts.",
      text = "Rebuild transmission" .. wearPercentageString,
      iconColor = greenishBlueColor,
      func = function()
        carp.clearSynchroWear()

        synchroWear = nil
        synchroWearPercentage = nil
      end
    }
  )

  im.Spacing()
  im.Separator()
  im.Spacing()

  im.TextWrapped("To log out safely, click this:")
  if base.uiIconImageButton(base.icons.exit_to_app or base.icons.done, nil, redColor) then
    be:getPlayerVehicle(0):queueLuaCommand(
      [[
      recovery.startRecovering()
      recovery.stopRecovering()

      carp.enableQuitCountdown()
    ]]
    )
  end

  base.endWindow()
end

local function drawSpawnLastUsedConfig()
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.fg_vehicle_sports_car,
      tooltip = "Spawn your last used config:",
      func = function()
        TriggerServerEvent("receiveLastLocationAndVehicle", "a")
      end,
      text = "Spawn Last Used Vehicle"
    }
  )
end

local function drawSpawnCustomConfigs()
  local icon_size = base.getIconSize()
  for index, key in pairs(slotKeys) do
    local name = slotNames[index] or "Custom Config Slot " .. index

    if editingSlotID == index then
      im.InputText("##carpcustomvehiclename", slotnamebuf, buf_size)
      im.SameLine()
      if base.uiIconImageButton(base.icons.cancel, icon_size) then
        editingSlotID = nil
      end
      im.SameLine()
      if base.uiIconImageButton(base.icons.save, icon_size) then
        editingSlotID = nil
        slotNames[index] = ffi.string(slotnamebuf)
        saveSlotNames()
      end
    else
      im.TextWrapped(name .. ":")
      im.SameLine()
      if base.uiIconImageButton(base.icons.mode_edit, icon_size) then
        slotnamebuf = im.ArrayChar(buf_size, slotNames[index] or "")
        editingSlotID = index
      end
    end

    im.SameLine(im.GetContentRegionAvailWidth() - (icon_size.x + im.GetStyle().ItemSpacing.x) * 2) -- right align

    if base.uiIconImageButton(base.icons.save, icon_size) then
      TriggerServerEvent("saveLatestConfigToSlot", key)
    end
    if im.IsItemHovered() then
      im.SetTooltip("Save current vehicle as slot '" .. name .. "'")
    end

    im.SameLine(im.GetContentRegionAvailWidth() - icon_size.x) -- right align

    if base.uiIconImageButton(base.icons.fg_vehicle_sports_car, icon_size) then
      TriggerServerEvent("receiveSpawnSavedConfig", key)
    end
    if im.IsItemHovered() then
      im.SetTooltip("Summon (spawn) vehicle '" .. name .. "'")
    end

    im.Separator()
    im.Spacing()
  end
end

local function drawSpawningUI()
  if not base.beginWindow("CarpSpawningUI", "Spawn Menu") then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))
  local icon_size = base.getIconSize()

  -- new picoturdie
  carp_ui_base.drawSmallIconWithText(
    {
      icon = carp_ui_base.icons.fg_vehicle_pigeon,
      tooltip = "Spawn a Pico Turdie (starter vehicle):",
      func = function()
        MPVehicleGE.replaceRequest("autobello", {config = "turdie"})
      end,
      text = "Spawn Starter Vehicle"
    }
  )

  im.Separator()
  im.Spacing()

  drawSpawnLastUsedConfig()

  im.Separator()
  im.Spacing()

  drawSpawnCustomConfigs()

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("GarageUI", im.ImVec2(500, 200))
  base.registerWindow("CarpSpawningUI", im.ImVec2(450, 300)) -- spawning stuff, lets you spawn vehicles

  base.registerDrawItem("spawnLastUsedConfig", "Spawn last used config", drawSpawnLastUsedConfig)
  base.registerDrawItem("spawnCustomConfigs", "Spawn custom configs", drawSpawnCustomConfigs)

  loadSlotNames()

  log("I", "onExtensionLoaded", "Garage UI initialized.")
end

local function showGaragePopup(show, name)
  if show then
    UI_GARAGE_NAME = name
    base.showWindow("GarageUI")
  else
    base.hideWindow("GarageUI")
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
  drawGaragePopup()
  drawSpawningUI()
end

local function updateCachedSynchroWear(data)
  synchroWear = data
end

M.onExtensionLoaded = onExtensionLoaded
M.showGaragePopup = showGaragePopup
M.showWindow = showWindow
M.onUpdate = onUpdate
M.updateCachedSynchroWear = updateCachedSynchroWear

print("Garage UI loaded")
return M
