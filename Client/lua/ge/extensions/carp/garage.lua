local M = {}

local previousFOV
local previousDefaultRotation

local function resetCamera()
  local camData = core_camera.getCameraDataById(be:getPlayerVehicleID(0))
  if camData and camData.orbit then
    camData.orbit:setMaxDistance(nil)
    camData.orbit:setDefaultRotation(previousDefaultRotation)
    camData.orbit:setFOV(previousFOV)
    camData.orbit:setSkipFovModifier(false)
    camData.orbit:init()
  end
end

M.resetCamera = resetCamera

return M
