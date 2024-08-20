local M = {}

local rainbowEnabled = false
local rainbowOffset = 0
local currentRainbowColor = nil
local disableNextFrame = nil -- used for delaying setAll by a frame

navigationPrefs = {
  drivabilityCutoff = 0.6
}

local function getPointToPointDistance(from, to, ...)
  local path = map.getPointToPointPath(from, to, ...)
  local dist = 0
  local mapCache = map.getMap()

  local lastNodeName = nil

  for i, currNode in ipairs(path) do
    local nextNode = path[i + 1]
    if nextNode then
      dist = dist + vec3(mapCache.nodes[currNode].pos):distance(vec3(mapCache.nodes[nextNode].pos))
    end
    lastNodeName = currNode
  end

  return dist, lastNodeName
end

local function findClosestRoadWithCutoff(targetPosition, drivabilityCutoff)
  local nodes = map.findNClosestNodes(targetPosition, 50)
  local mapData = map.getMap()

  for i, nodeData in ipairs(nodes) do
    local n1Name = nodeData[1]
    local node1 = mapData.nodes[n1Name]
    local n2Name, link = next(node1.links)
    local node2 = mapData.nodes[n2Name]

    if link and link.drivability >= navigationPrefs.drivabilityCutoff then -- these nodes make a good enough quality road
      -- find which node is closest
      local sqrDist1 = (targetPosition - node1.pos):squaredLength()
      local sqrDist2 = (targetPosition - node2.pos):squaredLength()

      if sqrDist1 < sqrDist2 then
        return n1Name, math.sqrt(sqrDist1)
      else
        return n2Name, math.sqrt(sqrDist2)
      end
    end
  end

  local firstNodeData = nodes[1] -- these are already sorted by distance
  if firstNodeData then
    return firstNodeData[1], firstNodeData[2] -- first element is the name
  else
    return nil
  end
end

local function findClosestRoad(targetPosition)
  local first, second, distance = map.findClosestRoad(targetPosition)
  if not first or not second then
    return false
  end

  local mapData = map.getMap()
  local node1 = mapData.nodes[first]
  local node2 = mapData.nodes[second]
  if node1 and node2 then
    -- find which node is closest
    local sqrDist1 = (targetPosition - node1.pos):squaredLength()
    local sqrDist2 = (targetPosition - node2.pos):squaredLength()

    if sqrDist1 < sqrDist2 then
      return first, math.sqrt(sqrDist1)
    else
      return second, math.sqrt(sqrDist2)
    end
  end
  return nil
end

local function clearFocus()
  core_groundMarkers.resetAll()
  core_groundMarkers.sendToApp()
end

local function setFocus(point, color)
  if type(point) == "cdata" then -- make sure the target is a node name (string) and not vec3 or Point3F
    point = findClosestRoad(point)
  end
  if carp_ui_base.getUISetting("disable_groundmarkers") then
    disableNextFrame = true
  end
  core_groundMarkers.setFocus(point, nil, nil, nil, nil, nil, color)
end

local function setDestination(pos, color, playSound)
  clearFocus()
  setFocus(pos, color)

  local rand = math.random(3)

  if not playSound then
    return
  end

  if rand == 1 then
    playCarpSound("audio/ok_queen.ogg")
  elseif rand == 2 then
    playCarpSound("audio/ok_cowboy.ogg")
  else
    playCarpSound("audio/recalculating_route.ogg")
  end
end

local function sendToAppWithColor()
  local c = rainbowEnabled and currentRainbowColor or core_groundMarkers.color
  local data = {
    markers = {},
    color = string.format("#%02X%02X%02XFF", c[1] * 255, c[2] * 255, c[3] * 255)
  }
  local id = 1
  for i, e in ipairs(core_groundMarkers.routePlanner.path) do
    data.markers[id] = e.pos.x
    data.markers[id + 1] = e.pos.y
    id = id + 2
  end

  guihooks.trigger("NavigationGroundMarkersUpdate", data)
end

local function customRainbowColor(numOfSteps, step, format)
  local x = step / math.max(numOfSteps, 1e-10)
  local r = math.min(1, math.max(0, 2 - math.abs(6 * x - 4)))
  local g = math.min(1, math.max(0, 2 - math.abs(6 * x - 2)))
  local b = math.min(1, math.max(0, math.abs(6 * x - 3) - 1))
  if (format or 255) == 255 then
    return {math.floor(r*255), math.floor(g*255), math.floor(b*255), 255}
  else
    return {r, g, b, 1}
  end
end

local function stepRGB(offset)
  local activeDecals = {}
  for i = 1, core_groundMarkers.decalPoolCount do
    if core_groundMarkers.decalPool[i].color.a > 0 then
      table.insert(activeDecals, i)
    end
  end
  currentRainbowColor = customRainbowColor(core_groundMarkers.decalPoolCount, 1 + offset, 1)

  for i, _ in ipairs(activeDecals) do
    local c = customRainbowColor(core_groundMarkers.decalPoolCount, (i + offset) % core_groundMarkers.decalPoolCount, 1)
    core_groundMarkers.decalPool[i].color.r = c[1]
    core_groundMarkers.decalPool[i].color.g = c[2]
    core_groundMarkers.decalPool[i].color.b = c[3]
  end
end

function setAll(r, g, b, a)
  local defaultColor = ColorF(r, g, b, a)

  for i = 1, core_groundMarkers.decalPoolCount do
    core_groundMarkers.decalPool[i].color = defaultColor
  end
end

local function enableRainbow()
  rainbowOffset = 0
  rainbowEnabled = true
  --core_groundMarkers.sendToApp = sendToAppWithColor
end

local function disableRainbow()
  rainbowOffset = 0
  rainbowEnabled = false
  currentRainbowColor = nil

  local c = core_groundMarkers.color

  if not c then
    return
  end -- no route has been made yet

  for i = 1, core_groundMarkers.decalPoolCount do
    core_groundMarkers.decalPool[i].color.r = c[1]
    core_groundMarkers.decalPool[i].color.g = c[2]
    core_groundMarkers.decalPool[i].color.b = c[3]
  end
end

local function onClientEndMission()
  clearFocus()
end

local function onExtensionLoaded()
    AddEventHandler("onClientEndMission", onClientEndMission)
    AddEventHandler("disableNaviRainbow", disableRainbow)
    AddEventHandler("enableNaviRainbow", enableRainbow)
    log("I", "carp_groundmarkers", "onExtensionLoaded")
end

local function onPreRender()
  if rainbowEnabled then
    rainbowOffset = rainbowOffset + 0.1
    stepRGB(rainbowOffset)
  end
  if disableNextFrame then
    setAll(0, 0, 0, 0)
    disableNextFrame = false
  end
end

--M.enableRainbow = enableRainbow
--M.disableRainbow = disableRainbow

M.findClosestRoadWithCutoff = findClosestRoadWithCutoff
M.findClosestRoad = findClosestRoad
M.getPointToPointDistance = getPointToPointDistance
M.clearFocus = clearFocus
M.setFocus = setFocus
M.setDestination = setDestination

M.onExtensionLoaded = onExtensionLoaded
M.onPreRender = onPreRender

return M
