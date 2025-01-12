local M = {}


local function finalizeSpawn(options, _vehicle)
  local firstVehicle = be:getObjectCount() == 0
  if firstVehicle then
    local player = 0
    be:enterNextVehicle(player, 0) -- enter any vehicle
  end

  local vehicle = _vehicle or be:getPlayerVehicle(0)
  if vehicle then
    if options.licenseText then
      vehicle:setDynDataFieldbyName("licenseText", 0, options.licenseText)
    end

    if options.vehicleName then
      vehicle:setField('name', '', options.vehicleName)
    end

    if be:getObjectCount() > 1 then
      if vehicle:getField('JBeam','0') ~= "unicycle" then
        ui_message("ui.hints.switchVehicle", 10, "spawn")
      end
    end
  end
end

local function spawnNewVehicle(model, opt)
  local options = sanitizeVehicleSpawnOptions(model, opt)

  -- spawn single
  local veh = spawn.spawnVehicle(model, options.config, options.pos, options.rot, options)
  finalizeSpawn(options, veh)
  return veh
end

local function removeCurrent()
  local vehicle = be:getPlayerVehicle(0)
  if vehicle then
    local playerPos = vehicle:getPosition()
    vehicle:delete()
    
    spawnNewVehicle("unicycle", { pos = playerPos })
    
    if be:getEnterableObjectCount() == 0 then
      spawnNewVehicle("unicycle", { pos = playerPos })
    end
  end
end

local function onExtensionLoaded()
		log('I', 'simpletrace', "LOAD")
end

local function onExtensionUnloaded()
	log('I', 'simpletrace', "UNLOAD")
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.removeCurrent = removeCurrent
return M