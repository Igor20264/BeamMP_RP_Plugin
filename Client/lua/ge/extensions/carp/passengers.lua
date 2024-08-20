local base = carp_ui_base

local M = {}

local excitementScore = 0
local fullComboCountdown = 1
--
local defaultDriftCooldown = 0.5

local currentDriftScore = 0
local driftBonus = 0
local driftState = 0
local driftCooldown = 0
local driftPoints = 0
local driftCombo = 0
local messageTimer = 1
local displayMessage = ""
local driftSummary = ""

local hasCheered = false

local greatDriftThreshold = 50000
--
local isGettingAirtime = false
local airTimeScorePerSecond = 600
local currentAirtimeScore = 0
--
local isExceedingGforce = false
local gForceExceedLimit = 1.2
local gForceScorePerSecond = 5500
local currentGforceScore = 0
--
local isExceedingSpeed = false
local speedExceedLimit = 100
local speedScorePerSecond = 100
local currentSpeedScore = 0
--
local isExciteMission = false
local paxMissionActive = false

local passengerList = {}

local function addPassengerToList(weight)
  table.insert(passengerList, weight)
end

local function clearPassengerList()
  passengerList = {}
end

local function getPassengerList()
  return passengerList
end

local function metersSecondToKmHour(ms)
  return ms * 3.6
end

local function getSpeedKmh()
  if not MPVehicleGE.isOwn(be:getPlayerVehicle(0):getID()) then
    return 0
  end

  local fobjData = map.objects[be:getPlayerVehicle(0):getID()]
  if not fobjData then
    return
  end

  local speedKmh = metersSecondToKmHour(fobjData.vel:length())

  return speedKmh
end

local function playCheerSound()
  local rand = math.random(1, 8)

  carp.playCarpSound("audio/cheers/cheer" .. rand .. ".ogg", 8)
end

local function updatePlayerVehicle(vehID)
  if not MPVehicleGE or not MPVehicleGE.isOwn(vehID) or not MPVehicleGE.getServerVehicleID(vehID) then
    --playerVehicle = nil -- this was not used anywhere
    return
  end

  --playerVehicle = carp_vehicle.getPlayerVehicle() -- this neither
end

local function onVehicleResetted(vehID, other)
  if not vehID or not MPVehicleGE.isOwn(tonumber(vehID)) then
    return
  end

  updatePlayerVehicle(vehID)

  if not isExciteMission then
    return
  end

  if excitementScore > 0 then
    excitementScore = 0
  end

  currentAirtimeScore = 0
  currentDriftScore = 0
end

local function onVehicleDestroyed(vehID)
  if not vehID or not MPVehicleGE.isOwn(tonumber(vehID)) then
    return
  end

  updatePlayerVehicle(vehID)
end

local playerVehicleID = nil

local function setIsInAir(vehID, isInAir)
  if not base.isWindowVisible("PassengerUI") then
    return
  end

  if not vehID or not MPVehicleGE.isOwn(vehID) then
    isGettingAirtime = false
    return
  end

  isGettingAirtime = isInAir
end

local function updateGForce(vehID, gForce)
  if not base.isWindowVisible("PassengerUI") then
    return
  end

  if not vehID or not MPVehicleGE.isOwn(tonumber(vehID)) then
    return
  end

  if tonumber(gForce) > gForceExceedLimit then
    isExceedingGforce = true
  else
    isExceedingGforce = false
  end
end

--------
local function processDrifting(dtReal)
  if not playerVehicleID and MPVehicleGE.isOwn(be:getPlayerVehicle(0):getID()) then
    playerVehicleID = be:getPlayerVehicle(0):getID()
  end

  if not playerVehicleID then
    return
  end

  local fobjData = map.objects[be:getPlayerVehicle(0):getID()]
  if not fobjData then
    return
  end

  local vehicle = scenetree.findObjectById(playerVehicleID)

  if fobjData then
    local vecDifx = fobjData.dirVec.x - (fobjData.vel.x / fobjData.vel:length()) --find the difference between the x speed and rotation vectors
    local vecDify = fobjData.dirVec.y - (fobjData.vel.y / fobjData.vel:length()) --find the difference between the y speed and rotation vectors

    local angleBonus = math.floor(math.sqrt(vecDifx * vecDifx + vecDify * vecDify) * 10) --distance between speed and rotation vectors
    local speedBonus = fobjData.vel:length() * 0.15
    local lastDriftPoints = 0
    angleBonus = angleBonus < 11 and angleBonus or 0 --don't consider spin-outs to be drifting
    angleBonus = angleBonus > 1 and angleBonus or 0 --don't consider overly shallow drifts
    speedBonus = speedBonus > 1 and speedBonus or 0 --don't consider very low-speed drifts
    speedBonus = isGettingAirtime == false and speedBonus or 0 -- don't consider tumbling down a mountain a drift

    driftBonus = math.floor(angleBonus * speedBonus) --combine speed and angle to make a score
    if driftBonus > 0 then --If a drift is happening
      if driftCooldown > 0 and driftState == 0 then --allow combined drifts with a score multiplier
        driftCombo = driftCombo + 1
      end

      currentDriftScore = currentDriftScore + driftBonus * (driftCombo + 1) --add the instantaneous drift score to the total scenario score
      driftPoints = driftPoints + driftBonus * (driftCombo + 1) --add the instantaneous drift score to the current drift score
      lastDriftPoints = 0

      if driftCombo == 0 then --normal display message
        displayMessage = "Drift: " .. driftPoints
      else
        displayMessage = "Combo x" .. (driftCombo + 1) .. ": " .. driftPoints --combo drift display message
      end
      driftState = 1
    else --if not drifting
      if driftState == 1 then --if just finished a drift
        driftCooldown = defaultDriftCooldown --allow chained drifts within a grace period
        driftState = 0 --end the drift
        messageTimer = 1
        lastDriftPoints = driftPoints --remember what the score was
        driftPoints = 0 --no more points from this drift
      end

      -- decrease drift cooldown, reset combo
      driftCooldown = driftCooldown > 0 and driftCooldown - dtReal or 0 --short cooldown during which additional drifts can be chained
      driftCombo = driftCooldown > 0 and driftCombo or 0 --reset combos after cooldown period

      if speedBonus == 0 then
        currentDriftScore = 0
      end
    end
  end

  if isExciteMission and not hasCheered and currentDriftScore > 0 and currentDriftScore > greatDriftThreshold then
    playCheerSound()
    hasCheered = true
  end
