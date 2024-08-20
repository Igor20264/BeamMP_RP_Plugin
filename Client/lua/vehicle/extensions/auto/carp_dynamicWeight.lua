local M = {}

local weightPartNodes = {}

local BASE_CARGO_WEIGHT_PER_UNIT = 15 -- we multiply this by a random range of 0.5 - 1.5 for more randomness between missions
local humanWeight = 80

local DEFAULT_NEW_WEIGHT = 50

-- this will populate the weightParts object with the names of the parts, the nodes, and the count of the nodes
local function getNodes(partName)
  local tempObject = {}
  local counter = 0

  -- find the coupler nodes so we don't use them
  --v.data['doorRLCoupler'].couplerNodes[2]
  local couplerNodes = ""
  for name, cNodes in pairs(v.data) do
    if (string.find(name, "Coupler") ~= nil or string.find(name, "Latch") ~= nil) then
      for i = 2, #cNodes.couplerNodes, 1 do
        couplerNodes = couplerNodes .. cNodes.couplerNodes[i][1] .. "," .. cNodes.couplerNodes[i][2] .. ","
      end
    end
  end

  for k, v in pairs(v.data.nodes) do
    if v.name then
      -- if (string.match(v.partOrigin, partName) and
      if
        (string.find(v.partOrigin, partName) ~= nil and string.find(v.partOrigin, "subframe") == nil and
          string.find(v.partOrigin, "pigeon_bed") == nil and
          string.find(v.partOrigin, "muffler") == nil and
          string.find(v.partOrigin, "bedcover") == nil and
          string.find(v.partOrigin, "campershell") == nil and
          string.find(v.partOrigin, "wigeon_door") == nil and
          string.find(v.partOrigin, "wigeon_tailgate") == nil and
          string.find(v.partOrigin, "sidepipe") == nil and
          string.find(v.partOrigin, "seat_FL") == nil and
          string.find(couplerNodes, v.name) == nil)
       then --ignoring all those parts above
        -- if we find a node linked to the partname we need, get it and it's info
        -- create entry if needed
        if (weightPartNodes[v.partOrigin] == nil) then
          weightPartNodes[v.partOrigin] = {}
          counter = counter + 1
        end
        if (tempObject[v.partOrigin] == nil) then
          tempObject[v.partOrigin] = {}
          tempObject[v.partOrigin]["nodeList"] = {}
          tempObject[v.partOrigin]["numNodes"] = 0
          tempObject[v.partOrigin]["totalWeight"] = 0
        end

        -- if (tempObject[v.partOrigin]["numNodes"] < 80) then
        table.insert(tempObject[v.partOrigin]["nodeList"], {id = v.cid, originalWeight = v.nodeWeight})
        tempObject[v.partOrigin]["numNodes"] = tempObject[v.partOrigin]["numNodes"] + 1
        tempObject[v.partOrigin]["totalWeight"] = tempObject[v.partOrigin]["totalWeight"] + v.nodeWeight
      -- end
      end
    end
  end

  for k, v in pairs(tempObject) do
    weightPartNodes[k] = tempObject[k]
  end

  for k, v in pairs(weightPartNodes) do
    weightPartNodes[k]["averageWeight"] = weightPartNodes[k]["totalWeight"] / weightPartNodes[k]["numNodes"]
  end

  return counter
end

local function resetWeights(whichNodes)
  for k, v in pairs(weightPartNodes) do
    if (whichNodes ~= nil and k ~= whichNodes) then
      -- do nothing
    else
      local newNodeWeight = weightPartNodes[k]["totalWeight"] / weightPartNodes[k]["numNodes"]

      for m, n in pairs(weightPartNodes[k]["nodeList"]) do
        obj:setNodeMass(n.id, n.originalWeight)
      end
    end
  end
  weightPartNodes = {}
end

-- which nodes is not currently used (and probably shouldn't because it isn't needed), so
-- this just makes sure all nodes are set to the weight they should be
local function setNodeWeights(whichNodes)
  for k, v in pairs(weightPartNodes) do
    if (whichNodes ~= nil and k ~= whichNodes) then
      -- do nothing
    else
      local newWeight = (weightPartNodes[k] and weightPartNodes[k]["newWeight"]) or DEFAULT_NEW_WEIGHT

      local newNodeWeight = newWeight / weightPartNodes[k]["numNodes"]

      for m, n in pairs(weightPartNodes[k]["nodeList"]) do
        obj:setNodeMass(n.id, n.originalWeight + newNodeWeight)
      end
    end
  end
end

-- deprecated, but leaving in case we need it at some point; totalWeights makes way more sense for now
local function setPartWeights(part, newWeight)
  if (part == nil) then
    return
  end

  if (newWeight == nil) then
    newWeight = DEFAULT_NEW_WEIGHT
  end

  getNodes(part)

  for k, v in pairs(weightPartNodes) do
    if (string.find(k, part) ~= nil) then
      weightPartNodes[k]["newWeight"] = newWeight
    end
  end

  setNodeWeights()
end

---- part can either be a string, or a table of strings {'door', 'frame'}
local function setPartTotalWeights(part, newWeight)
  local partsCount = 0

  if (part == nil) then
    return
  end

  if (newWeight == nil) then
    newWeight = 250
  end

  if (type(part) == "table") then
    for _, name in pairs(part) do
      getNodes(name)
    end
  else
    getNodes(part)
  end

  -- one loop to find how many, one loop to set the weights
  for k, v in pairs(weightPartNodes) do
    if (type(part) == "table") then
      for _, name in pairs(part) do
        if
          (string.find(k, name) ~= nil and string.find(name, "subframe") == nil and
            string.find(name, "pigeon_bed") == nil and
            string.find(name, "muffler") == nil and
            string.find(name, "sidepipe") == nil and
            string.find(name, "bedcover") == nil and
            string.find(name, "wigeon_door") == nil and
            string.find(name, "wigeon_tailgate") == nil and
            string.find(name, "seat_FL") == nil and
            string.find(name, "campershell") == nil)
         then -- never apply to subframes
          partsCount = partsCount + 1
        end
      end
    else
      if
        (string.find(k, part) ~= nil and string.find(part, "subframe") == nil and string.find(part, "pigeon_bed") == nil and
          string.find(part, "muffler") == nil and
          string.find(part, "sidepipe") == nil and
          string.find(part, "bedcover") == nil and
          string.find(part, "wigeon_door") == nil and
          string.find(part, "wigeon_tailgate") == nil and
          string.find(part, "seat_FL") == nil and
          string.find(part, "campershell") == nil)
       then
        partsCount = partsCount + 1
      end
    end
  end

  if (partsCount == 0) then
    return
  end

  newWeight = newWeight / partsCount

  -- set weights for all those parts!
  for k, v in pairs(weightPartNodes) do
    if (type(part) == "table") then
      for _, name in pairs(part) do
        if
          (string.find(k, name) ~= nil and string.find(name, "subframe") == nil and
            string.find(name, "pigeon_bed") == nil and
            string.find(name, "muffler") == nil and
            string.find(name, "sidepipe") == nil and
            string.find(name, "bedcover") == nil and
            string.find(name, "wigeon_door") == nil and
            string.find(name, "wigeon_tailgate") == nil and
            string.find(name, "seat_FL") == nil and
            string.find(name, "campershell") == nil)
         then
          weightPartNodes[k]["newWeight"] = newWeight
        end
      end
    else
      if
        (string.find(k, part) ~= nil and string.find(name, "subframe") == nil and string.find(name, "pigeon_bed") == nil and
          string.find(name, "muffler") == nil and
          string.find(name, "sidepipe") == nil and
          string.find(name, "bedcover") == nil and
          string.find(name, "wigeon_door") == nil and
          string.find(name, "wigeon_tailgate") == nil and
          string.find(name, "seat_FL") == nil and
          string.find(name, "campershell") == nil)
       then
        weightPartNodes[k]["newWeight"] = newWeight
      end
    end
  end

  setNodeWeights()
end

-- for simple calling to set cargo weight on vehicles from carplua
local function setCargoWeightsGeneric(cargoCapacity, slots)
  if (cargoCapacity == nil) then
    cargoCapacity = 25
  end

  local targetSlots =
    slots or
    {
      "_frame",
      "_body",
      "crate",
      "fridge",
      "chair",
      "couch",
      "pickup_bed",
      "mattress",
      "upfit_pipes",
      "upfit_smallpipes",
      "midtruck_6w_load",
      "midtruck_4w_load",
      "cargo_load_box"
    }
  setPartTotalWeights(targetSlots, cargoCapacity)
end

local function setCargoWeightsBolide(cargoCapacity)
  setCargoWeightsGeneric(
    cargoCapacity,
    {
      "engine",
      "crate",
      "fridge",
      "chair",
      "couch",
      "mattress",
      "cargo_load_box"
    }
  )
end

local function setCargoWeightsCovet(cargoCapacity)
  setCargoWeightsGeneric(
    cargoCapacity,
    {
      "_frame",
      "transmission",
      "transaxle",
      "seat",
      "crate",
      "fridge",
      "chair",
      "couch",
      "mattress",
      "cargo_load_box"
    }
  )
end

local function setCargoWeightsScintilla(cargoCapacity)
  setCargoWeightsGeneric(
    cargoCapacity,
    {
      "scintilla_frunk",
      "scintilla_engine",
      "crate",
      "fridge",
      "chair",
      "couch",
      "cargo_load_box"
    }
  )
end

local function addPassengerToUIList(weight)
  obj:queueGameEngineLua("carp_passengers.addPassengerToList(" .. weight .. ")")
end

local function setSeatWeightsGeneric(newWeight, numOfPassengers)
  if (newWeight == nil) then
    newWeight = humanWeight
  end

  getNodes("seat")

  local passengersAdded = 0

  while passengersAdded < numOfPassengers do
    for k, v in pairs(weightPartNodes) do
      if (string.find(k, "seat") ~= nil) and passengersAdded < numOfPassengers then
        local weightMultiplier = 1
        local paxWeight = newWeight * weightMultiplier

        addPassengerToUIList(paxWeight)
        passengersAdded = passengersAdded + 1

        if weightPartNodes[k]["newWeight"] then
          weightPartNodes[k]["newWeight"] = weightPartNodes[k]["newWeight"] + paxWeight
        else
          weightPartNodes[k]["newWeight"] = math.floor(paxWeight)
        end
      end
    end
  end

  setNodeWeights()
end

local function setSeatWeightsBolide(newWeight, numOfPassengers)
  if (newWeight == nil) then
    newWeight = humanWeight
  end

  local totalWeight = 0

  local frontLeft = false
  local frontRight = false

  -- getNodes('seat')

  for k, v in pairs(v.data.nodes) do
    if v.name then
      if (string.find(v.partOrigin, "seat_FL")) then
        frontLeft = true
      elseif (string.find(v.partOrigin, "seat_FR")) then
        frontRight = true
      end
    end
  end

  local weightMultiplier = 1
  local paxWeight = newWeight * weightMultiplier
  addPassengerToUIList(paxWeight)

  if (frontLeft) then
    totalWeight = totalWeight + (newWeight * weightMultiplier)
  end

  if (frontRight) then
    weightMultiplier = 1
    totalWeight = totalWeight + (newWeight * weightMultiplier)
  end

  setPartTotalWeights({"engine"}, totalWeight)
end

local function setCargoWeights(...)
  local model = v.data.model

  if model == "bolide" then
    setCargoWeightsBolide(...)
  elseif model == "covet" then
    setCargoWeightsCovet(...)
  elseif model == "scintilla" then
    setCargoWeightsScintilla(...)
  else
    setCargoWeightsGeneric(...)
  end
end

local function setSeatWeights(...)
  local model = v.data.model

  if model == "bolide" then
    setSeatWeightsBolide(...)
  else
    setSeatWeightsGeneric(...)
  end
end

print("Carp dynamic weight loaded.")

M.getNodes = getNodes

M.setSeatWeights = setSeatWeights
M.setCargoWeights = setCargoWeights
M.setNodeWeights = setNodeWeights
M.setPartWeights = setPartWeights
M.setPartTotalWeights = setPartTotalWeights

M.resetWeights = resetWeights

return M
