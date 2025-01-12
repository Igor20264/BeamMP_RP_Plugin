local M = {}
local afkTimer = 0
local timer = 0
local lastPos = nil


local function onUpdate(deltaTime)
  timer = timer + deltaTime
  if timer >= 1 then
    timer = 0

        local getVehicleID = be:getPlayerVehicle(0):getId()
        if MPVehicleGE and MPVehicleGE.isOwn(getVehicleID) then
            local pos = be:getPlayerVehicle(0):getPosition()
            local xOffset = math.abs(lastPos.x - pos.x)
            local yOffset = math.abs(lastPos.y - pos.y)
            local zOffset = math.abs(lastPos.z - pos.z)
            if xOffset > 0.001 or yOffset > 0.001 or zOffset > 0.001 then
                lastPos = pos
                afkTimer = 0
            else
                afkTimer = afkTimer + deltaTime
                if afkTimer > 600 then
                    TriggerServerEvent('IMAFK')
                end
            end
        end
    end
end



local function onExtensionLoaded()
    log("I", "BeamMP_RP_Plugin - Antiafk", "Extension Loaded")
end

local function onVehicleSwitched()
    lastPos = be:getPlayerVehicle(0):getPosition()
    afkTimer = 0
end

local function onExtensionUnloaded()
    log("I", "BeamMP_RP_Plugin - Antiafk", "Extension Loaded")
end
--M.onVehicleSwitched = onVehicleSwitched
--M.onExtensionLoaded = onExtensionLoaded
--M.onExtensionUnloaded = onExtensionUnloaded
--M.onUpdate = onUpdate
return M;
