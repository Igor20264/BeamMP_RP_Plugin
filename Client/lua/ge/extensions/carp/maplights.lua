local M = {}

M.dependencies = {"carp_ui_base"}

local currTime = 0
local updateTime = 0.1 -- how much to wait between checks for distance, in seconds

local turnedLightsOff = nil

local customLightsOnly = false

local fadeLights = true

local carpLights = nil
local carpLightsBrightness = nil

local lightDistanceTreshold = 100
local lightShouldCastShadowDistanceTreshold = 30

local lightShouldCastShadowDistanceTresholdSquared =
  lightShouldCastShadowDistanceTreshold * lightShouldCastShadowDistanceTreshold

local function getCarpLightsGroup()
  carpLights = {}
  carpLightsBrightness = {}

  if customLightsOnly then
    carpLights = scenetree.CarpLights

    if carpLights then
      carpLights = carpLights:getObjects()
    end

    if carpLights then
      for idx, name in pairs(carpLights) do
        local light = scenetree.findObject(name)
        if not light or not string.find(light:getClassName(), "Light") then
          table.remove(carpLights, idx)
        else
          carpLightsBrightness[name] = light.brightness
        end
      end
    end
  else
    for _, name in ipairs(scenetree.findClassObjects("SpotLight")) do
      local light = scenetree.findObject(name)
      if light then
        table.insert(carpLights, name)
        carpLightsBrightness[name] = light.brightness
      end
    end
    for _, name in ipairs(scenetree.findClassObjects("PointLight")) do
      local light = scenetree.findObject(name)
      if light then
        table.insert(carpLights, name)
        carpLightsBrightness[name] = light.brightness
      end
    end
  end
end

local function toggleAllLights(state)
  log("I", "toggleAllLights", "Turning all map lights " .. (state and "on" or "off"))

  for idx, name in pairs(carpLights) do
    local thisLight = scenetree.findObject(name)

    thisLight.isEnabled = state
  end
end

-- this only runs if its nighttime
local function updateLightsDistance()
  if not carp_ui_base or not carp_ui_base.getUISetting("distance_lights_enabled") then
    return
  end

  local cameraPos = getCameraPosition()
  local playerVeh = be:getPlayerVehicle(0)
  local lightDistanceTresholdSquared =
    carp_ui_base.getUISetting("distance_lights_distance") * carp_ui_base.getUISetting("distance_lights_distance")

  if playerVeh and (not cameraPos or not commands.isFreeCamera()) then
    cameraPos = playerVeh:getPosition()
  end

  if not cameraPos then
    return
  end

  for idx, name in pairs(carpLights) do
    local thisLight = scenetree.findObject(name)

    if not thisLight then
      return
    end

    local lightPosition = thisLight:getPosition()

    if not lightPosition then
      return
    end

    local squaredDistance = vec3(cameraPos):squaredDistance(lightPosition)

    -- should this light be enabled
    if squaredDistance < lightDistanceTresholdSquared then
      if fadeLights and carpLightsBrightness[name] then
        local brightnessCoef = linearScale(squaredDistance, lightDistanceTresholdSquared, 25, 0, 1)

        local brightnessScaled = carpLightsBrightness[name] * brightnessCoef

        thisLight.brightness = brightnessScaled
      end

      thisLight.isEnabled = true

      -- enable/disable shadows
      if squaredDistance < lightShouldCastShadowDistanceTresholdSquared then
        thisLight.castShadows = true
      else
        thisLight.castShadows = false
      end
    else
      thisLight.isEnabled = false
    end
  end
end

local function updateLightsTime()
  local tod = core_environment.getTimeOfDay()

  if not tod then
    return
  end

  if not carpLights then
    getCarpLightsGroup()
    return
  end

  if not carp_timesync.shouldLightsBeOn(tod.time) then -- reached daytime
    if not turnedLightsOff then
      toggleAllLights(false)
      turnedLightsOff = true
    end
  else
    turnedLightsOff = false
    updateLightsDistance()
  end
end

local function onUpdate(dtReal, dtSim, dtRaw)
  currTime = currTime + dtReal

  if currTime >= updateTime then
    currTime = 0
    updateLightsTime()
  end
end

local function invalidateCache()
  carpLights = nil
end

M.onUpdate = onUpdate
M.invalidateCache = invalidateCache

return M
