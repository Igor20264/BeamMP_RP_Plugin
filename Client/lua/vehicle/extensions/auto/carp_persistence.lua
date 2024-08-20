local M = {}

local function getSynchroWear()
  local gearbox = powertrain.getDevicesByCategory("gearbox")
  if not gearbox then
    return nil
  end

  if gearbox[1] and gearbox[1].synchroWear then
    return gearbox[1].synchroWear
  end

  return nil
end

local function loadSynchroFromFile(vehicleName)
  local data = jsonReadFile("settings/carpsettings.json")

  if data and data then
    return data
  end

  return nil
end

local function saveSynchroToFile(vehicleName)
  local carpSettings = loadSynchroFromFile(vehicleName) or {}
  if not carpSettings.synchroData then
    carpSettings.synchroData = {}
  end
  if not carpSettings.synchroData[vehicleName] then
    carpSettings.synchroData[vehicleName] = {}
  end

  carpSettings.synchroData[vehicleName] = getSynchroWear()

  jsonWriteFile("settings/carpsettings.json", carpSettings)
end

local function setSynchroWearFromSaved(vehicleName)
  local carpSettings = loadSynchroFromFile(vehicleName)
  if not carpSettings.synchroData then
    return
  end

  local currentGearbox = getSynchroWear()
  if not currentGearbox then
    return
  end

  for key, _ in pairs(currentGearbox) do
    if carpSettings.synchroData[vehicleName][tostring(key)] then
      currentGearbox[key] = carpSettings.synchroData[vehicleName][tostring(key)]

      -- prevent cringe unskilled players from making their cars entirely unusable
      if currentGearbox[key] > 0.98 then
        currentGearbox[key] = 0.98
      end
    end
  end
end

local function clearSynchroWear(vehicleName)
  local carpSettings = loadSynchroFromFile(vehicleName)
  if not carpSettings.synchroData or not carpSettings.synchroData[vehicleName] then
    return
  end

  local currentGearbox = getSynchroWear()
  if not currentGearbox then
    return
  end

  for key, value in pairs(currentGearbox) do
    currentGearbox[key] = 0
  end

  jsonWriteFile("settings/carpsettings.json", carpSettings)
end

M.getSynchroWear = getSynchroWear
M.loadSynchroFromFile = loadSynchroFromFile
M.saveSynchroToFile = saveSynchroToFile
M.setSynchroWearFromSaved = setSynchroWearFromSaved
M.clearSynchroWear = clearSynchroWear
return M
