local M = {}

local compRIm = 0
local compRITotalm = 0
local compRITotalmMission = 0
local bregenEnabled = false
local bregenCtdn = 0
local shouldRenderTrailerPreview = false
local hasTowHitch = false
local vehicleEngineTorqueData = nil

local runTimer = false
local timeRan = 0
local TIME_TO_QUIT = 2

function splitString(s, delimiter)
  local result = {}
  delimiter = delimiter or " "
  for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

local function comprierase()
  compRIm = 0
  compRITotalm = 0
end

local function compriMissionErase()
  compRITotalmMission = 0
end

local function sendCompRI()
  obj:queueGameEngineLua(
    "if carp and carp.updateCompRi then carp.updateCompRi(" ..
      obj:getID() .. ", " .. compRITotalm .. ", " .. compRITotalmMission .. ") end"
  )
end

local function sendDamage()
  local beamstats = obj:calcBeamStats()

  obj:queueGameEngineLua(
    "if carp_vehicle and carp_vehicle.setDamageStats then carp_vehicle.setDamageStats(" ..
      obj:getID() ..
        ", " .. beamstats.beams_broken .. ", " .. beamstats.beams_deformed .. ", " .. beamstats.beam_count .. ") end"
  )
end

local function sendTiresInfo()
  local tiresData = ""

  for idx, data in pairs(tyreData) do
    tiresData = tiresData .. data.condition

    if idx ~= #tyreData then
      tiresData = tiresData .. "|"
    end
  end

  -- send tires' condition values
  obj:queueGameEngineLua(
    "if carp_vehicle and carp_vehicle.setTiresInfo then carp_vehicle.setTiresInfo(" ..
      obj:getID() .. ", '" .. tiresData .. "') end"
  )
end

local function updateTiresInfo(payload)
  -- local tiresData = splitString(payload, "@")
  -- print("updating tires in memory")
  -- print("payload: " .. payload)
  -- local tyreDataKeys = {}
  -- for key, _ in pairs(tyreData) do
  --   table.insert(tyreDataKeys, key)
  -- end
  -- for idx, data in pairs(tiresData) do
  --   tyreData[tyreDataKeys[idx]].condition = tonumber(data)
  -- end
end

local function sendFuel()
  local storages = energyStorage.getStorages()

  local fuelCapacity, fuelRemaining = 0, 0
  local nitrousCapacity, nitrousRemaining = 0, 0

  for _, v in pairs(storages) do
    if (v.energyType == "n2o") then
      nitrousCapacity = nitrousCapacity + v.capacity
      nitrousRemaining = nitrousRemaining + v.remainingMass
    elseif (v.energyType == "gasoline" or v.energyType == "diesel" or v.energyType == "electricEnergy") then
      fuelCapacity = fuelCapacity + v.capacity
      fuelRemaining = fuelRemaining + v.remainingVolume
    end
  end

  -- send gas and nitrous values
  obj:queueGameEngineLua(
    "if carp_vehicle and carp_vehicle.setFuelInfo then carp_vehicle.setFuelInfo(" ..
      obj:getID() ..
        ", " .. fuelCapacity .. ", " .. fuelRemaining .. ", " .. nitrousCapacity .. ", " .. nitrousRemaining .. ") end"
  )
end

local function updateVehiclePowerWeight()
  local maxPower = 0
  local weight = obj:calcBeamStats().total_weight

  for _, eng in pairs(powertrain.getDevicesByCategory("engine")) do
    maxPower = maxPower + eng.maxPower
  end

  obj:queueGameEngineLua("if carp then carp.updateVehiclePowerWeight(" .. maxPower .. ", " .. weight .. ") end")
end

local function onInit()
  compRITotalm = 0
  compRITotalmMission = 0
  recovery.loadHome = function()
  end
end

local function onReset()
  compRITotalm = 0
  sendCompRI()

  vehicleEngineTorqueData = {}

  for _, eng in pairs(powertrain.getDevicesByCategory("engine")) do
    table.insert(vehicleEngineTorqueData, eng:getTorqueData())
  end

  recovery.loadHome = function()
  end
end

local function getIsInAir()
  if not wheels or not wheels.wheels then
    return
  end

  local noContact = true
  for _, wheelItem in pairs(wheels.wheels) do
    if wheelItem.contactMaterialID1 ~= -1 or wheelItem.contactMaterialID2 ~= -1 then
      noContact = false
      break
    end
  end

  -- if rotation is too excessive (vehicle is upside down)
  -- or velocity too low (under 30km/h), no airtime for you
  local rot = vec3(obj:getRotation())
  local velocityMs = obj:getVelocity():len()
  if math.abs(rot.x) > 0.5 or math.abs(rot.y) > 0.5 or velocityMs < 8.2 then
    noContact = false
  end

  obj:queueGameEngineLua(
    "if carp_ui_passenger and carp_passengers.setIsInAir then carp_passengers.setIsInAir(" ..
      obj:getID() .. ", " .. tostring(noContact) .. ") end"
  )
