--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP UI
--====================================================================================
local M = {}
print("Loading Carp Passenger UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base
local playerVehicle  -- only ever gets set, seemingly unused

local greatAirtimeThreshold = 100
local greatGforceThreshold = 100
local greatSpeedThreshold = 1000
local isExciteMission = false

local perfScore = 1000
local medScore = 3500

-- draw functions: -->
local function drawIcon(icon, text)
  base.uiIconImageButton(base.icons[icon] or base.icons.chat, im.ImVec2(24, 24))

  if text then
    if im.IsItemHovered() then
      im.SetTooltip(text)
    end
  end

  im.SameLine()
end

local function drawPaxIcons()
  local paxList = carp_passengers.getPassengerList()

  if #paxList <= 1 then
    return
  end

  im.Separator()
  im.TextWrapped("Passengers:")

  for idx, weight in pairs(paxList) do
    local paxWeight = string.format("%.1f", weight)

    drawIcon("person", "Passenger: " .. paxWeight .. "kg")
  end
end

local function drawExciteMissionPopup()
  local paxData = carp_passengers.getPassengerMissionData()

  local excitementScore = paxData.excitementScore
  local currentDriftScore = paxData.currentDriftScore
  local currentGforceScore = paxData.currentGforceScore
  local currentAirtimeScore = paxData.currentAirtimeScore
  local currentSpeedScore = paxData.currentSpeedScore
  local driftCombo = paxData.driftCombo

  if not base.beginWindow("PassengerUI", "Entertain your passenger!", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))
  im.Columns(1, "Asd")

  im.TextWrapped(
    "This passenger doesn't want a dull, comfortable ride. Instead, they want you to give them the experience of a lifetime."
  )
  im.TextWrapped(
    "Do fun stunts, go fast, and make this a ride to remember. Higher scores also means higher expectations."
  )
  im.TextWrapped(
    "But don't crash too hard - they might not enjoy waiting for a tow truck on the side of the road for 3 hours."
  )

  im.Separator()

  im.TextWrapped("Passenger Excitement: " .. math.floor(excitementScore) or 0)

  if currentDriftScore ~= 0 then
    local comboString = (driftCombo >= 1 and "x" .. driftCombo + 1 .. " combo") or ""
    im.TextWrapped("Current drift: " .. (currentDriftScore or 0) .. comboString)
  end

  if currentGforceScore ~= 0 then
    im.TextWrapped("Airtime: " .. math.floor(currentAirtimeScore))
  end

  if currentGforceScore ~= 0 then
    im.TextWrapped("Exciting driving! Score: " .. math.floor(currentGforceScore))
  end

  if currentSpeedScore ~= 0 then
    im.TextWrapped("Great speed! Score: " .. math.floor(currentSpeedScore))
  end

  drawPaxIcons()

  base.endWindow()
end

local function drawPaxMissionPopup()
  local paxData = carp_passengers.getPassengerMissionData()

  local excitementScore = paxData.excitementScore
  local currentDriftScore = paxData.currentDriftScore
  local currentGforceScore = paxData.currentGforceScore
  local currentAirtimeScore = paxData.currentAirtimeScore
  local currentSpeedScore = paxData.currentSpeedScore

  if not base.beginWindow("PassengerUI", "Passengers", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))
  im.Columns(1, "Asd")

  -- im.TextWrapped("Passenger Terror: " .. (math.floor(excitementScore) or 0))

  if currentDriftScore ~= 0 then
    drawIcon()
    im.TextWrapped("Going a bit too fast for these turns, aren't we?")
  end

  if currentGforceScore ~= 0 or currentAirtimeScore ~= 0 then
    drawIcon()
    im.TextWrapped("Ow, my head! I'm bouncing all over the place!")
  end

  if currentSpeedScore ~= 0 then
    drawIcon()
    im.TextWrapped("Slow down, I want to arrive in one piece!")
  end

  if currentDriftScore == 0 and currentGforceScore == 0 and currentSpeedScore == 0 then
    if excitementScore == 0 then
      drawIcon("tag_faces")
      im.TextWrapped("I am radiant. This is bliss. I am one with life.")
    elseif excitementScore <= perfScore then
      drawIcon("tag_faces")
      im.TextWrapped("This is fine. I'm comfortable.")
    elseif excitementScore <= medScore then
      drawIcon("face")
      im.TextWrapped("You're not getting 5 stars for this.")
    else
      drawIcon("thumb_down")
      im.TextWrapped("I just hope I get there alive at this point.")
    end
  end

  drawPaxIcons()

  base.endWindow()
end

-- draw functions <--

local function onExtensionLoaded()
  base.registerWindow("PassengerUI", im.ImVec2(500, 200))

  log("I", "onExtensionLoaded", "Passenger UI initialized.")
end

local function showDriftPopup(show, isExcitementMission)
  if show then
    base.showWindow("PassengerUI")
  else
    base.hideWindow("PassengerUI")
  end

  isExciteMission = isExcitementMission
end

--------

local function onUpdate()
  if not base.isWindowVisible("PassengerUI") then
    return
  end

  if isExciteMission then
    drawExciteMissionPopup()
  else
    drawPaxMissionPopup()
  end
end

M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.showDriftPopup = showDriftPopup

print("Drift UI loaded")
return M
