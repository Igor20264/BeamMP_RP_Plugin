--====================================================================================
-- All work by Pastry and deer.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP Race start UI
--====================================================================================
local M = {}
print("Loading Carp RaceStart UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base
local headingFont = "cairo_semibold_large"

local RACE_INFO = {}

-- race settings
local betAmount = im.IntPtr(50)
local isTitleRace = im.BoolPtr(false)
local minBet = 50
local maxBet = 100

-- draw functions: -->
local function drawRecordItem(item)
  im.Columns(5, "recorditems")
  im.Text(item.playerName or "---")
  im.SameLine()
  im.NextColumn()

  im.Text(item.duration or "---")
  im.SameLine()
  im.NextColumn()

  im.Text(item.vehicleName or "---")
  im.NextColumn()

  im.Text(item.powerToWeight or "---")
  im.SameLine()
  im.NextColumn()

  im.Text("$" .. (item.totalCost or "---"))
  im.NextColumn()
end

local function printRecordsHeader()
  im.Columns(5, "recorditems")

  im.Text("Player: ")
  im.SameLine()
  im.NextColumn()

  im.Text("Duration: ")
  im.SameLine()
  im.NextColumn()

  im.Text("Vehicle: ")
  im.SameLine()
  im.NextColumn()

  im.Text("Power To Weight: ")
  im.SameLine()
  im.NextColumn()

  im.Text("Parts Cost:")
  im.SameLine()
  im.NextColumn()
  im.TextWrapped("")

  im.Columns(1, "wewee")
end

local function drawRaceMenu()
  if not base.beginWindow("RaceStartUI", "Race Start Menu", nil, false) then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(base.getUISetting("window_scale"))

  base.uiIconImageButton(base.icons.mission_airace02_triangle, im.ImVec2(36, 36))
    im.SameLine()
  base.textWithFont(RACE_INFO.name, headingFont)

  im.TextWrapped(RACE_INFO.description or "No description")

  im.Separator()

  if RACE_INFO.isPreparing then
    if im.Button("Start Race") then
      TriggerServerEvent("receiveStartRace", RACE_INFO.waypoint)
    end

    base.endWindow()
    return
  end

  if RACE_INFO.isCountingDown then
    im.TextWrapped("Counting down...")

    base.endWindow()
    return
  end

  im.Columns(1, "racemenu")

  im.TextWrapped("Create race (for party or solo): ")
  if im.Button("Create") then
    local data = {}
    data.betAmount = betAmount[0]
    data.isTitleRace = isTitleRace[0]
    data.waypoint = RACE_INFO.waypoint

    local jsonfied = jsonEncode(data)
    jsonfied = jsonfied:gsub(":", "=")

    TriggerServerEvent("receiveCreateRace", jsonfied)
  end

  im.TextWrapped(" ")

  im.SliderInt("Bet Amount", betAmount, minBet, maxBet)

  if RACE_INFO.powerWeightRatings then
    im.Separator()

    im.TextWrapped("Participants' Power-to-Weight ratings:")

    local pwRatings = stringToTable(RACE_INFO.powerWeightRatings, "|")

    for k, v in pairs(pwRatings) do
      im.TextWrapped(v or "")
    end

    im.Separator()
  end

  if RACE_INFO.records and #RACE_INFO.records >= 1 then
    im.Columns(1, "woow")
    im.TextWrapped("Best times for this race:")

    printRecordsHeader()

    for _, item in pairs(RACE_INFO.records) do
      drawRecordItem(item)
    end

    im.Separator()
  end

  if RACE_INFO.vehicleRecords and #RACE_INFO.vehicleRecords >= 1 then
    im.Columns(1, "woow2")
    im.TextWrapped("Best times for this race with this vehicle:")

    printRecordsHeader()

    for _, item in pairs(RACE_INFO.vehicleRecords) do
      drawRecordItem(item)
    end

    im.Separator()
  end

  base.endWindow()
end

-- draw functions <--

local function onClientReceiveRaceStartMenu(data)
  print("decoding data: " .. data)
  RACE_INFO = jsonDecode(data)
end

-- event handlers <--

local function onExtensionLoaded()
  base.registerWindow("RaceStartUI", im.ImVec2(500, 350))

  AddEventHandler("onClientReceiveRaceStartMenu", onClientReceiveRaceStartMenu)

  log("I", "onExtensionLoaded", "RaceStart UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("RaceStartUI")
  else
    base.hideWindow("RaceStartUI")
    RACE_INFO = {}
  end
end

local function onUpdate()
  drawRaceMenu()
end

M.onExtensionLoaded = onExtensionLoaded
M.showWindow = showWindow
M.onUpdate = onUpdate

print("RaceStart UI loaded")
return M
