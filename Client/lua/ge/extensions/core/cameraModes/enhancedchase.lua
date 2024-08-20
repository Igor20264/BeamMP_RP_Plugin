-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local collision = require('core/cameraModes/collision')

local function rotateVectorAroundZAxis(vector, angleDeg)

    local angle = math.rad(angleDeg)

    local rotationMatrix = {
        {math.cos(angle), -math.sin(angle), 0},
        {math.sin(angle), math.cos(angle), 0},
        {0, 0, 1}
    }

    local rotatedVector = vec3(
            vector.x * rotationMatrix[1][1] + vector.y * rotationMatrix[1][2] + vector.z * rotationMatrix[1][3],
            vector.x * rotationMatrix[2][1] + vector.y * rotationMatrix[2][2] + vector.z * rotationMatrix[2][3],
            vector.x * rotationMatrix[3][1] + vector.y * rotationMatrix[3][2] + vector.z * rotationMatrix[3][3]
    )

    return rotatedVector
end

local C = {}
C.__index = C

function C:init()
  self.disabledByDefault = false
  self.camResetted = 2
  self.lastVel = nil
  self.lastCamPos = vec3()
  self.lastDir = vec3()
  self.dirSmoothX = newTemporalSpring(20, 8)
  self.dirSmoothY = newTemporalSpring(60, 10)
  self.dirSmoothZ = newTemporalSmoothingNonLinear(8, 8)
  self.smoothHeight = newTemporalSpring(50, 5)
  self.smoothVel = newTemporalSpring(10, 5)
  self.smoothYawX = newTemporalSmoothing(5, 5, 2, 0)
  self.smoothYawY = newTemporalSmoothing(5, 5, 2, 0)
  self.upSmoothingX = newTemporalSmoothingNonLinear(0.9, 0.9, 0)
  self.upSmoothingZ = newTemporalSmoothingNonLinear(0.6, 0.6, 0)
  self.c_time = 0

  self.collision = collision()
  self.collision:init()

  self:onSettingsChanged()
end

function C:onSettingsChanged()
  self.fov_max = settings.getValue('eccMaxFov', 76)
  self.fxGforceStrength = vec3(
          settings.getValue('eccFxGforceX', 1),
          settings.getValue('eccFxGforceY', 1),
          settings.getValue('eccFxGforceZ', 1))
  self.camDistance = settings.getValue('eccCamDist', 0)
  self.camPitch = settings.getValue('eccCamHeight', 0.4)
  self.camAngle = math.tan(math.rad(settings.getValue('eccCamAngle', 15)))
  self.fxShakeStrength = settings.getValue('eccFxShake', 1)
  self.fxVelStrength = settings.getValue('eccFxVelX', 1)
  self.fxVelYStrength = settings.getValue('eccFxVelY', 1)
  self.fxVelZStrength = settings.getValue('eccFxVelZ', 1)
  self.fxRollStrength = settings.getValue('eccFxRoll', 1)
  self.fxZbounce = settings.getValue('eccFxZbounce', true)
  self.fov = self.fov_max * 0.68
end

function C:onVehicleCameraConfigChanged()
  self.camResetted = self.camResetted + 2
end

function C:reset()
  self.camResetted = self.camResetted + 1
  self.lastVel = nil
end


local front = vec3(0, 1, 0)
local s = 1.2
local rear, top = 0, 0
local camerarot
local bboxoffset, bboxoffset2, center = vec3(), vec3(), vec3()
local camOffset, targetOffset = vec3(), vec3()
local g_forces, shake_vec = vec3(), vec3()


