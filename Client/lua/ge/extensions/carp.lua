local M = {}

local gui_module = require("ge/extensions/editor/api/gui")
local gui = {setupEditorGuiTheme = nop}
local im = ui_imgui

local carpAnticheatBlock = false
local carpNodeBlock = true
local carpAllowedToUnblockNode = true
local currentNodeStrength = 0
local carpLocalStrength = 30
local carpYourselfStrength = 10
local nodegrabUnlockTime = 25
local nodegrabCooldown = 60
local currentlyViewedVehicle = nil

local timeElapsed = 0

local currentMission = {}
local missionVehicleWeight = nil
local inventoryVehicleWeight = nil
local weightsApplied = true
local customRoles = {}
local resetDuringMission = true
local dSync = 0
local currentIsOwned = true
local compRI = 0
local compRIMission = 0

local enableResetsForTrailers = false

local currentVehiclePower = nil
local currentVehicleWeight = nil

local MISSION_TRIGGER_AUTO_FINISH_SPEED = 9.72 -- 35km/h

local traderOwners = nil

window_scale = 1.0

-- string in the format "x|y|z" coming from carp_passengers
local maximumGees = ""

local lastRanTimer = {nodeGrabDisable = 0, serverHeartbeat = 0, nodeGrabMsg = 0, unblockNode = 0, missionStartTimer = 0}
local timerDeltas = {
  -- updateHomePosition = 0,
  preventReset = 0,
  checkForClosestTrader = 0,
  requestTraderOwners = 0,
  hasAppliedWeights = 0,
  savedSynchro = 0
}
local updateRates = {
  -- updateHomePosition = 0.5,
  preventReset = 2,
  checkForClosestTrader = 2,
  requestTraderOwners = 10,
  hasAppliedWeights = 1,
  savedSynchro = 3
}
local customRoleTable = {
  CarpDev = {
    tag = "Carp Dev",
    shorttag = "Dev",
    red = 18,
    green = 142,
    blue = 18
  },
  CarpStaff = {
    tag = "Carp Staff",
    shorttag = "Staff",
    red = 255,
    green = 51,
    blue = 153
  }
}

function splitString(s, delimiter)
  local result = {}
  delimiter = delimiter or " "
  for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

local function requestTraderOwners()
  TriggerServerEvent("requestTraderOwners", "")
end

local function receiveTraderOwners(payload)
  if not payload or payload == "null" then -- added a check to stop error spam, no idea why this doesn't work TODO: fix??
    return
  end
  traderOwners = jsonDecode(payload)
end

local function getTraderOwners()
  return traderOwners
end

function distance3d(a, b)
  if not a or not a[1] or not a[2] or not a[3] or not b or not b[1] or not b[2] or not b[3] then
    print("ERROR", 'invalid coordinate table passed to "distance3d()"', a, b, simpletraceback())
    return 0
  end

  local x = a[1] - b[1]
  local y = a[2] - b[2]
  local z = a[3] - b[3]

  return math.sqrt(x * x + y * y + z * z)
end

function safeTraverse(base, ...)
  local t = base
  for k, v in ipairs {...} do
    t = t[v]
    if t == nil then
      return nil, tostring(v) .. " is nil"
    end
  end
  return t
end

function truncateNumber(number, places)
  if not number then
    return 0
  end

  local pattern = "%." .. (places or 3) .. "f"

  return tonumber(string.format(pattern, number))
end

function playCarpSound(soundName, volume)
  Engine.Audio.playOnce("AudioGui", soundName, {volume = volume or carp_ui_base.getUISetting("sfx_volume")})
end

local function showMessage(msg, duration, useBiggerText)
  if useBiggerText ~= true then
    useBiggerText = false
  end
  guihooks.trigger("ScenarioFlashMessage", {{msg, duration}})
end

local function hasTrailerMission()
  return currentMission and currentMission.special and currentMission.special.vehicleName
end

local function updateEngineStat(gameVehicleID, statName, value)
  carp_vehicle.updateEngineStat(gameVehicleID, statName, value)
end

local function setInventoryVehicleWeight(incomingWeight)
  inventoryVehicleWeight = incomingWeight

  weightsApplied = false
end

local function updateCompRi(vehID, cpri, cprim)
  if MPVehicleGE and MPVehicleGE.isOwn(vehID) then
    compRI = cpri
    compRIMission = cprim
  end
end

local function compRiErase()
  local veh = be:getPlayerVehicle(0)
  if not veh then
    return
  end
  veh:queueLuaCommand("if carp then carp.comprierase() end")
end

local function compRiMissionErase()
  local veh = be:getPlayerVehicle(0)
  if not veh then
    return
  end
  veh:queueLuaCommand("if carp then carp.compriMissionErase() end")
end

local function onClientReceiveBalance(data)
  ui_message("Your balance is: $" .. data, 10, "carpBalance", "attach_money")
end

local function requestVehiclePowerWeight(vehID)
  local veh = be:getPlayerVehicle(0)
  if not veh then
    return
  end

  veh:queueLuaCommand("carp.updateVehiclePowerWeight()")
end

local function updateVehiclePowerWeight(power, weight)
  currentVehiclePower = tonumber(power)
  currentVehicleWeight = tonumber(weight)

  TriggerServerEvent("receiveUpdatePowerWeight", currentVehiclePower .. "|" .. currentVehicleWeight)
end

local function getVehicleWeight()
  return currentVehicleWeight
end

local function handlePassengerMissionEnablement(decodedData)
  ------- passenger G-Force reset -------
  be:getPlayerVehicle(0):queueLuaCommand("carp_passengers.resetMaxGees()")

  -- if not passengerMission, disable recording stats
  if decodedData == "false" or decodedData == nil or decodedData == "" then
    be:getPlayerVehicle(0):queueLuaCommand("carp_passengers.setActive(false)")

    return
  end

  -- if normal passenger mission, enable g-force recording
  if decodedData == "normal" then
    be:getPlayerVehicle(0):queueLuaCommand("carp_passengers.setActive('normal')")
    carp_passengers.enable()
  elseif decodedData == "excitement" then
    -- if excitement passengerMission, use drift popup
    be:getPlayerVehicle(0):queueLuaCommand("carp_passengers.setActive('excitement')")
    carp_passengers.enable(true)
  end
