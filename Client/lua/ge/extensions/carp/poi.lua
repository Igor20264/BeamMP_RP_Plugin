local M = {}

local missionColor = {1, 0, 0}

local mainGroupName = "CarpTriggers"

local original_sendMissionLocationsToMinimap

local rawPoiListByLevel = {}

local clientWaypoints = {}

local triggerData = {
  contact = {
    color = {1, 0.6, 0, 1},
    luaFunction = "carp.requestTraderInfo",
    triggerScale = {2, 2, 2},
    tickPeriod = 2000
  },
  mission = {
    color = {1, 0, 0, 1},
    luaFunction = "carp.showDestinationPopup",
    triggerScale = {2, 2, 2}
  },
  gasstation = {
    color = {0.6, 0.5, 1, 1},
    luaFunction = "carp.showGasStationPopup",
    triggerScale = {3, 3, 3},
    tickPeriod = 1800
  },
  chargingstation = {
    color = {0.01, 0.92, 0.98, 1},
    luaFunction = "carp.showChargingStationPopup",
    triggerScale = {3, 3, 3},
    tickPeriod = 1800
  },
  repairgarage = {
    color = {0.1, 1, 0.3, 1},
    luaFunction = "carp.showGaragePopup",
    markerScale = {5, 5, 2},
    triggerScale = {5, 5, 2},
    tickPeriod = 2000
  },
  cardealership = {
    color = {0.85, 0.2, 0.85, 1},
    luaFunction = "carp.enteredDealership",
    markerScale = {3, 3, 2},
    triggerScale = {3, 3, 3}
  },
  race = {
    color = {1, 0.3, 0, 1},
    luaFunction = "carp_race.showNextWaypoint",
    markerScale = {3.5, 3.5, 200},
    triggerScale = {7.5, 7.5, 7.5},
    tickPeriod = 200
  },
  racestart = {
    color = {1, 0.3, 0, 1},
    luaFunction = "carp.showRaceStartPopup",
    markerScale = {3, 3, 2},
    triggerScale = {3, 3, 3},
    tickPeriod = 200
  },
  debug = {
    color = {1, 0.5, 0.1, 1},
    luaFunction = "",
    markerScale = {2, 2, 2}
  }
}

local function sendToApp()
  local mainGroup = scenetree.CarpTriggers

  if not mainGroup then
    return
  end

  local groups = mainGroup:getObjects()

  local locations = {}

  for _, objName in pairs(groups) do
    local locationCategory, locationName, locationType = string.match(objName, "(%w+)%-(.+)_(.+)")
    if locationType == "marker" then
      local obj = scenetree[objName]
      locations[objName] = {pos = obj:getPosition(), category = locationCategory}
    end
  end

  local data = {
    key = "missions",
    items = {}
  }
  local i = 1
  for _, location in pairs(locations) do
    data.items[i] = location.pos.x
    data.items[i + 1] = location.pos.y
    data.items[i + 2] = "bruh"
    data.items[i + 3] = location.category
    i = i + 4
  end

  guihooks.trigger("NavigationStaticMarkers", data)
end

local function getDisplayName(objID)
  local obj = Sim.findObjectById(objID)
  if not obj then
    return nil
  end

  local name = obj:getField("displayName", "")

  if name == "" then
    return nil
  end
  return name
end

local function createMissionGroup(missionGroupName)
  if scenetree[missionGroupName] then
    return
  end --already exists
  if not scenetree.MissionGroup then
    log("E", "createMissionGroup", "scenetree.MissionGroup does not exist!")
    return
  end

  if not scenetree[mainGroupName] then
    local mainGroupObject = createObject("SimGroup")
    mainGroupObject:registerObject(mainGroupName)
    mainGroupObject.canSave = false
    scenetree.MissionGroup:addObject(mainGroupObject.obj)
  end

  local mainGroupObject = scenetree[mainGroupName]

  local simGroupObject = createObject("SimGroup")
  simGroupObject:registerObject(missionGroupName)
  simGroupObject.canSave = false

  mainGroupObject:addObject(simGroupObject.obj)
  log("I", "createMissionGroup", "Created SimGroup " .. missionGroupName)
end

local function deleteMissionGroup(missionGroupName)
  if not scenetree[missionGroupName] then
    return
  end --doesn't exist
  scenetree[missionGroupName]:delete()
end

local function deleteObjectByName(objectName)
  if not Sim.findObject(objectName) then --doesn't exist
    print("attempted to DELETE simobject:", objectName, "but couldnt find any objects with that name.")
    return
  end

  Sim.findObject(objectName):delete()
end

