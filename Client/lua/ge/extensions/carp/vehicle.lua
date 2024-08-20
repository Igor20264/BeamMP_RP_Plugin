local M = {}

local origOnVehicleSpawned = nil
local origSendDataToUI = nil
local bkpDropPlayer = nil
local jbeamIO = require("jbeam/io")
local jbeamSlotSystem = require("jbeam/slotSystem")
local vehManager = extensions.core_vehicle_manager

local lastResetPressed

local ownedParts = {}

local lastVehiclePosition = nil

currentVehicles = {car = {}}
local currentVehicleName
local firstSpawn = true

local timerDeltas = {queryPos = 0, queryFuel = 0, sendPos = 0, dmgMap = 0, queryTires = 0}
local updateRates = {queryPos = 1, queryFuel = 5, sendPos = 5, dmgMap = 2, queryTires = 10}

local pendingEditVeh = nil -- stores ID of last edited vehicle

local jbeamNames = {} -- used to figure out if we edited or spawned a new vehicle
local fuelMap = {}
local tiresMap = {}
local damageMap = {}
local oldDamageMap = {} -- TODO: probably the wrong way of doing things but at least i dont have to rewrite everything
local damageStats = {}

local partPrices = {}
local partPricesLoaded = false

local firstConfig = nil
local firstConfigElapsed = 0
local firstConfigSpawned = false
local TIME_BEFORE_FIRST_SPAWN = 1

local carpsettingsJson = jsonReadFile("settings/carpsettings.json")
if carpsettingsJson and carpsettingsJson.firstSpawnDelay and tonumber(carpsettingsJson.firstSpawnDelay) then
  TIME_BEFORE_FIRST_SPAWN = math.min(tonumber(carpsettingsJson.firstSpawnDelay), 5)
end

local engineStats = {
  currentRPM = 0,
  --
  currentTorque = 0,
  maxTorqueRPM = 0,
  maxTorque = 0,
  --
  currentPower = 0,
  maxPowerRPM = 0,
  maxPower = 0
}

local function updateEngineStat(gameVehicleID, statName, value)
  if not MPVehicleGE.isOwn(gameVehicleID) then
    return
  end

  if not carp.getVehicleWeight() then
    carp.requestVehiclePowerWeight(gameVehicleID)
  end

  engineStats[statName] = tonumber(value)
end

local function getEngineStatValue(statName)
  return engineStats[statName] or "does not exist"
end