end

local function handleVehicleWeight(decodedData)
  local numOfPassengers = decodedData.numOfPassengers

  local veh = be:getPlayerVehicle(0)
  if not veh then
    return
  end

  ------- dynamic weight -------
  if decodedData.passengerMission and decodedData.passengerMission ~= "false" then
    veh:queueLuaCommand("carp_dynamicWeight.setSeatWeights(nil," .. numOfPassengers .. ")")
  else
    if decodedData.playerVehicleCargo or decodedData.playerVehicleCargoWeight then
      missionVehicleWeight = decodedData.playerVehicleCargoWeight or decodedData.playerVehicleCargo or 0 -- TODO: figure out why there's two of these?
      local totalWeight = tonumber(missionVehicleWeight) + (inventoryVehicleWeight or 0)

      veh:queueLuaCommand("carp_dynamicWeight.setCargoWeights(" .. tostring(totalWeight) .. ")")
    end
  end
end

local function requestVehicleWeightUpdate()
  local veh = be:getPlayerVehicle(0)
  if not veh then
    return
  end

  local totalWeight = (missionVehicleWeight or 0) + (inventoryVehicleWeight or 0)

  be:getPlayerVehicle(0):queueLuaCommand(
    "if carp_dynamicWeight then carp_dynamicWeight.resetWeights() carp_dynamicWeight.setCargoWeights(" ..
      tostring(totalWeight) .. ") end"
  )
end

local function onClientStartMission(missionData)
  local decodedData = jsonDecode(missionData)

  resetDuringMission = false

  compRiErase()
  compRiMissionErase()
  currentMission = decodedData

  carp_passengers.disable(true)

  if hasTrailerMission() then
    enableResetsForTrailers = true
    lastRanTimer.missionStartTimer = lastRanTimer.missionStartTimer + 2
    local trailer =
      core_vehicles.spawnNewVehicle(
      currentMission.special.vehicleName,
      {config = currentMission.special.configName.config, autoEnterVehicle = false}
    )
    currentVehicles.trailer = {gameVehicleID = trailer:getID()}
    trailer:queueLuaCommand('input.event("parkingbrake", 1)')
  end

  if decodedData.missionMessage and decodedData.missionMessage ~= "" then
    showMessage(decodedData.missionMessage, 5, false)
    UIGlobal_MissionDescription = decodedData.missionMessage
  else
    showMessage("You have a mission! Go!", 5, false)
  end

  handlePassengerMissionEnablement(decodedData.passengerMission)
  handleVehicleWeight(decodedData)

  Engine.Audio.playOnce("AudioGui", "audio/recalculating_route.ogg")
end

local function deleteMissionDestinationMarker()
  carp_poi.deleteObjectByName("mission-delivery-destination_icon")
  carp_poi.deleteObjectByName("mission-delivery-destination_marker")
  carp_poi.deleteObjectByName("mission-delivery-destination_trigger")
end

local function onClientEndMission()
  carp_vehicle.removeTrailerVehicle()

  Engine.Audio.playOnce("AudioGui", "event:UI_CountdownGo")
  compRiErase()
  compRiMissionErase()

  UIGlobal_MissionDescription = nil

  -- i hate to do it this way, but it works, so..
  resetDuringMission = true

  local veh = be:getPlayerVehicle(0)
  if veh then
    veh:queueLuaCommand("carp_passengers.setActive(false)")
  end

  -- remove mission weight after mission done
  missionVehicleWeight = nil
  requestVehicleWeightUpdate()

  carp_passengers.disable()

  currentMission = {}

  deleteMissionDestinationMarker()
end

local function receiveOnAbandonCheck()
  local paxData = carp_passengers.getPassengerMissionData()
  local isFun = paxData.isExciteMission
  local score = paxData.excitementScore
  local paxCount = paxData.paxCount

  TriggerServerEvent("receivedAbandonCheck", tostring(isFun) .. "|" .. score .. "|" .. paxCount)
end

local function onClientReceiveUIMessage(message)
  showMessage(message, 4, false)
end

local function onExtensionUnloaded()
  print("[CaRP Client <><] Unloaded!")

  -- Lua:requestReload()
  --reloadUI()
end

local function ePress(vehID, ePressed)
  if not MPVehicleGE.isOwn(vehID) then
    return
  end

  if ePressed then
    M.sendMissionRequest()
  else
  end
end

local function syncWaypoint()
  dSync = core_groundMarkers.getPathLength()
  --local dSync, err = safeTraverse(core_groundMarkers, "routePlanner", "path", 1, "distToTarget")
end

local function blockIllegalKeybinds()
  -- core_input_actionFilter.setGroup("carpBlockWorldEdit", {"editorToggle", "editorSafeModeToggle", "toggleWalkingMode"})
  be:setDynamicCollisionEnabled(true)
  -- core_input_actionFilter.addAction(0, "carpBlockWorldEdit", true)
  core_input_actionFilter.setGroup("carpBlockAdjustStrength", {"nodegrabberStrength"})
  core_input_actionFilter.setGroup(
    "carpBlockWorldEdit",
    {
      "editorToggle",
      "editorSafeModeToggle",
      "toggleWalkingMode",
      "dropPlayerAtCamera",
      "dropPlayerAtCameraNoReset",
      "funBreak",
      "funHinges"
    }
  )
  core_input_actionFilter.addAction(0, "carpBlockWorldEdit", true)
  core_input_actionFilter.setGroup("carpBlockAdjustStrength", {"nodegrabberStrength"})
  core_input_actionFilter.addAction(0, "carpBlockAdjustStrength", true)

  core_input_actionFilter.setGroup(
    "carpBlockFreecam",
    {"toggleCamera", "moveforward", "movebackward", "moveleft", "moveright", "moveup", "movedown"}
  )

  core_input_actionFilter.setGroup(
    "carpBlockReset",
    {
      "reset_physics",
      "reset_all_physics",
      "recover_vehicle_alt",
      "recover_to_last_road",
      "funBreak",
      "funHinges",
      "funTires",
      "couplersLock",
      "funRandomTire",
      "funFire",
      "funExtinguish",
      "funBoom",
      "forceField",
      "loadHome"
    }
  )
  core_input_actionFilter.addAction(0, "carpBlockReset", true)