end

local function checkForAiMode()
  if ai and ai.mode ~= "disabled" then
    -- ai.setMode("disabled")
    print("caught a bad boy")
  end
end

local vecUp = vec3(0, 0, 1)
local leftQuartenion = quatFromDir(vec3(-1, 0, 0), vecUp)
local TRAILER_INDICATOR_DISTANCE = 6
local textBackgroundColor = "ColorI(0, 0, 0, 128)"
local textColor = "ColorF(1, 1, 1, 0.9)"

local function renderTrailerPreview()
  if not shouldRenderTrailerPreview or not hasTowHitch then
    return
  end

  local pos = obj:getPosition()

  local fwd = obj:getForwardVector():rotated(leftQuartenion) * TRAILER_INDICATOR_DISTANCE
  local resultPos = pos + fwd

  obj:queueGameEngineLua(
    string.format(
      "if carp_draw then carp_draw.drawRect(%s, %s, %s, %s, %s, %s) end",
      tostring(resultPos),
      6,
      3,
      2.5,
      "ColorF(0.9, 0.2, 0.2, 0.7)",
      tostring(obj:getForwardVector())
    )
  )

  obj:queueGameEngineLua(
    "debugDrawer:drawTextAdvanced(" ..
      tostring(resultPos) ..
        ", 'Trailers will try to spawn here. Leave some space.', " ..
          textColor .. ", true, false, " .. textBackgroundColor .. ")"
  )
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
local frameCount = 0
local FRAMES_UNTIL_UPDATE_GAME_ENGINE = 24

local function updateEngineStats()
  if not vehicleEngineTorqueData then
    return
  end

  local currentRPM = 0
  local currentPower = 0
  local currentTorque = 0

  local maxTorqueRPM = 0
  local maxTorque = 0
  local maxPowerRPM = 0
  local maxPower = 0

  for _, engine in pairs(vehicleEngineTorqueData) do
    local torqueCurves = (engine.curves and engine.curves[1] and engine.curves[1].torque) or engine.torqueCurve or {}
    local powerCurves = (engine.curves and engine.curves[1] and engine.curves[1].power) or {}

    currentRPM = currentRPM + electrics.values.rpm

    currentPower = currentPower + ((currentRPM and powerCurves and powerCurves[math.floor(currentRPM)]) or 0)

    currentTorque = currentTorque + ((currentRPM and torqueCurves and torqueCurves[math.floor(currentRPM)]) or 0)

    maxTorqueRPM =
      maxTorqueRPM +
      (engine.maxTorqueRPM and math.floor(engine.maxTorqueRPM) or engine:getTorqueData().maxTorqueRPM or 0)

    maxTorque = maxTorque + (engine.maxTorque and math.floor(engine.maxTorque) or engine:getTorqueData().maxTorque or 0)

    maxPowerRPM =
      maxPowerRPM + (engine.maxTorqueRPM and math.floor(engine.maxPowerRPM) or engine:getTorqueData().maxPowerRPM or 0)

    maxPower = maxPower + (engine.maxTorqueRPM and math.floor(engine.maxPower) or engine:getTorqueData().maxPower or 0)
  end

  engineStats.currentRPM = currentRPM
  engineStats.currentPower = currentPower
  engineStats.currentTorque = currentTorque
  engineStats.maxTorqueRPM = maxTorqueRPM
  engineStats.maxTorque = maxTorque
  engineStats.maxPowerRPM = maxPowerRPM
  engineStats.maxPower = maxPower

  for statName, value in pairs(engineStats) do
    obj:queueGameEngineLua(
      "if carp then carp.updateEngineStat(" .. obj:getID() .. ", '" .. statName .. "', '" .. value .. "') end"
    )
  end
end

local HEIGHT_PROBABLY_FALLING_THRU_WORLD = -500
local function checkIfFallingThroughWorld()
  if not obj or not obj.getPosition then
    return
  end

  -- if this is not a Local vehicle, then we don't need to do any checks:
  if v.mpVehicleType ~= "L" then
    return
  end

  local currentPos = obj:getPosition()
  local zPosition = tonumber(currentPos.z or 0)

  if zPosition <= HEIGHT_PROBABLY_FALLING_THRU_WORLD then
    obj:queueGameEngineLua("if carp_ui_fallingthruworld then carp_ui_fallingthruworld.showWindow(true) end ")
  end
