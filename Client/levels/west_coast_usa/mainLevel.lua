local M = {}

local envObjectIdCache = {}

local function getObject(className)
  if envObjectIdCache[className] then
    if envObjectIdCache[className] == 0 then return nil end
    return scenetree.findObjectById(envObjectIdCache[className])
  end
  envObjectIdCache[className] = 0
  local objNames = scenetree.findClassObjects(className)
  if objNames and not tableIsEmpty(objNames) then
    local obj = scenetree.findObject(objNames[1])
    if obj then
      envObjectIdCache[className] = obj:getID()
      return obj
    end
  end
  return nil
end


local function forceApply()
  core_environment.setTimeOfDay(core_environment.getTimeOfDay())
end

local function overrideNightcolor(value)
  local scatterSkyObj = getObject("ScatterSky")
  if scatterSkyObj then
    scatterSkyObj.nightColor = Point4F(value, value, value, 1.0)
  end
end

local function onUpdate()
  core_environment.setNightGradientFile("")
  overrideNightcolor(0.42)
  forceApply()
end

M.onUpdate = onUpdate

return M