end

local function setNodegrabCameraRestrictions(enabled)
  if enabled then
    core_input_actionFilter.addAction(0, "carpBlockFreecam", true)
    core_camera.setMaxDistance(carp_vehicle.getPlayerVehicleID(), 11)

    if commands then
      commands.setGameCamera()
    end
  else
    core_input_actionFilter.addAction(0, "carpBlockFreecam", false)

    core_camera.setMaxDistance(carp_vehicle.getPlayerVehicleID(), nil)
  end
end

local function updateMaxGees(string)
  maximumGees = string
end

local function toggleBlockReset()
  core_input_actionFilter.setGroup(
    "carpBlockReset",
    {
      "reset_physics",
      "recover_vehicle",
      "recover_vehicle_alt"
    }
  )

  core_input_actionFilter.addAction(0, "carpBlockReset", carpAnticheatBlock)
end

local function toggleBlockNodes()
  core_input_actionFilter.setGroup(
    "carpBlockNodes",
    {
      "nodegrabberAction",
      "nodegrabberGrab",
      "nodegrabberRender"
    }
  )
  core_input_actionFilter.setGroup(
    "carpBlockCamera",
    {
      "changeCameraSpeed",
      "movefast"
    }
  )

  -- unblock node grabbing, block camera speed adjustment
  if (carpNodeBlock == false) then
    core_input_actionFilter.addAction(0, "carpBlockNodes", false)
    core_input_actionFilter.addAction(0, "carpBlockCamera", true)
    setConsoleVariable("$Camera::movementSpeed", 14)
  else
    core_input_actionFilter.addAction(0, "carpBlockNodes", true)
    core_input_actionFilter.addAction(0, "carpBlockCamera", false)
    be.nodeGrabber:addStrength(-100)
    setConsoleVariable("$Camera::movementSpeed", 20)
  end
end

local function toggleSpeedChecks(inputVal)
  carpAnticheatBlock = inputVal

  toggleBlockReset()
  toggleBlockNodes()

  if (inputVal == false) then
    -- also run the damage check and fuel send every time they drop below the reset speed
    --getDamageStats()
    carp_vehicle.sendFuel()
  end
end

local function enableNodegrab(theHelp)
  if (theHelp == "yourself") then
    lastRanTimer.nodeGrabMsg = timeElapsed + nodegrabUnlockTime
    lastRanTimer.unblockNode = timeElapsed + nodegrabUnlockTime + nodegrabCooldown
    carpNodeBlock = false
    currentNodeStrength = carpYourselfStrength
    TriggerServerEvent("genericMessageSender", "Good luck pushing it yourself!")
    toggleBlockNodes()

    setNodegrabCameraRestrictions(true)
  elseif (carpAllowedToUnblockNode) then
    lastRanTimer.nodeGrabMsg = timeElapsed + nodegrabUnlockTime
    lastRanTimer.unblockNode = timeElapsed + nodegrabUnlockTime + nodegrabCooldown
    carpNodeBlock = false
    carpAllowedToUnblockNode = false
    currentNodeStrength = carpLocalStrength
    TriggerServerEvent("payForNodegrabbing", "herpderp")
    toggleBlockNodes()
  else
    TriggerServerEvent(
      "genericMessageSender",
      "Sorry! The locals are still tired from helping you last time! Try again later."
    )
  end
  TriggerServerEvent("handleNodegrab", theHelp)
end

local function showRaceStartPopup(data)
  if MPVehicleGE.isOwn(data.subjectID) then
    if (data.event == "enter") then
      TriggerServerEvent("receiveRaceMenuRequest", stringToTable(data.triggerName, "_")[1])
    end
    carp_ui_race.showWindow(data.event ~= "exit")
  end
end

local function showGasStationPopup(data)
  if MPVehicleGE.isOwn(data.subjectID) then
    carp_ui_gasstation.showGasStationUI(data.event ~= "exit", carp_poi.getDisplayName(data.triggerID))
  end
end

local function showChargingStationPopup(data)
  if MPVehicleGE.isOwn(data.subjectID) then
    carp_ui_chargingstation.showChargingStationUI(data.event ~= "exit", carp_poi.getDisplayName(data.triggerID))
  end
end

local function fadeMarker(triggerName, isEnter)
  if not triggerName then
    return
  end

  local markerName = stringToTable(triggerName, "_")[1] .. "_marker"
  local markerObj = scenetree.findObject(markerName)

  local markerColor = tostring(markerObj.instanceColor)
  local markerColorTable = stringToTable(markerColor, ", ")
  local colorR = markerColorTable[1] .. " "
  local colorG = markerColorTable[2] .. " "
  local colorB = markerColorTable[3] .. " "

  local newAlpha = (isEnter and "0.2") or "1"
  print("isEnter is", isEnter, ". setting alpha to:", newAlpha)

  local newColorString = "" .. colorR .. colorG .. colorB .. newAlpha

  markerObj:setField("instanceColor", 0, newColorString)
  markerObj:updateInstanceRenderData()
end

local function attemptToDeliverMissionItems()
  TriggerServerEvent("attemptToDeliverItems", "")
end

local function showDestinationPopup(data)
  if MPVehicleGE.isOwn(data.subjectID) then
    if data.event == "enter" then
      carp_ui_gigdestination.showGigDestinationPopup(true)

      if
        carp_ui_base.getUISetting("mission_auto_complete") and
          be:getPlayerVehicle(0):getVelocity():length() <= MISSION_TRIGGER_AUTO_FINISH_SPEED
       then
        carp.sendMissionRequest()
      end
    elseif data.event == "exit" then
      carp_ui_gigdestination.showGigDestinationPopup(false)
    end
  end
end

local function showGaragePopup(data)
  if MPVehicleGE.isOwn(data.subjectID) then
    if data.event == "enter" then
      carp_ui_garage.showGaragePopup(true, carp_poi.getDisplayName(data.triggerID))

      print("called fadeMarker for enter")
      fadeMarker(data.triggerName, true)
    elseif data.event == "exit" then
      carp_ui_garage.showGaragePopup(false)

      print("called fadeMarker for exit")
      fadeMarker(data.triggerName, false)

      if MPVehicleGE.sendPendingVehicleEdits then
        MPVehicleGE.sendPendingVehicleEdits()
      else
        carp_vehicle.exitedGarage(data.subjectID)
      end
    end
  end