local function createIconModel(name, iconName, markerPosition, color, sceneTreeGroupName)
  local iconModel = createObject("TSStatic")
  local position = Point3F(markerPosition)
  position.z = position.z + 5
  iconModel.shapeName = "art/shapes/interface/" .. iconName .. ".dae"
  iconModel:setPosition(position)
  iconModel.scale = Point3F(1, 1, 1)
  iconModel.useInstanceRenderData = 1
  iconModel.instanceColor = color
  iconModel:registerObject(name .. "_icon")

  if sceneTreeGroupName and scenetree[sceneTreeGroupName] and iconModel.obj then
    scenetree[sceneTreeGroupName]:addObject(iconModel.obj)
  end

  return iconModel
end

-- takes string, string, string, point3f
local function createScenarioMarker(key, groupName, name, position, data)
  local marker = createObject("TSStatic")
  marker.shapeName = "art/shapes/interface/checkpoint_marker_base.dae"
  marker:setPosition(position)
  marker.scale = Point3F(2, 2, 2)
  marker.useInstanceRenderData = 1
  marker.instanceColor = Point4F(1, 1, 1, 1)
  marker.markerType = groupName

  marker:registerObject(key .. "_marker")

  local triggerobj = createObject("BeamNGTrigger")
  triggerobj.loadMode = 1 -- 'Manual'
  triggerobj:setField("triggerType", 0, "Sphere")
  triggerobj:setField("triggerMode", 0, "Contains")
  triggerobj:setDynDataFieldbyName("displayName", 0, name)
  triggerobj:setPosition(position)

  if triggerData[groupName] then
    local missionGroupName = "Carp" .. groupName .. "TriggersGroup"
    createMissionGroup(missionGroupName)

    local color = Point4F(unpack(triggerData[groupName].color))

    -- icon
    if string.find(groupName, "race") then
      if groupName == "race" then
        createIconModel(key, "race", position, color, missionGroupName)
        createIconModel(
          key .. "_lower",
          "race",
          Point3F(position.x, position.y, position.z - 10),
          color,
          missionGroupName
        ) -- for air races
      else
        createIconModel(key, "race", position, color, missionGroupName)
      end
    else
      createIconModel(key, groupName, position, color, missionGroupName)
    end

    -- marker
    if triggerData[groupName].markerScale then
      marker:setScale(Point3F(unpack(triggerData[groupName].markerScale)))
    else
      marker:setScale(Point3F(2, 2, 2))
    end
    marker.instanceColor = color
    scenetree[missionGroupName]:addObject(marker.obj)

    -- trigger
    if triggerData[groupName].tickPeriod then
      triggerobj.ticking = true
      triggerobj.tickPeriod = triggerData[groupName].tickPeriod
    end

    if triggerData[groupName].luaFunction and triggerData[groupName].luaFunction ~= "" then
      triggerobj.luaFunction = String(triggerData[groupName].luaFunction)
    end

    if triggerData[groupName].triggerScale then
      triggerobj:setScale(Point3F(unpack(triggerData[groupName].triggerScale)))
    else
      triggerobj:setScale(Point3F(2, 2, 2))
    end

    if groupName == "race" and data then
      if data.isLastWaypoint then -- last waypoint, different function and color
        triggerobj.luaFunction = String("carp_race.finishRace")
        marker.instanceColor = Point4F(0, 0.2, 1, 1)
      elseif data.isNotActiveWaypoint then -- secondary waypoint, grayed out
        marker.instanceColor = Point4F(0.3, 0.3, 0.3, 1)
      end
    end

    triggerobj:registerObject(key .. "_trigger")
    scenetree[missionGroupName]:addObject(triggerobj.obj)
  end

  return marker
end

local function carpSpawnWaypoint(key, name, pos, data)
  local coords = stringToTable(pos, "|")
  local p3fCoords = Point3F(tonumber(coords[1]), tonumber(coords[2]), tonumber(coords[3]) + 0.6)

  local pointType = stringToTable(key, "-")[1]

  return createScenarioMarker(key, pointType, name, p3fCoords, data), p3fCoords
end

local function onClientSpawnMarker(missionData)
  local data = stringToTable(missionData, ";")
  local key = data[1]
  local pos = data[2]
  local name = data[3] or data[1]
  carpSpawnWaypoint(key, name, pos)

  sendToApp()
end

local function onClientPopulateWaypoints(poiDataString)
  clientWaypoints = jsonDecode(poiDataString == 'null' and '' or poiDataString) -- we get null? null is bad. causes the parser to fail. '' returns {}
  log('I', 'onClientPopulateWaypoints', "populating client waypoints")
end