end

local function updateGarageSynchroWear()
  local data = carp_persistence.getSynchroWear()

  if data then
    data = table.concat(data, "&")

    obj:queueGameEngineLua(
      'if carp_ui_garage and carp_ui_garage.updateCachedSynchroWear then carp_ui_garage.updateCachedSynchroWear("' ..
        data .. '") end'
    )
  end
end

-- SET UP TIMERS:
local timerDeltas = {
  updateEngineStats = 0,
  checkIfFallingThroughWorld = 0,
  updateGarageSynchroWear = 0
}
local updateRates = {
  updateEngineStats = 0.3,
  checkIfFallingThroughWorld = 3,
  updateGarageSynchroWear = 1
}
-- END TIMER SET UP

local function updateGFX(dt)
  if not v.mpVehicleType == "L" then
    return
  end

  -- /\ START timers
  for k, v in pairs(timerDeltas) do
    timerDeltas[k] = timerDeltas[k] + dt
  end

  -- || check AND run timers
  if timerDeltas.updateEngineStats > updateRates.updateEngineStats then
    timerDeltas.updateEngineStats = 0

    updateEngineStats()
  end
  if timerDeltas.updateGarageSynchroWear > updateRates.updateGarageSynchroWear then
    timerDeltas.updateGarageSynchroWear = 0

    updateGarageSynchroWear()
  end
  if timerDeltas.checkIfFallingThroughWorld > updateRates.checkIfFallingThroughWorld then
    timerDeltas.checkIfFallingThroughWorld = 0

    checkIfFallingThroughWorld()
  end
  -- \/ END timers

  checkForAiMode()

  -- calculate compRi
  compRIm = electrics.values.airspeed * dt
  compRITotalm = compRIm + compRITotalm
  compRITotalmMission = compRIm + compRITotalmMission

  --send stuff
  sendCompRI()
  sendDamage()

  if extensions.isExtensionLoaded("beamRegenerator") then
    if extensions.beamRegeneration.regenerate ~= beamstate.breakAllBreakgroups then
      extensions.beamRegeneration.regenerate = function()
        bregenEnabled = true
      end
    end
  end

  -- bregen handling
  if bregenEnabled then
    if not bregenCtdn then
      bregenCtdn = 0
    else
      if bregenCtdn > 0 and bregenCtdn < 0.2 then
        beamstate.breakAllBreakgroups()
        beamstate.breakHinges()
        beamstate.deflateTires()
        beamstate.deflateRandomTire()

        obj:setGravity(-520)
      end

      if bregenCtdn > 2 and bregenCtdn < 2.05 then
        local a = 0

        obj:setGravity(-520)

        while a < 1000 do
          obj:setGravity(-520)
          fire.igniteRandomNode()
          a = a + 1
        end

        a = 0
      end

      if bregenCtdn > 3 and bregenCtdn < 3.03 then
        obj:setGravity(-520)
        obj:queueLuaCommand("recovery.startRecovering(true)")
      end

      if bregenCtdn > 7 then
        bregenEnabled = false
        bregenCtdn = 0

        obj:queueGameEngineLua("MPCoreNetwork.leaveServer(true)")
      end

      bregenCtdn = bregenCtdn + dt
    end
  end

  -- update isInAir for excitementScore
  getIsInAir()

  renderTrailerPreview()

  if runTimer then
    timeRan = timeRan + dt
  end

  if timeRan > TIME_TO_QUIT then
    obj:queueGameEngineLua("MPCoreNetwork.leaveServer(true)")
  end
end

local function enableQuitCountdown()
  runTimer = true
end

local function receiveTowHitchStatus(hasHitch)
  print("in veh received:", type(hasHitch), hasHitch)

  hasTowHitch = hasHitch == "true"

  print("hasTowHitch is now:", hasTowHitch)
end

local function enableTrailerPreview(isEnabled)
  shouldRenderTrailerPreview = isEnabled
end

M.onInit = onInit
M.onReset = onReset
M.updateGFX = updateGFX

M.sendFuel = sendFuel

M.updateTiresInfo = updateTiresInfo
M.sendTiresInfo = sendTiresInfo

M.comprierase = comprierase
M.compriMissionErase = compriMissionErase

M.updateVehiclePowerWeight = updateVehiclePowerWeight
M.enableTrailerPreview = enableTrailerPreview
M.receiveTowHitchStatus = receiveTowHitchStatus
M.enableQuitCountdown = enableQuitCountdown

return M
