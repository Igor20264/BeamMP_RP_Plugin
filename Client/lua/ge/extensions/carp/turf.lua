local M = {}

local lastClosestWaypoint = nil

local timerDeltas = {checkClosestWaypoint = 0}
local updateRates = {checkClosestWaypoint = 2}

local function checkWaypoints()
  local mainGroup = scenetree.CarpTriggers
  if not mainGroup then
    log("I", "checkWaypoints", "not maingroup")
    return
  end

  local playerPos = be:getPlayerVehicle(0):getPosition()
  local playerPosFormatted = {
    [1] = playerPos.x,
    [2] = playerPos.y,
    [3] = playerPos.z
  }

  local closestWaypoint = nil
  local closestDistance = 999999999

  local objects = mainGroup:getObjects()

  for _, objectName in pairs(objects) do
    if string.find(objectName, "_marker") then
      local obj = Sim.findObject(objectName)

      if obj and obj.markerType == "contact" then
        local position = obj:getPosition()
        local positionFormatted = {
          [1] = position.x,
          [2] = position.y,
          [3] = position.z
        }

        local distance = distance3d(positionFormatted, playerPosFormatted)

        if distance < closestDistance then
          closestDistance = distance
          closestWaypoint = objectName
        end
      end
    end
  end

  if closestWaypoint then
    local cleanWaypointName = string.gsub(closestWaypoint, "_marker", "")

    local traderOwners = carp.getTraderOwners()

    if traderOwners and traderOwners[cleanWaypointName] and lastClosestWaypoint ~= cleanWaypointName then
    -- dump(traderOwners[cleanWaypointName])
    end
  end
end

local function onUpdate(dtReal, dtSim, dtRaw)
  --[[ for k, v in pairs(timerDeltas) do
    timerDeltas[k] = timerDeltas[k] + dtReal
  end

  if timerDeltas.checkClosestWaypoint > updateRates.checkClosestWaypoint and be:getPlayerVehicle(0) then
    timerDeltas.checkClosestWaypoint = 0

    checkWaypoints()
  end ]]
end

M.onUpdate = onUpdate

return M
