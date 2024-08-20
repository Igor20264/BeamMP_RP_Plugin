local M = {}

local vehID = nil
local timer = 0 -- used for updating carp.lua's gForce tracker
local gSoundTimer = 0 -- used for updating when we can play g sounds again
local isActive = false

local maxG_X = 0
local maxG_Y = 0
local maxG_Z = 0

local currentGForce = 0

local soundMaxLevelAchieved = 0

local function resetMaxGees()
  maxG_X = 0
  maxG_Y = 0
  maxG_Z = 0
  soundMaxLevelAchieved = 0
end

local function onInit()
  if not vehID then
    vehID = obj:getID()
  end

  if vehID and vehID ~= obj:getID() then
    vehID = obj:getID()
  end
end

local function onReset()
  if not vehID then
    vehID = obj:getID()
  end
end

local function playGeeSound(newMaxGees)
  if newMaxGees > 3 and soundMaxLevelAchieved < 3 then
    local randomNumber = math.random(1, 14)
    local audioName = "audio/scream-xl-" .. randomNumber .. ".ogg"

    obj:queueGameEngineLua('playCarpSound("' .. audioName .. '")')

    soundMaxLevelAchieved = 3
  elseif newMaxGees > 2 and soundMaxLevelAchieved < 2 then
    local randomNumber = math.random(1, 12)
    local audioName = "audio/scream-m-" .. randomNumber .. ".ogg"

    obj:queueGameEngineLua('playCarpSound("' .. audioName .. '")')

    soundMaxLevelAchieved = 2
  elseif newMaxGees > 1 and soundMaxLevelAchieved < 1 then
    local randomNumber = math.random(1, 24)
    local audioName = "audio/scream-s-" .. randomNumber .. ".ogg"

    obj:queueGameEngineLua('playCarpSound("' .. audioName .. '")')

    soundMaxLevelAchieved = 1
  end
end

local function updateGFX(dt)
  if not v.mpVehicleType == 'L' then return end
  if not isActive then
    return
  end

  -- update G-force values
  local newValueX = math.abs(sensors.gx) / 9.81
  maxG_X = math.max(maxG_X, newValueX)

  local newValueY = math.abs(sensors.gy) / 9.81
  maxG_Y = math.max(maxG_Y, newValueY)

  local newValueZ = (math.abs(sensors.gz) / 9.81) - 1
  maxG_Z = math.max(maxG_Z, newValueZ)

  local biggestGforce = math.max(newValueX, newValueY)
  biggestGforce = math.max(newValueY, newValueZ)

  if isActive == "normal" then
    -- reset sound playing
    if soundMaxLevelAchieved ~= 0 then
      if gSoundTimer > 2400 then
        soundMaxLevelAchieved = 0
        gSoundTimer = 0
      else
        gSoundTimer = gSoundTimer + 1
      end
    end

    -- send carp.lua g values
    if timer > 60 then
      obj:queueGameEngineLua("carp.updateMaxGees('" .. maxG_X .. "@" .. maxG_Y .. "@" .. maxG_Z .. "')")

      timer = 0
    else
      timer = timer + 1
    end

    playGeeSound(biggestGforce)
  elseif isActive == "excitement" then
    obj:queueGameEngineLua(
      "if carp_ui_passenger then carp_passengers.updateGForce('" .. obj:getID() .. "','" .. biggestGforce .. "') end"
    )
  end
end

local function setActive(active)
  isActive = active

  if (active == "normal") then
    local randomNumber = math.random(1, 17)
    local audioName = "audio/hello-" .. randomNumber .. ".ogg"

    obj:queueGameEngineLua('playCarpSound("' .. audioName .. '")')
  end
end

M.onInit = onInit
M.onReset = onReset
M.updateGFX = updateGFX
M.maxG_X = maxG_X
M.maxG_Y = maxG_Y
M.maxG_Z = maxG_Z
M.setActive = setActive
M.resetMaxGees = resetMaxGees
M.currentGForce = currentGForce

return M
