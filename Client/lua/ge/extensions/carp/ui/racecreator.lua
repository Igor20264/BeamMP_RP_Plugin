--====================================================================================
-- All work by Pastry.
-- You have no permission to edit, redistribute or upload. That's all!
--====================================================================================
-- CaRP RaceCreator UI
--====================================================================================
local M = {}
print("Loading Carp RaceCreator UI...")

M.dependencies = {"ui_imgui", "carp_ui_base"}

local im = ui_imgui
local base = carp_ui_base
local ffi = require("ffi")
local UI_STATE = "CarpUIRaceCreator"
local VISIBLE = false

local raceStartLocation = nil
local raceData = {}
raceData.name = im.ArrayChar(500)
raceData.description = im.ArrayChar(500)
raceData.location = nil
raceData.checkpoints = {}
local waypointData = {}
waypointData.locName = im.ArrayChar(500)
waypointData.name = im.ArrayChar(500)
waypointData.type = im.ArrayChar(500)
waypointData.offroad = im.ArrayChar(500)
waypointData.location = nil

local locSetString = "YOU FORGOT TO SET ME!!!"

local function changeUIWindowState(UIStateName) -- helper function
  UI_STATE = UIStateName
end

-- waypoint stuff
local function createMissionGroup(missionGroupName)
  if scenetree[missionGroupName] then
    return
  end --already exists
  if not scenetree.MissionGroup then
    log("E", "createMissionGroup", "scenetree.MissionGroup does not exist!")
    return
  end

  local simGroupObject = createObject("SimGroup")
  simGroupObject:registerObject(missionGroupName)
  simGroupObject.canSave = false

  scenetree.MissionGroup:addObject(simGroupObject.obj)
  log("I", "createMissionGroup", "Created SimGroup " .. missionGroupName)
end