end

local function showDriftPopup(data)
  if carp_ui_passenger ~= nil then
    carp_passengers.showDriftPopup(true)
  end
end

local function requestTraderInfo(data)
  if not MPVehicleGE.isOwn(data.subjectID) then
    return
  end

  local playerVeh = be:getPlayerVehicle(0)

  local currentlyLoadedTraderName = carp_ui_trader.getCurrentTraderName()
  local triggerWaypointName = stringToTable(data.triggerName, "_")[1]

  if (data.event == "enter") then
    if not currentlyLoadedTraderName or currentlyLoadedTraderName ~= triggerWaypointName then
      TriggerServerEvent("receiveContactMenuRequest", triggerWaypointName)

      playerVeh:queueLuaCommand("carp.enableTrailerPreview(true)")
    end
  elseif (data.event == "exit") then
    carp_ui_trader.clearInventory()
    carp_ui_vehicleinventory.clearCurrentLocation()

    playerVeh:queueLuaCommand("carp.enableTrailerPreview(false)")
  end
end

local function enteredDealership(data)
  if MPVehicleGE.isOwn(data.subjectID) then
    TriggerServerEvent("requestOwnedVehicles", "owo")
    carp_ui_dealership.showWindow(data.event == "enter", carp_poi.getDisplayName(data.triggerID))
  end
end

local function arrivedAtDestination()
  attemptToDeliverMissionItems()
end

local function heartbeatCheck()
  if MPGameNetwork.launcherConnected() then
    TriggerServerEvent("ClientHeartbeatCheckin", "a")
    reenableInstabilityPause()
  end
end

local function checkForDisableNodeGrab(anticheatEnabled)
  local vehicle = carp_vehicle.getPlayerVehicle()
  local airspeed = math.abs((vehicle:getVelocity() or vec3()):length()) or 0

  if (airspeed > 5 and not anticheatEnabled) then
    M.toggleSpeedChecks(true)
  elseif (airspeed < 5 and anticheatEnabled) then
    M.toggleSpeedChecks(false)
  end
end

-- handles the receiveHandlePlayerGetPosition event
local function sendMissionRequest()
  if not carp_vehicle.getPlayerVehicleID() or not MPVehicleGE.isOwn(carp_vehicle.getPlayerVehicleID()) then
    return
  end

  local vehiclePosition = carp_vehicle.getVehiclePosition()

  local payload = {}
  payload.x = vehiclePosition.x
  payload.y = vehiclePosition.y
  payload.z = vehiclePosition.z

  -- lets use the average of the trailer position and player position instead if we have a trailer mission
  if hasTrailerMission() and carp_vehicle.getTrailerVehicleID() then
    local trailerVehId = carp_vehicle.getTrailerVehicleID()
    local trailerPosition = be:getObjectByID(trailerVehId):getPosition()

    --local vehiclePosition2d = vehiclePosition:z0()
    --local trailerPosition2d = trailerPosition:z0()
    --local trailerDistance = vehiclePosition2d:distance(trailerPosition2d)
    local trailerDistance = vehiclePosition:distance(trailerPosition)

    local avgPosX = (vehiclePosition.x + trailerPosition.x) / 2
    local avgPosY = (vehiclePosition.y + trailerPosition.y) / 2
    local avgPosZ = (vehiclePosition.z + trailerPosition.z) / 2

    -- if trailer distance is too far, set z arbitrarily high so it fails the check
    if (trailerDistance > 15) then
      avgPosZ = "300"
    end

    payload.x = avgPosX
    payload.y = avgPosY
    payload.z = avgPosZ
  end

  if compRI and compRI ~= 0 then
    payload.compRI = compRI
  end

  if compRIMission and compRIMission ~= 0 then
    if dSync and dSync > 0 then
      payload.dSync = dSync
    else
      payload.compRIMission = compRIMission
    end
  end

  local excitementScore = carp_passengers.getDriftScore()
  payload.excitementScore = excitementScore

  payload.resetDuringMission = resetDuringMission
  payload.maximumGees = maximumGees

  payload = jsonEncode(payload)
  payload = payload:gsub(":", "=")

  TriggerServerEvent("receiveHandlePlayerGetPosition", payload)
end

local function getCurrentMission()
  return deepcopy(currentMission)
end

local function saveSynchroToFile(playerVehicle)
  local vehicleName = playerVehicle.JBeam

  playerVehicle:queueLuaCommand("carp_persistence.saveSynchroToFile('" .. vehicleName .. "')")
end