end

local pointDecreasePerSecond = 10

local function processTimeScoreDecrease(dtReal)
  local scoreDecrease = getExponentialValue(excitementScore, (pointDecreasePerSecond * dtReal * 130), 1, 0.000006)

  pointDecreasePerSecond = pointDecreasePerSecond + (dtReal * 0.08)

  if scoreDecrease < 1 then
    scoreDecrease = 1
  end

  excitementScore = excitementScore - scoreDecrease
end

local function processAirTime(dtReal)
  if isGettingAirtime then
    currentAirtimeScore = currentAirtimeScore + (airTimeScorePerSecond * dtReal)
  end
end

local function processGForceExceed(dtReal)
  if isExceedingGforce then
    currentGforceScore = currentGforceScore + (gForceScorePerSecond * dtReal)
  end
end

local function processSpeed(dtReal)
  if not playerVehicleID and MPVehicleGE.isOwn(be:getPlayerVehicle(0):getID()) then
    playerVehicleID = be:getPlayerVehicle(0):getID()
  end

  if not playerVehicleID then
    return
  end

  local fobjData = map.objects[be:getPlayerVehicle(0):getID()]
  if not fobjData then
    return
  end

  local speedKmh = metersSecondToKmHour(fobjData.vel:length())

  if speedKmh > speedExceedLimit then
    isExceedingSpeed = true
  else
    isExceedingSpeed = false
  end

  if isExceedingSpeed then
    currentSpeedScore = currentSpeedScore + (speedScorePerSecond * dtReal)
  end
end

local function tryResetAllCurrentScores(dtReal)
  if driftBonus <= 0 and driftCooldown <= 0 and not isGettingAirtime and not isExceedingGforce and not isExceedingSpeed then
    -- ran out of time, commit scores
    if fullComboCountdown <= 0 then
      excitementScore =
        excitementScore + currentDriftScore + currentAirtimeScore + currentGforceScore + currentSpeedScore

      currentDriftScore = 0
      currentAirtimeScore = 0
      currentGforceScore = 0
      currentSpeedScore = 0

      driftCooldown = 0

      hasCheered = false
    else
      -- count down
      fullComboCountdown = fullComboCountdown - dtReal
    end
  else
    -- youre doing stuff, reset countdown to 1
    fullComboCountdown = 1
  end
end

local function getDriftScore()
  -- finalize current scores so you get your right score when finishing a mission
  fullComboCountdown = 0
  tryResetAllCurrentScores(0.001)

  return excitementScore
end

local function enable(isExcitementMission)
  paxMissionActive = true
  excitementScore = 0
  pointDecreasePerSecond = 10
  clearPassengerList()

  carp_ui_passenger.showDriftPopup(true, isExcitementMission)

  if isExcitementMission then
    isExciteMission = true
  else
    isExciteMission = false
  end
end

local function disable(isNewMission)
  paxMissionActive = false
  carp_ui_passenger.showDriftPopup(false)

  if isNewMission then
    clearPassengerList()
    excitementScore = 0
  end
end

local function onUpdate(dtReal)
  if not paxMissionActive then
    return
  end

  local speedIsAboveMinimum = getSpeedKmh() > 5
  local dtScaled = bullettime.get() * dtReal --TODO: make this actually work @deer

  if bullettime.get() ~= 0 then
    if speedIsAboveMinimum then
      processDrifting(dtScaled)
      processAirTime(dtScaled)
      processGForceExceed(dtScaled)
      processSpeed(dtScaled)
    end

    tryResetAllCurrentScores(dtScaled)

    if isExciteMission then
      processTimeScoreDecrease(dtScaled)
    end
  end
end

local function getPassengerMissionData()
  return {
    excitementScore = excitementScore,
    currentDriftScore = currentDriftScore,
    currentGforceScore = currentGforceScore,
    currentAirtimeScore = currentAirtimeScore,
    currentSpeedScore = currentSpeedScore,
    driftCombo = driftCombo,
    isExciteMission = isExciteMission,
    paxCount = #passengerList
  }
end

M.onVehicleResetted = onVehicleResetted
M.onVehicleDestroyed = onVehicleDestroyed
M.onUpdate = onUpdate
M.getDriftScore = getDriftScore
M.enable = enable
M.disable = disable
M.setIsInAir = setIsInAir
M.updateGForce = updateGForce
M.getPassengerMissionData = getPassengerMissionData
M.getPassengerList = getPassengerList
M.addPassengerToList = addPassengerToList

return M