local function onClientStartMission(missionData)
  local decodedData = jsonDecode(missionData)

  local key = decodedData.missionDestinationKey or decodedData.missionDestination
  local name = decodedData.missionDestinationName
  local pos = decodedData.destinationCoords

  key = key:gsub("contact", "mission") -- make sure contact markers behave as destination ones

  if (string.find(key, "mission") == nil) then
    key = "mission-" .. key
  end

  -- delete waypoints you should see during a mission
  deleteMissionGroup("CarpcontactTriggersGroup")
  deleteMissionGroup("CarpracestartTriggersGroup")

  local destinationMarker, waypointPos = carpSpawnWaypoint(key, key, pos)

  sendToApp()

  carp_groundmarkers.setDestination(waypointPos, missionColor, true)
  carp.syncWaypoint()
end

local function onClientEndMission()
  if scenetree.CarpmissionTriggersGroup then
    scenetree.CarpmissionTriggersGroup:delete()
  end
  sendToApp()
end

local function removeDebugWaypoints()
  if scenetree.CarpdebugGroup then
    scenetree.CarpdebugGroup:delete()
  end
end

local function spawnDestinationWaypoint(payload)
  local data = jsonDecode(payload)
  local location = data.location

  deleteObjectByName("mission-delivery-destination_icon")
  deleteObjectByName("mission-delivery-destination_marker")
  deleteObjectByName("mission-delivery-destination_trigger")

  carpSpawnWaypoint("mission-delivery-destination", "delivery-destination", location)

  local data = stringToTable(location, "|")

  local nearestWaypoint = vec3(tonumber(data[1]), tonumber(data[2]), tonumber(data[3]))
  local color = {0.9, 0.25, 0.2}

  carp_groundmarkers.setDestination(nearestWaypoint, color, true)
end

local function getRawPoiListByLevel(levelIdentifier)
  if not rawPoiListByLevel[levelIdentifier] then
    print("attemping to build poi list")
    local elements = {}

    if tableIsEmpty(clientWaypoints) then -- do something so we can still leave the server
      print("no pois found..........")
    else
      for key, waypoint in pairs(clientWaypoints) do
        local data = {}
        data["translationId"] = waypoint.name
        data["description"] = waypoint.description

        waypoint.type = waypoint.type or "deliveries" -- if a waypoint doesn't have a type it will lock the players in the server, default to this

        if waypoint.type ~= "deliveries" then

          local previewString = "/art/bigmap/" .. waypoint.type .. ".png"
          data["previews"] = {previewString}

          -- lua moment
          local pos = splitString(clientWaypoints[key].location, "|")
          local x = tonumber(pos[1])
          local y = tonumber(pos[2])
          local z = tonumber(pos[3])
          pos = vec3(x, y, z)

          data.type = "spawnPoint"
          data.id = data.objectname or ("spawnPoint-" .. key)

          table.insert(
            elements,
            {
              id = data.id,
              -- objectname = "spawns_industrial", 
              -- radius = 3,
              data = data,
              clusterType = "invisibleMarker",
              markerInfo = {
                bigmapMarker = {pos = pos, icon = "poi_fasttravel_round_orange_green",  quickTravelPosRotFunction = getSpawnPointPosRot, name = data.translationId, description = data.description, thumbnail = data.previews[1], previews = data.previews}
              }
            }
          )
        end
      end
    end
    rawPoiListByLevel[levelIdentifier] = elements
  end
  return rawPoiListByLevel[levelIdentifier], 0
end

local function onExtensionLoaded()
    AddEventHandler("onClientStartMission", onClientStartMission)
    AddEventHandler("onClientEndMission", onClientEndMission)

    AddEventHandler("onClientSpawnMarker", onClientSpawnMarker)

    AddEventHandler("onClientPopulateWaypoints", onClientPopulateWaypoints)

    AddEventHandler("removeDebugWaypoints", removeDebugWaypoints)
    --AddEventHandler("onClientRemoveMissionMarkers", onClientRemoveMissionMarkers) not implemented yet

    AddEventHandler("onClientSetNavigationToWaypoint", spawnDestinationWaypoint)

    gameplay_rawPois.getRawPoiListByLevel = getRawPoiListByLevel -- TODO: have a look at this and fix

    
    --freeroam_bigMapPoiProvider.requestMissionLocationsForMinimap = sendToApp -- TODO: same for this
    log("I", "carp_poi", "onExtensionLoaded")
end

local function onExtensionUnloaded()
  --ocationsToMinimap =
  --  original_sendMissionLocationsToMinimap and original_sendMissionLocationsToMinimap
  log("I", "carp_poi", "onExtensionUnloaded")
end

M.deleteMissionGroup = deleteMissionGroup
M.carpSpawnWaypoint = carpSpawnWaypoint
M.getDisplayName = getDisplayName
M.sendToApp = sendToApp
M.deleteObjectByName = deleteObjectByName
M.getRawPoiListByLevel = getRawPoiListByLevel -- TODO: also this

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M