local function loadPartPricesFromJson()
  if partPricesLoaded then
    return
  end

  partPricesLoaded = true

  local basePath = "/carpresources/json/priceCatalog"

  local partPriceFiles = FS:directoryList(basePath)

  if not (#partPriceFiles) or #partPriceFiles == 0 then
    log("W", "loadPartPricesFromJson", "No part prices found")
    return
  end

  local loadedPartCount = 0

  for _, filename in pairs(partPriceFiles) do
    local fileContents = jsonReadFile(filename)

    for partName, partPrice in pairs(fileContents) do
      partPrices[partName] = partPrice
      loadedPartCount = loadedPartCount + 1
      --table.insert(partPrices, partName, partPrice)
    end
  end

  log("I", "loadPartPricesFromJson", "Loaded " .. loadedPartCount .. " part prices")
end

local vehsPartsData = {}
local function getVehData(vehID)
  local vehObj = vehID and be:getObjectByID(vehID) or be:getPlayerVehicle(0)
  if not vehObj then
    return
  end
  vehID = vehObj:getID()

  local vehData = vehManager.getVehicleData(vehID)
  if not vehData then
    return
  end

  if not vehsPartsData[vehID] then
    vehsPartsData[vehID] = {vehName = vehObj:getJBeamFilename(), alpha = 1, partsHighlighted = nil}
  end

  return vehObj, vehData, vehID, vehsPartsData[vehID]
end
-- function override for sending data to the part picker menu
local function customSendDataToUI()
  log("W", "customSendDataToUI", "customSendDataToUI")

  local vehObj, vehData, vehID, partsData
  local playerVehicle = be:getPlayerVehicle(0)
  if playerVehicle then
    vehObj, vehData, vehID, partsData = getVehData(playerVehicle:getID())
  end
  if not vehObj then
    log("E", "customSendDataToUI", "no active vehicle")
    return
  end

  local jbeam = stringToTable(vehData.vehicleDirectory, "/")[2] -- '/vehicles/pickup/'

  log("W", "customSendDataToUI", "jbeam: " .. jbeam)

  local pcFilename = vehData.config.partConfigFilename
  local configDefaults = nil
  if pcFilename then
    local data = core_vehicle_partmgmt.buildConfigFromString(vehData.vehicleDirectory, pcFilename)
    if data ~= nil then
      configDefaults = data
      configDefaults.parts = configDefaults.parts or {}
      configDefaults.vars = configDefaults.vars or {}
    end
  end
  if configDefaults == nil then
    configDefaults = {parts = {}, vars = {}}
  end
  log("W", "customSendDataToUI", "customSendDataToUI")
  --  dump(vehData.mainPartName)
  local data = {
    mainPartName = vehData.mainPartName,
    chosenParts = vehData.chosenParts,
    variables = vehData.vdata.variables,
    availableParts = jbeamIO.getAvailableParts(vehData.ioCtx),
    slotMap = jbeamIO.getAvailableSlotMap(vehData.ioCtx),
    partsHighlighted = partsData.partsHighlighted,
    defaults = configDefaults
  }

  -- enrich the data a bit for the UI
  for partName, part in pairs(data.availableParts) do
    if part.modName then
      local mod = core_modmanager.getModDB(part.modName)
      if mod and mod.modData then
        part.modTagLine = mod.modData.tag_line
        part.modTitle = mod.modData.title
        part.modLastUpdate = mod.modData.last_update
      end
    end
  end

  -- debug globals
  -- availParts = data.availableParts
  -- OwnedParts = ownedParts
  -- PartPrices = partPrices

  log("I", "customSendDataToUI", "jbeam: " .. jbeam)

  local unknownPartPriceString = " (⚠️Unknown)"
  local ownedPartString = " ✅"

  -- Loop through all the available parts
  for partName, partsTable in pairs(data.availableParts) do
    if partPrices[partName] ~= nil then
      local formattedPrice = string.format(" [$%d]", partPrices[partName])
      if string.find(data.availableParts[partName].description, formattedPrice, nil, true) == nil then
        data.availableParts[partName].description = data.availableParts[partName].description .. formattedPrice
      end
    elseif string.find(data.availableParts[partName].description, unknownPartPriceString, nil, true) == nil then
      data.availableParts[partName].description = data.availableParts[partName].description .. unknownPartPriceString
    end
    -- Set owned flag
    if
      ownedParts[jbeam] and ownedParts[jbeam][partName] == true and
        string.find(data.availableParts[partName].description, ownedPartString, nil, true) == nil
     then
      data.availableParts[partName].description = data.availableParts[partName].description .. ownedPartString
    end
  end
  guihooks.trigger("VehicleConfigChange", data)
  --log("I", "customSendDataToUI", "VehicleConfigChange")
end

local function customOnVehicleSpawned(gameVehicleID)
  local vehicleData = vehManager.getVehicleData(gameVehicleID)

  if not vehicleData or not MPVehicleGE.isOwn(gameVehicleID) then
    origOnVehicleSpawned(gameVehicleID)
    return
  end

  local vehicle, unifyJournal, chosenParts, activePartsOrig =
    jbeamSlotSystem.findParts(vehicleData.ioCtx, vehicleData.config)

  chosenParts.main = nil

  vehicleData.config.parts = chosenParts -- this updates the config for future calls of getVehicleData too, so edits are also taken care of

  origOnVehicleSpawned(gameVehicleID)
end

local function injectPartPrices()
  if extensions.core_vehicle_partmgmt and extensions.core_vehicle_partmgmt.sendDataToUI ~= customSendDataToUI then
    log("E", "onclientpoststartmission", "loaded custom part schenanigans")
    origSendDataToUI = extensions.core_vehicle_partmgmt.sendDataToUI
    extensions.core_vehicle_partmgmt.sendDataToUI = customSendDataToUI
    extensions.core_vehicle_partmgmt.reset = customSendDataToUI
  end
end

local function injectConfigCleanup()
  if extensions.MPVehicleGE and extensions.MPVehicleGE.onVehicleSpawned ~= customOnVehicleSpawned then
    log("E", "onExtensionLoaded", "loaded custom config schenanigans")
    origOnVehicleSpawned = extensions.MPVehicleGE.onVehicleSpawned
    extensions.MPVehicleGE.onVehicleSpawned = customOnVehicleSpawned

    extensions.hookUpdate("onVehicleSpawned") -- its a hook so we have to invalidate the cache
  end
end

-- return local vehicle object
local function getPlayerVehicle()
  if currentVehicles.car and currentVehicles.car.gameVehicleID then
    local veh = be:getObjectByID(currentVehicles.car.gameVehicleID)
    if veh then
      return veh
    end
  end

  log("E", "getPlayerVehicle", "Could not get carp current veh, falling back to game current vehicle")
  local veh = be:getPlayerVehicle(0)

  if veh and MPVehicleGE.isOwn(veh:getID()) then
    currentVehicles.car.gameVehicleID = veh:getID()
    return veh
  end

  return nil
end

-- return local vehicle id
local function getPlayerVehicleID()
  if not currentVehicles.car.gameVehicleID then
    log("E", "getPlayerVehicleID", "Could not get currentVehicles.car.gameVehicleID, falling back to current vehicle")
    local currveh = getPlayerVehicle()
    if not currveh then
      log("E", "getPlayerVehicleID", "Could not get be:getPlayerVehicle(0)")
      return nil
    end
    currentVehicles.car.gameVehicleID = currveh:getID()
  end

  return currentVehicles.car.gameVehicleID
end

-- return local trailer id
local function getTrailerVehicleID()
  if currentVehicles.trailer and currentVehicles.trailer.gameVehicleID then
    return currentVehicles.trailer.gameVehicleID
  else
    log("E", "getTrailerVehicleID", "Could not get currentVehicles.trailer.gameVehicleID")
    return nil
  end
end

-- return local vehicle position object
local function getVehiclePosition()
  local playerVehicle = getPlayerVehicle()
  if playerVehicle then
    local playerVehiclePosition = playerVehicle:getPosition()

    lastVehiclePosition = playerVehiclePosition
    return playerVehiclePosition
  end
end

-- used when 'teleporting'
local function sendPositionDifference()
  if not lastVehiclePosition or not lastVehiclePosition.x then
    return false
  end

  local lastVehPos = vec3(lastVehiclePosition)

  local currentPos = getVehiclePosition()
  if not currentPos then
    return false
  end

  local dist = currentPos:distance(lastVehPos)

  TriggerServerEvent("receiveHandleTeleport", tostring(dist))
end

local function getVehicleName()
  local vehic = getPlayerVehicle()
  if vehic and vehic.JBeam then
    return vehic.JBeam
  end
end

-- updates fuel info (from VE)
local function setFuelInfo(vehID, fuelCapacity, fuelRemaining, nitrousCapacity, nitrousRemaining)
  fuelMap[vehID] = {
    capacity = fuelCapacity,
    current = fuelRemaining,
    nitrousCapacity = nitrousCapacity,
    nitrousRemaining = nitrousRemaining
  }
end

-- request fuel from VE
local function getFuelInfo()
  local currVeh = getPlayerVehicle()
  if currVeh then
    currVeh:queueLuaCommand("if carp then carp.sendFuel() end")
  end
end

-- request tires info from VE
local function getTiresInfo()
  local currVeh = getPlayerVehicle()
  if currVeh then
    currVeh:queueLuaCommand("if carp then carp.sendTiresInfo() end")
  end
end

-- updates tires info (from VE)
local function setTiresInfo(vehID, tiresInfo)
  local payloadSplit = stringToTable(tiresInfo, "|")

  tiresMap[vehID] = {}

  for _, value in pairs(payloadSplit) do
    table.insert(tiresMap[vehID], value)
  end
end

-- pushing tires info to VE
local function updateTiresInfo(payload)
  --[[ local currVeh = getPlayerVehicle()
  if currVeh then
    print("updateTiresInfo -> vehicle lua")

    currVeh:queueLuaCommand("if carp then carp.updateTiresInfo('" .. payload .. "') end")
  end ]]
end

local function sendTiresInfo()
  local vehicleName = getVehicleName()
  local playerVehicleID = getPlayerVehicleID()

  --check if we know the current tires for this vehicle. if not, get them
  if not vehicleName or not tiresMap[playerVehicleID] then
    getTiresInfo()
    return
  end

  local payload = vehicleName .. "|" .. table.concat(tiresMap[playerVehicleID], "@")

  print("!!!! sendTiresInfo: receiveUpdateTires to server")
  print("sendTiresInfo payload:")
  print(payload)

  TriggerServerEvent("receiveUpdateTires", payload)
end

local function returnTiresMap(objID)
  if objID then
    return tiresMap[objID]
  end

  return tiresMap
end

local function receiveRefuelCommand(payload)
  local payloadSplit = stringToTable(payload, "|")

  local vehicleName, currentFuel, currentNitrous = payloadSplit[1], payloadSplit[2], payloadSplit[3]

  local veh = getPlayerVehicle()
  if not veh or not veh:getID() then
    return
  end

  veh:queueLuaCommand([[
    local s = energyStorage.getStorages()
    local f = 0
    if (s) then
      for k, v in pairs(s) do
        if (v.energyType == 'gasoline' or v.energyType == 'diesel' or v.energyType == 'electricEnergy') then
          f = f + v.capacity
        end
      end
    end
    local fuelRatio = ]].. currentFuel ..[[ / f 
    for k, v in pairs(s) do
      if (v.energyType == 'gasoline' or v.energyType == 'diesel' or v.energyType == 'electricEnergy') then
        v:setRemainingRatio(fuelRatio)
      end
    end
  ]])

  veh:queueLuaCommand([[
    local s = energyStorage.getStorages()
    local f = 0
    if (s) then
      for k, v in pairs(s) do
        if (k == 'mainBottle') then
          f = f + v.capacity
        end
      end
    end
    local fuelRatio = ]].. currentNitrous ..[[ / f 
    for k, v in pairs(s) do 
      if (k == 'mainBottle' and v.setRemainingRatio) then
        v:setRemainingRatio(fuelRatio)
      end
    end 
  ]])

  if not fuelMap[veh:getID()] then
    return
  end

  fuelMap[veh:getID()].current = currentFuel
end

-- updates damage stats (from VE)
local function setDamageStats(vehID, beams_broken, beams_deformed, beam_count)
  damageMap[vehID] = {
    brokenBeams = beams_broken,
    deformedBeams = beams_deformed,
    totalBeams = beam_count
  }
end

-- returns damage stats for local vehicle
local function getDamageStats()
  local vehID = getPlayerVehicleID()
  return vehID and damageMap[vehID] or nil
end

-- TODO: cleanup. why are there 2 similar functions
local function receiveChatRefuel()
  local playerVehicleID = getPlayerVehicleID()
  if not fuelMap[playerVehicleID] then
    getFuelInfo()
    return
  else
    local payload = getVehicleName() .. "|" .. fuelMap[playerVehicleID].current
    TriggerServerEvent("receiveChatRefuelResult", payload)
  end
end

local function sendFuel()
  local vehicleName = getVehicleName()
  local playerVehicleID = getPlayerVehicleID()

  --check if we know the current fuel levels for this vehicle. if not, get them
  if not vehicleName or not fuelMap[playerVehicleID] then
    getFuelInfo()
    return
  end

  local payload =
    vehicleName ..
    "|" .. tostring(fuelMap[playerVehicleID].current) .. "|" .. tostring(fuelMap[playerVehicleID].nitrousRemaining)
  TriggerServerEvent("receiveUpdateVehicleFuel", payload)
end

local function getCurrentFuelMap()
  return fuelMap[getPlayerVehicleID()]
end

-- UI button
local function requestRefuel(amount)
  amount = amount or 5
  local playerVehicleID = getPlayerVehicleID()
  if not playerVehicleID or not fuelMap[playerVehicleID] then
    getFuelInfo()
    return
  else
    local payload =
      getVehicleName() .. "|" .. fuelMap[playerVehicleID].capacity .. "|" .. fuelMap[playerVehicleID].current .. "|" .. amount
    TriggerServerEvent("receiveRefuelVehicleStation", payload)
  end
end

-- UI button
local function requestCharge(amount)
  amount = amount or 5
  local playerVehicleID = getPlayerVehicleID()
  if not playerVehicleID or not fuelMap[playerVehicleID] then
    getFuelInfo()
    return
  else
    local payload =
      getVehicleName() .. "|" .. fuelMap[playerVehicleID].capacity .. "|" .. fuelMap[playerVehicleID].current .. "|" .. amount
    TriggerServerEvent("receiveChargingVehicleStation", payload)
  end
end

-- UI button
local function requestNitrousRefuel(amount)
  amount = amount or 5
  local playerVehicleID = getPlayerVehicleID()
  if not playerVehicleID or not fuelMap[playerVehicleID] then
    getFuelInfo()
    return
  else
    local payload =
      getVehicleName() ..
      "|" .. fuelMap[playerVehicleID].nitrousCapacity .. "|" .. fuelMap[playerVehicleID].nitrousRemaining .. "|" .. amount
    TriggerServerEvent("receiveNitrousRefuelVehicleStation", payload)
  end
end

local function updateDamageMap()
  local playerVehicle = getPlayerVehicle()

  if not playerVehicle then
    return
  end

  local playerVehicleID = playerVehicle:getID()

  local damageStats = damageMap[playerVehicleID]
  if damageStats ~= nil and damageStats.brokenBeams ~= nil then
    local returnString = ""

    local lastRepairDamageStats = oldDamageMap[playerVehicleID]

    returnString = damageStats.brokenBeams .. "|" .. damageStats.deformedBeams .. "|" .. damageStats.totalBeams

    -- reset the last repaired values
    oldDamageMap[playerVehicleID] = shallowcopy(damageStats) -- bruh moment

    TriggerServerEvent("setDamageStatus", returnString)
  end
end

-- returns a string with: position if no damage stats
-- returns a string with: position + brokenBeams + deformedBeams + vehicleName, if we have em
local function buildVehicleResettedPayload()
  local playerVehicle = getPlayerVehicle()
  local playerVehicleID = playerVehicle:getID()
  local playerVehiclePosition = playerVehicle:getPosition()

  local positionString = playerVehiclePosition.x .. "&" .. playerVehiclePosition.y .. "&" .. playerVehiclePosition.z
  local damageStats = damageMap[playerVehicleID]
  local lastRepairDamageStats = oldDamageMap[playerVehicleID]

  if damageStats ~= nil and damageStats.brokenBeams ~= nil then
    local returnString = ""

    -- if everything is the same as the last repair, send that the vehicle is in perfect shape instead
    if lastRepairDamageStats and tableSize(MPHelpers.tableDiff(damageStats, lastRepairDamageStats)) == 0 then
      returnString = positionString .. "|0|0|3000"
    else
      returnString =
        positionString ..
        "|" .. damageStats.brokenBeams .. "|" .. damageStats.deformedBeams .. "|" .. damageStats.totalBeams
    end

    returnString = returnString .. "|" .. currentVehicleName

    -- reset the last repaired values
    oldDamageMap[playerVehicleID] = shallowcopy(damageStats) -- bruh moment

    return returnString
  else
    return positionString
  end
end

local function checkDamagedVehicleChange(previousVehicleName, vehicleName)
  if previousVehicleName == vehicleName or previousVehicleName == nil or vehicleName == nil then
    return
  end

  if
    damageStats["brokenBeams"] and damageStats["deformedBeams"] and damageStats["totalBeams"] and
      tostring(lastRepairDamageStats["brokenBeams"]) ~= tostring(damageStats["brokenBeams"]) and
      tostring(lastRepairDamageStats["deformedBeams"]) ~= tostring(damageStats["deformedBeams"]) and
      tostring(lastRepairDamageStats["totalBeams"]) ~= tostring(damageStats["totalBeams"])
   then
    local payloadString = buildVehicleResettedPayload()
    payloadString = payloadString .. "|" .. previousVehicleName
    TriggerServerEvent("receiveHandlePlayerSwapDamagedVehicle", payloadString)

    damageStats = {}
  end
end

local function towToNearestRoad()
  local playerVehicle = getPlayerVehicle()

  if playerVehicle:getVelocity():length() > 5 then
    TriggerServerEvent("genericMessageSender", "Slow down there cowboy")
    return
  end

  local nearestRoadNode, distance = carp_groundmarkers.findClosestRoad(playerVehicle:getPosition())

  if not distance or distance > 25 then
    TriggerServerEvent(
      "genericMessageSender",
      "The towing service had a good look at your wreck and decided you're too far to pull out."
    )
    return
  end

  local nearestRoadPos = vec3(map.getMap().nodes[nearestRoadNode].pos)
  nearestRoadPos.z = nearestRoadPos.z + 0.1

  TriggerServerEvent("receiveHandleTow", tostring(distance))

  playerVehicle:setPositionNoPhysicsReset(nearestRoadPos)
  commands.setGameCamera()
end

local function removeTrailerVehicle()
  local trailerGameVehicleID = getTrailerVehicleID()

  if carp.hasTrailerMission() and trailerGameVehicleID then
    local trailerObj = be:getObjectByID(trailerGameVehicleID)
    if trailerObj then
      trailerObj:delete()
    end
    currentVehicles.trailer = nil
  else
  end
end

local function exitedGarage()
end

-- SERVER EVENTS

-- receives owned parts so it can be injected into the UI
local function receiveOwnedParts(partstring)
  local ownedPartsArray = stringToTable(partstring, ";")
  local vehicleName = ownedPartsArray[1]
  log("I", "receiveOwnedParts", "Received " .. #ownedPartsArray .. " owned parts")
  ownedParts[vehicleName] = {} -- clear previous entries for this vehicle
  for k, v in pairs(ownedPartsArray) do
    ownedParts[vehicleName][v] = true
  end
end

local function setPlayerVehicleSlot(data)
  local decodedData = stringToTable(data, "|")

  log("W", "setPlayerVehicleSlot", dumps(decodedData))

  local vehicleType = decodedData[1]
  local vehicleName = decodedData[2]
  local gameVehicleID = tonumber(decodedData[4])

  -- .... I'm not so sure about this? what is this for..
  --local serverVehicleID = MPConfig.getPlayerServerID() .. "-" .. decodedData[3]

  if vehicleType then
    if not currentVehicles[vehicleType] then
      currentVehicles[vehicleType] = {}
    end
    currentVehicles[vehicleType].serverVehicleID = serverVehicleID

    if gameVehicleID and gameVehicleID > 0 then
      currentVehicles[vehicleType].gameVehicleID = gameVehicleID --MPVehicleGE.getGameVehicleID(serverVehicleID)
    end

    if currentVehicles[vehicleType].name == vehicleName then
      if currentVehicles[vehicleType].spawnCount then
        currentVehicles[vehicleType].spawnCount = 1
      end
    else
      currentVehicles[vehicleType].name = vehicleName

      if not currentVehicles[vehicleType].spawnCount then
        currentVehicles[vehicleType].spawnCount = 0
      end
    end
  end
end

local function spawnConfig(data)
  if not firstConfigSpawned and firstConfigElapsed <= TIME_BEFORE_FIRST_SPAWN then
    firstConfig = data

    return
  end

  if not firstConfigSpawned then
    firstConfigSpawned = true
    firstConfig = nil
  end

  if data == "startervehicle" or data == '"startervehicle"' then
    MPVehicleGE.replaceRequest("autobello", {config = "turdie"})
    return
  else
    local config = jsonDecode(data)

    local requestConfig = {
      config = config.vcf
    }
    if config.rot and config.rot.x and config.rot.y and config.rot.z and config.rot.w then
      requestConfig.rot = quat(config.rot) * quat(0, 0, 1, 0) -- rotate vehicle 180 degrees
    else
      log("W", "spawnConfig", "Vehicle spawn rotation data unvailable.")
    end

    if config.pos and config.pos.x and config.pos.y and config.pos.z then
      requestConfig.pos = config.pos
    else
      log("W", "spawnConfig", "Vehicle spawn position data unvailable. Spawning at random default spawn location.")
      local spawnLocations = scenetree.findClassObjects("SpawnSphere")
      local totalSpawns = 0

      for _, name in pairs(spawnLocations) do
        -- literally just looping to figure out how many :(
        totalSpawns = totalSpawns + 1
      end

      if (totalSpawns > 0) then
        math.randomseed(os.time())
        local spawnToUse = math.floor((math.random() * totalSpawns) + 1)
        local spawnObject = scenetree.findObject(spawnLocations[spawnToUse])
        requestConfig.pos = spawnObject:getPosition()
      end
    end

    if requestConfig.pos and requestConfig.pos.x == 0 and requestConfig.pos.y == 0 and requestConfig.pos.z == 0 then
      TriggerServerEvent("genericMessageSender", "Could not load your position! This is bad!")
      return
    end

    --replace current vehicle if owned
    MPVehicleGE.replaceRequest(config.jbm, requestConfig)
  end
end

-- BEAMNG EVENTS

local function onVehicleResetted(vehID, other)
  if not MPVehicleGE or not MPVehicleGE.isOwn(vehID) or not MPVehicleGE.getServerVehicleID(vehID) then
    return
  end

  MPVehicleGE.sendVehicleEdit(vehID)

  log("W", "onVehicleResetted", "" .. vehID)

  sendPositionDifference()

  local previousVehicleName = currentVehicleName
  currentVehicleName = getVehicleName()

  if (currentVehicleName ~= previousVehicleName) then
  -- UI.chatSend("/abandon")
  end

  log("W", "onVehicleResetted", "2")
  local currentMission = carp.getCurrentMission()

  if (currentMission ~= nil and MPVehicleGE and MPVehicleGE.isOwn(vehID)) then
    if ((currentVehicleName ~= previousVehicleName) and currentMission.missionDestination ~= nil) then
      removeTrailerVehicle()
    -- UI.chatSend("/abandon")
    end
  end
  log("W", "onVehicleResetted", "3")

  -- lets delete trailers if you give up on a special mission!
  if carp.hasTrailerMission() then
    if currentVehicles.trailer and currentVehicles.trailer.spawnCount and currentVehicles.trailer.spawnCount < 2 then
      currentVehicles.trailer.spawnCount = currentVehicles.trailer.spawnCount + 1
      return
    else
      removeTrailerVehicle()
      TriggerServerEvent("receiveHandleSpecialMissionAttemptedReset", tostring(vehID))
    end
  end
  log("W", "onVehicleResetted", "4")

  if firstSpawn then
    MPModManager.checkAllMods()
  end

  local payloadString = buildVehicleResettedPayload()
  log("W", "onVehicleResetted", payloadString)

  TriggerServerEvent("receiveHandlePlayerResetVehicle", payloadString)
  getPlayerVehicle():queueLuaCommand("carp_dynamicWeight.setNodeWeights()") -- set node weights back to what they should be on resets

  -- damaged vehicle checks
  local vehName = getVehicleName()
  checkDamagedVehicleChange(previousVehicleName, vehName)

  TriggerServerEvent("receiveGetVehicleFuelAmount", vehName)

  -- also reset the fuel timer since we don't need it to run instantly after
  timerDeltas.queryFuel = 0

  --getMaxFuel()
end

local function onVehicleDestroyed(vehID)
  -- UI.chatSend("/abandon")
  --[[
  local mission = carp.getCurrentMission()
  if (mission ~= nil and MPVehicleGE and MPVehicleGE.isOwn(vehID) and currentVehicles.trailer == nil) then
    if (mission.missionDestination ~= nil) then
      removeTrailerVehicle()
      -- UI.chatSend("/abandon")
    --currentMission = {} the server should clear the mission for us
    end
  end
  ]]
end

-- sync on part change
local function onVehicleSpawned(gameVehicleID)
  local veh = be:getObjectByID(gameVehicleID)
  local newJbeam = veh:getJBeamFilename()

  local oldJbeam = jbeamNames[gameVehicleID]

  if oldJbeam and oldJbeam == newJbeam then -- If it's an edit, not new spawn or vehicle change
    pendingEditVeh = gameVehicleID
  end

  jbeamNames[gameVehicleID] = newJbeam
end

local function onUpdate(dtReal, dtSim, dtRaw)
  for k, v in pairs(timerDeltas) do
    timerDeltas[k] = timerDeltas[k] + dtReal
  end

  if firstConfig and not firstConfigSpawned then
    firstConfigElapsed = firstConfigElapsed + dtReal

    if firstConfigElapsed > TIME_BEFORE_FIRST_SPAWN then
      spawnConfig(firstConfig)
    end
  end

  -- used for caching in case of resets/teleports
  if timerDeltas.queryPos > updateRates.queryPos then
    timerDeltas.queryPos = 0
    --getDamageStats() now done on every frame
    getVehiclePosition()
  end

  if timerDeltas.queryFuel > updateRates.queryFuel then
    timerDeltas.queryFuel = 0
    getFuelInfo()
  end

  if timerDeltas.dmgMap > updateRates.dmgMap then
    timerDeltas.dmgMap = 0
    updateDamageMap()
  end

  if timerDeltas.sendPos > updateRates.sendPos then
    timerDeltas.sendPos = 0

    sendFuel()
  end
end

local function onExtensionLoaded()
  AddEventHandler("onClientReceiveOwnedParts", receiveOwnedParts)
  AddEventHandler("clientCommandReceiver", sendMissionRequest)
  AddEventHandler("setPlayerVehicleSlot", setPlayerVehicleSlot)
  AddEventHandler("receiveRefuelCommand", receiveRefuelCommand)
  AddEventHandler("receiveChatRefuel", receiveChatRefuel)
  AddEventHandler("spawnConfig", spawnConfig)
  AddEventHandler("updateTiresInfo", updateTiresInfo)

  resetGameplay = function()
    return nil
  end

  bkpDropPlayer = commands.dropPlayerAtCamera
  commands.dropPlayerAtCamera = function()
    return nil
  end

  loadPartPricesFromJson()
  injectConfigCleanup()
  injectPartPrices()
  log("I", "onExtensionLoaded", "carp_vehicle initialized.")
end

local function onExtensionUnloaded()
  if origSendDataToUI ~= nil then
    extensions.core_vehicle_partmgmt.sendDataToUI = origSendDataToUI
  end

  commands.dropPlayerAtCamera = bkpDropPlayer
end

M.onVehicleResetted = onVehicleResetted
M.onVehicleDestroyed = onVehicleDestroyed
M.onVehicleSpawned = onVehicleSpawned
M.onUpdate = onUpdate
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
--M.onWorldReadyState = onWorldReadyState

M.exitedGarage = exitedGarage
M.setFuelInfo = setFuelInfo
M.setDamageStats = setDamageStats
M.sendFuel = sendFuel
M.getCurrentFuelMap = getCurrentFuelMap
M.requestRefuel = requestRefuel
M.requestCharge = requestCharge
M.requestNitrousRefuel = requestNitrousRefuel
M.removeTrailerVehicle = removeTrailerVehicle
M.towToNearestRoad = towToNearestRoad

M.getTiresInfo = getTiresInfo
M.setTiresInfo = setTiresInfo
M.updateTiresInfo = updateTiresInfo
M.returnTiresMap = returnTiresMap

M.getPlayerVehicle = getPlayerVehicle
M.getPlayerVehicleID = getPlayerVehicleID
M.getVehiclePosition = getVehiclePosition
M.getTrailerVehicleID = getTrailerVehicleID
M.getVehicleName = getVehicleName

M.updateEngineStat = updateEngineStat
M.getEngineStatValue = getEngineStatValue

return M