function C:update(data)
  data.res.collisionCompatible = true

  self.c_time = self.c_time + data.dt

  -- camera offset control
  camerarot = ((math.atan2(
          self.smoothYawX:get(MoveManager.yawLeft - MoveManager.yawRight, data.dt),
          self.smoothYawY:get(MoveManager.pitchUp - MoveManager.pitchDown, data.dt))/math.pi) * 180) % 360
  --camerarot = self.smoothYaw:get(camerarot, data.dt)

  local cameradist = (MoveManager.zoomIn - MoveManager.zoomOut)
  self.camDistance = clamp(self.camDistance + cameradist * 0.1, -0.4, 5)

  -- vehicle offsets
  local ref  = data.veh:getNodePosition(self.refNodes.ref)
  local left = data.veh:getNodePosition(self.refNodes.left)
  local back = data.veh:getNodePosition(self.refNodes.back)
  center:setLerp(back, left, 0.5)

  local dir = (ref - back); dir = dir:normalized()

  local dir_l = (left - ref); dir_l:normalized()
  local dir_up = dir:cross(dir_l)

  local quat_dir_z = quatFromDir(dir, dir_up)
  local quat_dir = quatFromDir(dir)
  local rev_dir = quat_dir:conjugated()

  -- reset stuff
  if self.camResetted > 1 then
    rear = -data.veh:getSpawnWorldOOBBRearPoint():distance(data.veh:getBBCenter())
    top = -rear * 0.34
    bboxoffset = (data.veh:getBBCenter() - (data.pos + center)):rotated(rev_dir)
    bboxoffset.x = 0
  end

  bboxoffset2 = bboxoffset:rotated(quat_dir_z)

  if self.camResetted > 0 then
    log("D", "ECC", self.camResetted)
    self.lastVel = dir
    self.smoothHeight:set(data.pos.z)
    self.upSmoothingX:set(0)
    self.upSmoothingZ:set(0)
    self.dirSmoothX:set(0)
    self.dirSmoothY:set(0)
    self.dirSmoothZ:set(0)
    self.lastCamPos:set(data.pos)
    self.camResetted = 0
  end

  local dvel = data.vel - data.prevVel
  local accel = (dvel / data.dt)
  local l_accel = accel:rotated(rev_dir)
  local l_vel = data.vel:rotated(rev_dir)
  local vel_dir = data.vel:normalized()

  vel_dir:setLerp(self.lastVel, vel_dir, 0.06)

  if data.vel:length() > 1 then
    self.lastVel = vel_dir
  else
    vel_dir = self.lastVel
  end

  local dir_diff = vec3(); dir_diff:setLerp(dir, vel_dir, 0.69)
  --local dir_diff = vec3(); dir_diff:setLerp(dir, vel_dir, 0.69 - math.abs(l_accel.x) * 0.01 + math.abs(l_vel.x) * 0.01)
  dir_diff:normalized(); dir_diff = dir_diff:z0()


  if data.lookBack == true then
    camerarot = 180
  end

  dir_diff = rotateVectorAroundZAxis(dir_diff, camerarot)


  local vel_dir_quat = quatFromDir(dir_diff)


  local vel_s = clamp(math.exp((-100 / data.vel:length())+2), 0, 1)
  local shake_x = vel_s * math.sin(2 * math.pi * 16 * (self.c_time + data.dt * math.random()))
  local shake_z = vel_s * math.sin(2 * math.pi * 11 * (self.c_time + data.dt * math.random()))

  local fps_s_amt = clamp(((1/data.dt) * 0.017), 0, 1)

  shake_vec:set(
          fps_s_amt * shake_x * 0.006,
          0,
          fps_s_amt * shake_z * 0.012)
  shake_vec:setScaled(self.fxShakeStrength)


  local zoom = linearScale(math.abs(data.vel:length()), 0, 40, -rear, (-rear * self.fov) / self.fov_max)

  local vel_y_component = clamp((1/(1 + 9 * math.exp(-math.abs(data.vel:length() * 0.2))) - 0.1) * s, 0, 1)


  g_forces:set(
          self.dirSmoothX:get(l_accel.x * 0.04, data.dt),
          clamp(self.dirSmoothY:get(-l_accel.y * 0.06, data.dt), -math.huge, -rear),
          self.dirSmoothZ:get(-accel.z * 0.004, data.dt))

  g_forces:setComponentMul(self.fxGforceStrength)


  local x_offset = self.smoothVel:get(rescale(l_vel.x * vel_y_component, -10, 10, 0.5, -0.5), data.dt)

  local y_offset = - vel_y_component * 0.2

  local z_offset = top * 0.4 - (linearScale(vel_y_component, 0, 1, 0, top * 0.4))

  camOffset:set(
          x_offset * self.fxVelStrength,
          y_offset * self.fxVelYStrength - zoom - self.camDistance + rear * 1.2,
          z_offset + top * 0.66 + self.camPitch - (rear - self.camDistance) * self.camAngle)
  camOffset:setAdd(g_forces)
  camOffset:setAdd(shake_vec)

  targetOffset:set(
          x_offset * 0.6 * self.fxVelStrength + g_forces.x,
          -y_offset * self.fxVelYStrength - rear,
          top * 0.66 + self.camPitch + rear * self.camAngle)

  camOffset.z = camOffset.z - 0.3 * self.fxVelZStrength * math.abs(x_offset)

  targetOffset.z = targetOffset.z - 0.4 * self.fxVelZStrength * math.abs(x_offset)

  camOffset:setRotate(vel_dir_quat)

  targetOffset:setRotate(vel_dir_quat)

  local up_dir = dir_up:rotated(rev_dir)
  up_dir.x = self.upSmoothingX:get((clamp(up_dir.x, -0.1, 0.1) + clamp(x_offset * 0.2 * self.fxRollStrength, -0.1, 0.1)), data.dt) + fps_s_amt * ((shake_x * shake_z * 0.003) * self.fxShakeStrength)
  up_dir.y = 0
  up_dir.z = 1
  up_dir:normalize()
  up_dir:setRotate(vel_dir_quat)

  local pitch = vec3(0, 0, 0)
  pitch.z = self.upSmoothingZ:get(clamp(dir.z, -0.3, 0.3), data.dt)

  local base_pos = vec3(); base_pos:set(data.pos)
  if self.fxZbounce == true then
    local z_diff = self.lastCamPos.z - data.pos.z
    if z_diff > 0 then
      base_pos.z = self.lastCamPos.z + 0.66 * (data.pos.z - self.lastCamPos.z)
    end
    base_pos.z = self.smoothHeight:get(base_pos.z, data.dt)

  end
  self.lastCamPos:set(base_pos)

  local newpos = base_pos + center + bboxoffset2 + camOffset - pitch

  local targetPos = base_pos + center + bboxoffset2 + targetOffset + pitch


  -- application
  data.res.fov = self.fov * (-rear / zoom)
  data.res.pos:set(newpos.x, newpos.y, newpos.z)
  data.res.rot = quatFromDir(targetPos - data.res.pos, up_dir)

  self.collision:update(data)

  --DEBUG STUFF:

  --log("D", "ECC", "Acceleration: " .. tostring(l_accel) .. " Velocity: " .. tostring(l_vel))
  --debugDrawer:drawSphere((targetPos):toPoint3F(), 0.2, ColorF(0,0,1,1))
  --debugDrawer:drawLine((data.pos + center + bboxoffset2):toPoint3F(), (data.pos + center + bboxoffset2 + vec3(0, 0 ,  z_offset)):toPoint3F(), ColorF(0,1,0,1))
  --debugDrawer:drawLine((data.pos + center + bboxoffset2):toPoint3F(), (data.pos + center + bboxoffset2 + data.vel):toPoint3F(), ColorF(0,1,0,1))
  --debugDrawer:drawLine((data.pos + center + bboxoffset2):toPoint3F(), (data.pos + center + bboxoffset2 + dir_up):toPoint3F(), ColorF(0,1,0,1))
  --debugDrawer:drawLine((data.pos + center + bboxoffset2):toPoint3F(), (data.pos + center + bboxoffset2):toPoint3F(), ColorF(0,1,0,1))
  --debugDrawer:drawLine((data.pos + center + bboxoffset2):toPoint3F(), (data.pos + center + bboxoffset2 + vec3(0, 0, top)):toPoint3F(), ColorF(0,1,0,1))
  --debugDrawer:drawLine((data.pos + center):toPoint3F(), (data.pos + center + data.vel):toPoint3F(), ColorF(0,1,1,1))
  --debugDrawer:drawLine((data.pos + center + data.vel):toPoint3F(), (data.pos + center + data.vel + accel):toPoint3F(), ColorF(1,1,0,1))
  --debugDrawer:setLastZTest(false)

  return true
end

function C:setRefNodes(centerNodeID, leftNodeID, backNodeID)
  self.refNodes = self.refNodes or {}
  self.refNodes.ref = centerNodeID
  self.refNodes.left = leftNodeID
  self.refNodes.back = backNodeID
end

-- DO NOT CHANGE CLASS IMPLEMENTATION BELOW

return function(...)
  local o = ... or {}
  setmetatable(o, C)
  o:init()
  return o
end
