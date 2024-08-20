local M = {}

local function updateInventoryWeight(inventory)
  local totalWeight = 0

  if not inventory then
    carp.setInventoryVehicleWeight(0)
    return
  end

  for _, item in pairs(inventory) do
    if not item.weight then
      return
    end

    totalWeight = totalWeight + item.weight
  end

  carp.setInventoryVehicleWeight(totalWeight)
  carp.requestVehicleWeightUpdate()
end

local function getLastInventoryMissionItem()
  local lastDestination = nil

  local inventory = carp_ui_vehicleinventory.getCurrentInventory() -- this should be here instead of in the ui :(

  for _, item in pairs(inventory) do
    if item.destination then
      lastDestination = item.destination
    end
  end

  if lastDestination then
    TriggerServerEvent("receiveGetNavigationToWaypoint", lastDestination)
  end
end

M.updateInventoryWeight = updateInventoryWeight
M.getLastInventoryMissionItem = getLastInventoryMissionItem

return M