local function onUpdate(dtReal, dtSim, dtRaw)
  timeElapsed = timeElapsed + dtReal

  local playerVehicle = be:getPlayerVehicle(0)

  for k, v in pairs(timerDeltas) do
    timerDeltas[k] = timerDeltas[k] + dtReal
  end

  if timerDeltas.requestTraderOwners > updateRates.requestTraderOwners and playerVehicle then
    timerDeltas.requestTraderOwners = 0

    requestTraderOwners()
  end

  if timerDeltas.savedSynchro > updateRates.savedSynchro and playerVehicle then
    timerDeltas.savedSynchro = 0

    saveSynchroToFile(playerVehicle)
  end

  -- this probably does not even work.
  --[[ if timerDeltas.updateHomePosition > updateRates.updateHomePosition and playerVehicle then
    timerDeltas.updateHomePosition = 0

    if MPVehicleGE.isOwn(playerVehicle:getId()) then
      playerVehicle:queueLuaCommand("recovery.saveHome()")
    end
  end ]]
  if timerDeltas.preventReset > updateRates.preventReset then
    resetGameplay = function(x, y, z)
      print("youre welcome")
    end
    spawn.teleportToLastRoad = function(x, y, z)
      print("youre welcome")
    end

    local playerVeh = playerVehicle
    if playerVeh then
      playerVeh:queueLuaCommand("if recovery then recovery.loadHome = function(x,y,z) return end end")
    end
  end

  if timerDeltas.hasAppliedWeights > updateRates.hasAppliedWeights then
    timerDeltas.hasAppliedWeights = 0

    if not weightsApplied and playerVehicle then
      weightsApplied = true

      local totalWeight = tonumber(missionVehicleWeight or 0) + tonumber(inventoryVehicleWeight or 0)
      totalWeight = tostring(totalWeight)

      playerVehicle:queueLuaCommand("carp_dynamicWeight.setCargoWeights(" .. totalWeight .. ")")
    end
  end

  -- TODO move to groundmarker?
  if currentMission.missionDestination and (not dSync or dSync == 0) then
    syncWaypoint()
  end

  -- nodegrab timer
  if timeElapsed - lastRanTimer.nodeGrabDisable > 1 then
    lastRanTimer.nodeGrabDisable = timeElapsed

    if currentlyViewedVehicle and currentlyViewedVehicle == carp_vehicle.getPlayerVehicleID() then
      checkForDisableNodeGrab(carpAnticheatBlock)
    end
    if (carpNodeBlock == false) then
      be.nodeGrabber:addStrength(-100)
      be.nodeGrabber:addStrength(currentNodeStrength)
    end
  end

  if timeElapsed - lastRanTimer.missionStartTimer > 2 then
    lastRanTimer.missionStartTimer = timeElapsed
    enableResetsForTrailers = false
  end

  if timeElapsed - lastRanTimer.serverHeartbeat > 5 then
    lastRanTimer.serverHeartbeat = timeElapsed
    heartbeatCheck() -------- heartbeat shit
  end

  if (timeElapsed > lastRanTimer.nodeGrabMsg and carpNodeBlock == false) then
    if (currentNodeStrength == carpLocalStrength) then
      TriggerServerEvent("genericMessageSender", "Looks like the locals got tired and went home.")
    else
      TriggerServerEvent("genericMessageSender", "You're exhausted from all that pushing.")
    end
    carpNodeBlock = true
    setNodegrabCameraRestrictions(false)
    toggleBlockNodes()
  end

  if (timeElapsed > lastRanTimer.unblockNode and carpAllowedToUnblockNode == false) then
    carpAllowedToUnblockNode = true
  end

  if timeElapsed >= 20 then
    timeElapsed = 0

    lastRanTimer.nodeGrabDisable = lastRanTimer.nodeGrabDisable - 20

    lastRanTimer.missionStartTimer = lastRanTimer.missionStartTimer - 20

    if (carpNodeBlock == false) then
      lastRanTimer.nodeGrabMsg = lastRanTimer.nodeGrabMsg - 20
    end
    if (carpAllowedToUnblockNode == false) then
      lastRanTimer.unblockNode = lastRanTimer.unblockNode - 20
    end
  end
end

function reenableInstabilityPause()
  settings.setValue("disableInstabilityPausing", false)
  settings.impl.invalidateCache()
end

local function stopBigMapTeepee() -- hehe peepee
  if freeroam_bigMapMode then
    -- remove ability to tele on map
    freeroam_bigMapMode.teleportToPoi = function(x, y, z)
      print("no teleporting! ;)")
    end
    freeroam_bigMapMode.teleportToSpawnPoint = function(x, y, z)
      print("no teleporting! ;)")
    end
    freeroam_bigMapMode.teleportToMission = function(x, y, z)
      print("no teleporting! ;)")
    end
    freeroam_bigMapMode.teleportToGarage = function(x, y, z)
      print("no teleporting! ;)")
    end
  end
end

local function teleportToClosestGarage()
  local garageGroup = scenetree.CarprepairgarageTriggersGroup
  if not garageGroup then
    print("couldnt find CarprepairgarageTriggersGroup")
  end

  local garageObjects = garageGroup:getObjects()
  if not garageObjects then
    print("couldnt find garageObjects")
  end

  local playerVeh = be:getPlayerVehicle(0)
  local vehPosition = playerVeh:getPosition()
  local vehPositionFormatted = {
    [1] = vehPosition.x,
    [2] = vehPosition.y,
    [3] = vehPosition.z
  }

  local shortestDistance = 999999999999999999
  local shortestDistanceName

  for _, objectName in pairs(garageObjects) do
    if objectName:endsWith("_icon") then
      local objectPosition = scenetree.findObject(objectName):getPosition()

      local objectPositionFormatted = {
        [1] = objectPosition.x,
        [2] = objectPosition.y,
        [3] = objectPosition.z
      }

      local distance = distance3d(objectPositionFormatted, vehPositionFormatted)

      if distance < shortestDistance then
        shortestDistance = distance
        shortestDistanceName = objectName
      end
    end
  end

  if shortestDistanceName then
    local destination = scenetree.findObject(shortestDistanceName)

    if destination and MPVehicleGE.isOwn(playerVeh:getId()) then
      local destinationPos = destination:getPosition()
      destinationPos.z = destinationPos.z - 5

      playerVeh:setPosition(destinationPos)

      carp_ui_fallingthruworld.showWindow(false)
    end
  end
end