local function createCheckpointMarker(name)
  local color = Point4F(1, 0, 1, 1)
  print("color set to:", color)

  local pos = be:getPlayerVehicle(0):getPosition()
  print("pos set to:", pos)

  local locName = string.gsub(name, " ", "-")
  locName = locName:lower()
  print("locname set to:", locName)

  local marker = createObject("TSStatic")
  marker.shapeName = "art/shapes/interface/checkpoint_marker_base.dae"
  marker:setPosition(pos)
  marker.scale = Point3F(2, 2, 2)
  marker.useInstanceRenderData = 1
  marker.instanceColor = color

  marker:registerObject(name .. "_marker_" .. (#raceData.checkpoints + 1))

  createMissionGroup("CarpMissionDebugGroup")

  scenetree.CarpMissionDebugGroup:addObject(marker.obj)

  local location = pos.x .. "|" .. pos.y .. "|" .. pos.z
  table.insert(raceData.checkpoints, location)

  return marker
end

-- tabs : -->
local function renderRaceCreatorTab()
  if im.BeginTabItem("Race Creator", nil, 0) then
    im.Columns(1, "Asd")

    im.Separator()

    im.InputText("Race Name", raceData.name, ffi.sizeof(raceData.name))
    im.InputText("Description", raceData.description, ffi.sizeof(raceData.description))

    im.TextWrapped("Start set to: " .. locSetString)
    if im.Button("Set start") then
      local pos = be:getPlayerVehicle(0):getPosition()
      local location = pos.x .. "|" .. pos.y .. "|" .. pos.z
      locSetString = location

      raceData.location = location
    end

    im.Separator()

    -- add
    if im.Button("Add Waypoint") then
      createCheckpointMarker(ffi.string(raceData.name))
    end
    -- remove last
    if im.Button("Delete Last Waypoint") then
      scenetree.CarpMissionDebugGroup:findObject(ffi.string(raceData.name) .. "_marker_" .. (#raceData.checkpoints)):delete(

      )
      table.remove(raceData.checkpoints)
    end

    if im.Button("Save to file") then
      local f = jsonReadFile("waypoints.json") or {}
      local mapname = getMissionFilename()
      local locName = string.gsub(ffi.string(raceData.name), " ", "-")
      locName = "racestart-" .. locName:lower()

      local payload = {
        name = ffi.string(raceData.name),
        description = ffi.string(raceData.description),
        location = raceData.location,
        checkpoints = raceData.checkpoints
      }

      f[mapname] = f[mapname] or {}
      f[mapname][locName] = f[mapname][locName] or {}
      table.insert(f[mapname][locName], payload)

      jsonWriteFile("races.json", f)
    end

    im.Separator()

    -- delete all
    if im.Button("Delete ALL Waypoints") then
      if scenetree.CarpMissionDebugGroup then
        scenetree.CarpMissionDebugGroup:delete()
      end
    end

    -- reset everything
    if im.Button("Delete EVERYTHING!!!!!!!!") then
      locSetString = "YOU FORGOT TO SET ME!!!"

      if scenetree.CarpMissionDebugGroup then
        scenetree.CarpMissionDebugGroup:delete()
      end

      raceData.name = im.ArrayChar(500)
      raceData.description = im.ArrayChar(500)
      raceData.location = nil
      raceData.checkpoints = {}
    end
    im.EndTabItem()
  end
end

local function renderWaypointCreatorTab()
  if im.BeginTabItem("waypointCreator", nil, 0) then
    im.Columns(1, "Asd")

    im.Separator()

    im.InputText(
      "Waypoint Name (internal, use contact- prefix to get missions here)",
      waypointData.locName,
      ffi.sizeof(waypointData.locName)
    )
    im.InputText("Display Name", waypointData.name, ffi.sizeof(waypointData.name))
    im.InputText("Type, (Internal name)", waypointData.type, ffi.sizeof(waypointData.type))
    im.InputText("Offroad, ('true' or 'false)", waypointData.offroad, ffi.sizeof(waypointData.offroad))

    im.TextWrapped("Location set to: " .. locSetString)

    if im.Button("Set Waypoint Location") then
      local pos = be:getPlayerVehicle(0):getPosition()
      local location = pos.x .. "|" .. pos.y .. "|" .. pos.z
      locSetString = location

      waypointData.location = location
    end

    if im.Button("Add to file") then
      local f = jsonReadFile("new_waypoints.json") or {}
      local mapname = getMissionFilename()
      local locName = ffi.string(waypointData.locName)
      locName = locName:lower()

      local payload = {
        name = ffi.string(waypointData.name),
        type = ffi.string(waypointData.type),
        offroad = ffi.string(waypointData.offroad),
        location = waypointData.location
      }

      f[mapname] = f[mapname] or {}
      f[mapname][locName] = payload or nil

      jsonWriteFile("new_waypoints.json", f)
    end

    im.Separator()

    im.EndTabItem()
  end
end

-- draw functions: -->
local function drawRaceCreatorUI()
  if not base.beginWindow("RaceCreatorUI", "RaceCreator Menu") then
    base.endWindow()
    return
  end

  im.SetWindowFontScale(carp_ui_base.getUISetting("window_scale"))
  im.TextWrapped("Welcome to the Race and Waypoint creator UI :)")

  if im.BeginTabBar("##CreatorTabBar") then
    renderRaceCreatorTab()
    renderWaypointCreatorTab()
  end

  base.endWindow()
end

-- draw functions <--

local function showRaceCreatorUI()
  base.showWindow("RaceCreatorUI")
end

local function hideRaceCreatorUI()
  base.hideWindow("RaceCreatorUI")
end

local function onClientReceiveRaceCreatorMenu(data)
  print("decoding data:", data)
  RACE_INFO = jsonDecode(data)
end
-- event handlers <--

local function onExtensionLoaded()
  base.registerWindow("RaceCreatorUI", im.ImVec2(500, 350))

  AddEventHandler("onClientReceiveRaceCreatorMenu", onClientReceiveRaceCreatorMenu)

  AddEventHandler("showRaceCreatorUI", showRaceCreatorUI)

  log("I", "onExtensionLoaded", "RaceCreator UI initialized.")
end

local function showWindow(show)
  if show then
    base.showWindow("RaceCreatorUI")
  else
    base.hideWindow("RaceCreatorUI")
  end
end

local function onUpdate()
  drawRaceCreatorUI()
end

M.onExtensionLoaded = onExtensionLoaded
M.drawRaceCreatorUI = showWindow
M.onUpdate = onUpdate

print("RaceCreator UI loaded")
return M