local function teleportToRandomGarage()
  local garageGroup = scenetree.CarprepairgarageTriggersGroup
  if not garageGroup then
    print("couldnt find CarprepairgarageTriggersGroup")
  end

  local garageObjects = garageGroup:getObjects()
  if not garageObjects then
    print("couldnt find garageObjects")
  end

  local playerVeh = be:getPlayerVehicle(0)
  if not playerVeh then
    return
  end

  local validDestinations = {}
  for _, objectName in pairs(garageObjects) do
    if objectName:endsWith("_icon") then
      table.insert(validDestinations, objectName)
    end
  end

  local chosenGarage = validDestinations[math.random(1, #validDestinations)]

  if chosenGarage then
    local destination = scenetree.findObject(chosenGarage)

    if destination and MPVehicleGE.isOwn(playerVeh:getId()) then
      local destinationPos = destination:getPosition()
      destinationPos.z = destinationPos.z - 5

      playerVeh:setPosition(destinationPos)

      carp_ui_fallingthruworld.showWindow(false)
    end
  end
end

local function loadSynchroFromFile(playerVehicle)
  if not playerVehicle then
    return
  end
  local vehicleName = playerVehicle.JBeam

  playerVehicle:queueLuaCommand("carp_persistence.setSynchroWearFromSaved('" .. vehicleName .. "')")
end

local function clearSynchroWear()
  local playerVehicle = be:getPlayerVehicle(0)
  local vehicleName = playerVehicle.JBeam

  TriggerServerEvent("fixSynchro", "")
  playerVehicle:queueLuaCommand("carp_persistence.clearSynchroWear('" .. vehicleName .. "')")
  playCarpSound("audio/torque_wrench", 0.8)
end

local function attemptVehiclePurchase(vehicleName)
  local playerVehicle = be:getPlayerVehicle(0)
  if not playerVehicle then
    return
  end

  local playerVehiclePosition = playerVehicle:getPosition()
  if not playerVehiclePosition then
    return
  end

  local payload =
    playerVehiclePosition.x .. "|" .. playerVehiclePosition.y .. "|" .. playerVehiclePosition.z .. "|" .. vehicleName

  TriggerServerEvent("receiveAttemptVehiclePurchase", payload)
end

local function onSetPlayerTag(data)
  local tagData = jsonDecode(data)
  MPVehicleGE.setPlayerNickPrefix(tagData.name, tagData.source or "CaRP", tagData.text)
end

local function getIdToServerNew()
  local id = getHardwareID()

  if (id and id ~= "") then
    local payload = id
    TriggerServerEvent("getIDNew", payload)
  end
end
local function onClientReceiveVehicleInventory(inventoryString)
  local inventory = jsonDecode(inventoryString)

  carp_ui_vehicleinventory.updateInventory(inventory)
end

local function onClientReceiveGig(payload)
  if payload and payload ~= "" then
    TriggerServerEvent("receiveGetNavigationToWaypoint", payload)
  else
    carp_vehicleinventory.getLastInventoryMissionItem()
  end
end

local function receiveTiresHealth(payload)
  local splitPayload = stringToTable(payload, "|")

  -- carp_vehicle.updateTiresInfo(splitPayload[2])
end

local function receiveTowHitchStatus(payload)
  local veh = be:getPlayerVehicle(0)
  if not veh then
    return
  end

  veh:queueLuaCommand("if carp then carp.receiveTowHitchStatus('" .. payload .. "') end")
end

local function updateGasStationPrices(payload)
  if not payload then
    return
  end

  local asJson = jsonDecode(payload)
  if not asJson then
    return
  end

  carp_gasstationdisplays.updateGasStationPrices(asJson)
end

local function receiveCorporationData(payload)
  carp_corporation.receiveCorporationData(payload)
end

local function onClientUpdateRoles(payload)
  if not payload then
    return
  end
  if payload == null then
    return
  end
  if payload == "null" then
    return
  end

  local vehicleRoleTable = jsonDecode(payload)
  -- 0-1 : carpDev
  if not vehicleRoleTable then
    return
  end -- if there is nothing to set don't fail
  for vehicleID, roleIdentifier in pairs(vehicleRoleTable) do
    MPVehicleGE.setVehicleRole(vehicleID, roleIdentifier, 0)
  end
end

-- used on next function!
local function getPartsFromPCFiles()
  local vehiclefolders = FS:directoryList("/vehicles", false, true)

  for _, vf in pairs(vehiclefolders) do
    local carname = vf:gsub("vehicles/", ""):gsub("/", "")

    local partsFile = jsonReadFile("/parts/parts.json")

    local pcFiles = FS:findFiles(vf, "*.pc", 1, true, false)

    if pcFiles then
      for _, jf in pairs(pcFiles) do
        local p = jsonReadFile(jf)

        if p["parts"] then
          for partSlot, partName in pairs(p["parts"]) do
            if partName ~= "" and partName ~= "none" and partName ~= "None" then
              if not partsFile[partSlot] then
                partsFile[partSlot] = 100
              end

              if not partsFile[partName] then
                partsFile[partName] = 100
              end
            end
          end
        end
      end
    end

    jsonWriteFile("/parts/parts.json", partsFile)
  end
end

local function recursivePartFinder(parts, searchFolder)
  local dList = FS:directoryList(searchFolder, false, true)

  for _, vf in pairs(dList) do
    if (FS:directoryExists(vf)) then
      parts = recursivePartFinder(parts, vf)
    end
    local jbeams = FS:findFiles(vf, "*.jbeam", 1, true, false)

    for _, jf in pairs(jbeams) do
      local p = jsonReadFile(jf)
      if (p ~= nil) then
        for part, info in pairs(p) do
          if parts[part] then
          end

          parts[part] = info.information and info.information.value or 100
        end
      end
    end
  end

  return parts
end

local function getAllPartPricesRecursively()
  local parts = jsonReadFile("/parts/parts.json")
  parts = recursivePartFinder(parts, "/vehicles")

  jsonWriteFile("/parts/parts.json", parts)
  print("/parts/parts.json written.")
end

local getPricesForAllCommonVehicleParts = function()
  local vehiclefolders = FS:directoryList("/vehicles/common", false, true)

  local parts = jsonReadFile("/parts/parts.json")

  for _, vf in pairs(vehiclefolders) do
    local jbeams = FS:findFiles(vf, "*.jbeam", 1, true, false)

    for _, jf in pairs(jbeams) do
      local p = jsonReadFile(jf)

      for part, info in pairs(p) do
        if parts[part] and parts[part] > (info.information and info.information.value or -1) then
          print("PART ALREADY EXISTS! " .. part)
        else
          parts[part] = info.information and info.information.value or 100
        end
      end
    end
  end

  jsonWriteFile("/parts/parts.json", parts)
  print("/parts/parts.json written.")
end

local getPricesForAllVehicleParts = function()
  local vehiclefolders = FS:directoryList("/vehicles", false, true)

  local parts = jsonReadFile("/parts/parts.json") or {}

  local existingPartTotal = 0
  local newPartTotal = 0

  for _, vf in pairs(vehiclefolders) do
    local jbeams = FS:findFiles(vf, "*.jbeam", -1, true, false)
    for _, jf in pairs(jbeams) do
      local p = jsonReadFile(jf)

      if p then
        for part, info in pairs(p) do
          if parts[part] and parts[part] > (info.information and info.information.value or -1) then
            existingPartTotal = existingPartTotal + 1
            print("PART ALREADY EXISTS! " .. part .. " - " .. (info.information and info.information.value or "nil"))
          else
            parts[part] = info.information and info.information.value or 100
            newPartTotal = newPartTotal + 1
          end
        end
      end
    end
  end

  jsonWriteFile("/parts/parts.json", parts)
  print("/parts/parts.json written.")
  print(existingPartTotal .. " parts already existed.")
  print(newPartTotal .. " parts were added.")

  --getPartsFromPCFiles()
end

local function saveVehicleParts()
  local playerVehicle = be:getPlayerVehicle(0)
  local vehManager = extensions.core_vehicle_manager
  jsonWriteFile("/vehicleParts/" .. playerVehicle.JBeam .. ".json", vehManager.getPlayerVehicleData().chosenParts)
end

local function getNearestPOI(type)
  if not type then
    return
  end

  local group = nil
  local color = {0.1, 0.25, 0.5}

  if type == "gas" then
    group = scenetree.CarpgasstationTriggersGroup
    color = {0.6, 0.5, 1}
  elseif type == "charger" then
    group = scenetree.CarpchargingstationTriggersGroup
    color = {0.01, 0.92, 0.98}
  elseif type == "cardealership" then
    group = scenetree.CarpcardealershipTriggersGroup
    color = {0.85, 0.2, 0.85}
  elseif type == "garage" then
    group = scenetree.CarprepairgarageTriggersGroup
    color = {0.1, 1, 0.3}
  elseif type == "contact" then
    group = scenetree.CarpcontactTriggersGroup
    color = {1, 0.6, 0}
  elseif type == "race" then
    color = {1, 0.3, 0}
  end

  if not group then
    log("E", "getNearestPOI", 'Could not find group "' .. type .. '"')
    return
  end

  local triggers = group:getObjects()

  if triggers == nil or #triggers == nil or #triggers == 0 then
    return
  end

  local playerVehicle = be:getPlayerVehicle(0)
  local playerVehiclePosition = playerVehicle:getPosition()

  local nearestWaypoint = vec3(0, 0, 0)
  local nearestNode = ""
  local shortestDistance = 999999999

  for _, name in pairs(triggers) do
    local testLocation = group:findObject(name):getPosition()
    local dist, lastNodeName = carp_groundmarkers.getPointToPointDistance(playerVehiclePosition, testLocation)

    if dist < shortestDistance then
      shortestDistance = dist
      nearestWaypoint = testLocation
      nearestNode = lastNodeName
    end
  end

  if shortestDistance == 999999999 then -- none found i guess
    return
  end

  carp_groundmarkers.setDestination(nearestWaypoint, color, true)
end

M.savespot = function(inputName, inputOffroad, inputProlicense, inputPassenger)
  local pos = be:getObject(0):getPosition()

  local location = pos.x .. "|" .. pos.y .. "|" .. pos.z
  local name = inputName
  local locName = string.gsub(name, " ", "-")
  locName = locName:lower()
  local provide = ""
  local request = ""
  local restriction = ""
  local prolicense = inputProlicense or "true"
  local offroad = inputOffroad or "true"
  local passenger = inputPassenger or "true"

  local payload = {
    name = name,
    location = location,
    provide = provide,
    request = request,
    restriction = restriction,
    prolicense = prolicense,
    offroad = offroad,
    passenger = passenger
  }

  local f = jsonReadFile("waypoints.json") or {}
  local mapname = getMissionFilename()
  f[mapname] = f[mapname] or {}
  f[mapname][locName] = f[mapname][locName] or {}
  table.insert(f[mapname][locName], payload)
  jsonWriteFile("waypoints.json", f)
end

function uiTextColoredWithFont(color, text, fontName)
  if fontName then
    im.PushFont3(fontName)
  end

  if not color then
    im.Text(text)
  else
    im.TextColored(color or im.GetStyleColorVec4(im.Col_Text), text)
  end

  if fontName then
    im.PopFont()
  end
end

-- maps a number into an exponential curve
function getExponentialValue(inputValue, maxValue, startingValue, speed)
  local resSpeed = speed or 0.05
  local resMaxValue = maxValue or 100
  local resStartingValue = startingValue or 0
  return resMaxValue - (resMaxValue - resStartingValue) * math.exp(-resSpeed * inputValue)
end

local function mapNumberToRange(number, startingMin, startingMax, resultMin, resultMax, clamp)
  if clamp and number < startingMin then
    return resultMin
  end

  if clamp and number > startingMax then
    return resultMax
  end

  return (number - startingMin) / (startingMax - startingMin) * (resultMax - resultMin) + resultMin
end

function tableContainsValue(tbl, val)
  for k, v in pairs(tbl) do
    if v == val then
      return k
    end
  end
  return false
end

function string:endsWith(ending)
  return ending == "" or self:sub(-(#ending)) == ending
end

local function onExtensionLoaded()
  reenableInstabilityPause()
  if MPCoreNetwork then
    AddEventHandler("clientCommandReceiver", sendMissionRequest)

    AddEventHandler("onClientStartMission", onClientStartMission)
    AddEventHandler("onClientEndMission", onClientEndMission)
    AddEventHandler("onClientReceiveBalance", onClientReceiveBalance)
    AddEventHandler("receiveTowHitchStatus", receiveTowHitchStatus)
    AddEventHandler("attemptVehiclePurchase", attemptVehiclePurchase)
    AddEventHandler("onClientReceiveUIMessage", onClientReceiveUIMessage)
    AddEventHandler("onSetPlayerTag", onSetPlayerTag)
    AddEventHandler("onClientReceiveVehicleInventory", onClientReceiveVehicleInventory)
    AddEventHandler("onClientUpdateRoles", onClientUpdateRoles)
    AddEventHandler("receiveGasStationData", updateGasStationPrices)
    AddEventHandler("onClientReceiveGig", onClientReceiveGig)
    AddEventHandler("receiveCorporationData", receiveCorporationData)
    AddEventHandler("receiveOnAbandonCheck", receiveOnAbandonCheck)
    AddEventHandler("getPlayerIDNew", getIdToServerNew)
    AddEventHandler("receiveTiresHealth", receiveTiresHealth)
    AddEventHandler("receiveTraderOwners", receiveTraderOwners)

    -- remove ability to world edit and adjust node grab strength
    blockIllegalKeybinds()

    core_input_actionFilter.setGroup("carpBlockNodeStrength", {"nodegrabberStrength"})
    core_input_actionFilter.addAction(0, "carpBlockNodeStrength", true)

    if freeroam_bigMapMode then
      -- remove ability to tele on map
      freeroam_bigMapMode.teleportToPoi = function(x, y, z)
        print("no teleporting! ;)")
      end
      freeroam_bigMapMode.teleportToSpawnPoint = function(x, y, z)
        print("no teleporting! ;)")
      end
      freeroam_bigMapMode.teleportToMission = function(x, y, z)
        print("no teleporting! ;)")
      end
      freeroam_bigMapMode.teleportToGarage = function(x, y, z)
        print("no teleporting! ;)")
      end
    end

    toggleBlockNodes()
    be:setDynamicCollisionEnabled(true)

    print("[CaRP Client <><] Ready!")

    -- play easter egg sound on load?
    local rando = math.random(1, 100)

    if rando < 25 then
      playCarpSound("audio/get ready 2 carp.ogg", 1)
    end
    if rando >= 25 and rando <= 50 then
      playCarpSound("audio/welcome to the carp zone.ogg", 1)
    end

    if rando == 68 then
      playCarpSound("audio/koi-chan approved.ogg", 1)
    end

    if rando > 99 then
      local randomNumber = math.random(1, 9)
      local audioName = "audio/intro/" .. randomNumber .. ".ogg"

      playCarpSound(audioName, 2)
    end

    for roleName, role in pairs(customRoleTable) do
      MPVehicleGE.createRole(roleName, role.tag, role.shorttag, role.red, role.green, role.blue)
    end
  end

  if not MPCoreNetwork or not MPCoreNetwork.isLauncherConnected or not MPCoreNetwork.isLauncherConnected() then
    messageBox(
      "Multiplayer mod error",
      "Reopen the BeamMP launcher and wait until the BeamNG.drive launcher shows up. In the future, do not close BeamNG directly - use the ingame BeamMP 'Quit' button to disconnect from servers.",
      0,
      0
    )
    TorqueScriptLua.call("quit")
  end
end

local function onVehicleResetted(vehID, other)
  if not MPVehicleGE or not MPVehicleGE.isOwn(vehID) or not MPVehicleGE.getServerVehicleID(vehID) then
    return
  end

  stopBigMapTeepee()

  -- resetting during mission removes speed bonus, pass that info to server
  -- add check for if the trailer was reset at the start of the mission
  if (resetDuringMission == false) then
    if
      (currentVehicles.trailer == nil or
        not (currentVehicles.trailer.gameVehicleID == vehID and enableResetsForTrailers))
     then
      resetDuringMission = true
      TriggerServerEvent("receiveHandleAnyMissionAttemptedReset", "" .. vehID)
    end
  end

  blockIllegalKeybinds()
  reenableInstabilityPause()

  -- updates power/weight stats
  if (currentVehicles.trailer == nil or currentVehicles.trailer.gameVehicleID ~= vehID) then
    requestVehiclePowerWeight()
  end

  stopBigMapTeepee()

  be:setDynamicCollisionEnabled(true)

  local playerVehicle = be:getPlayerVehicle(0)
  loadSynchroFromFile(playerVehicle)

  weightsApplied = false
end

local function onVehicleSwitched(vehIDFrom, vehIDTo)
  currentlyViewedVehicle = vehIDTo
  reenableInstabilityPause()
  currentIsOwned = MPVehicleGE.isOwn(vehIDTo)

  be:setDynamicCollisionEnabled(true)

  local playerVehicle = be:getPlayerVehicle(0)
  loadSynchroFromFile(playerVehicle)
end

local function onVehicleDestroyed(vehID, other)
  be:setDynamicCollisionEnabled(true)
  reenableInstabilityPause()
  if vehID == carp_vehicle.getTrailerVehicleID() then
    return
  end

  stopBigMapTeepee()

  onVehicleResetted(vehID, other)
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.sendMissionRequest = sendMissionRequest
M.getPricesForAllVehicleParts = getPricesForAllVehicleParts
M.getPricesForAllCommonVehicleParts = getPricesForAllCommonVehicleParts
M.getAllPartPricesRecursively = getAllPartPricesRecursively
M.recursivePartFinder = recursivePartFinder
M.ePress = ePress
M.toggleSpeedChecks = toggleSpeedChecks
M.updateCompRi = updateCompRi
M.onVehicleResetted = onVehicleResetted
M.onVehicleSwitched = onVehicleSwitched
M.onVehicleDestroyed = onVehicleDestroyed
M.onUpdate = onUpdate
M.currentIsOwned = currentIsOwned
M.printVehicles = function()
  print("currentVehicles")
  dump(carp_vehicle.getCurrentVehicles())
  print("currently viewed vehicle")
  print(currentlyViewedVehicle)
end

--M.requestFood = requestFood -- does not exist
M.requestTraderInfo = requestTraderInfo
--M.receiveContactInfo = requestContactInfo -- does not exist

M.showGaragePopup = showGaragePopup
M.showDestinationPopup = showDestinationPopup
M.showGasStationPopup = showGasStationPopup
M.showChargingStationPopup = showChargingStationPopup
M.showRaceStartPopup = showRaceStartPopup
M.showDriftPopup = showDriftPopup

M.enteredDealership = enteredDealership
M.arrivedAtDestination = arrivedAtDestination
M.updateVehiclePowerWeight = updateVehiclePowerWeight
M.enableNodegrab = enableNodegrab
M.getNearestPOI = getNearestPOI
M.updateMaxGees = updateMaxGees
M.getPartsFromPCFiles = getPartsFromPCFiles
M.syncWaypoint = syncWaypoint
M.hasTrailerMission = hasTrailerMission
M.getCurrentMission = getCurrentMission
M.sendMissionRequest = sendMissionRequest
M.updateEngineStat = updateEngineStat
M.requestVehiclePowerWeight = requestVehiclePowerWeight
M.setInventoryVehicleWeight = setInventoryVehicleWeight
M.requestVehicleWeightUpdate = requestVehicleWeightUpdate
M.getTraderOwners = getTraderOwners
M.teleportToClosestGarage = teleportToClosestGarage
M.teleportToRandomGarage = teleportToRandomGarage

M.playCarpSound = playCarpSound

M.mapNumberToRange = mapNumberToRange

M.getVehicleWeight = getVehicleWeight
M.clearSynchroWear = clearSynchroWear

return M
