local M = {}

local function D3toD2(x,y,z) -- vec3 to vec2
    return x,y
end

local function minDistancePointRect(x1, y1, x2, y2,px, py)
  local left = math.min(x1, x2)
  local right = math.max(x1, x2)
  local top = math.min(y1, y2)
  local bottom = math.max(y1, y2)

  local closestX = px
  if px < left then
    closestX = left
  elseif px > right then
    closestX = right
  end

  local closestY = py
  if py < top then
    closestY = top
  elseif py > bottom then
    closestY = bottom
  end

  local distanceX = math.abs(px - closestX)
  local distanceY = math.abs(py - closestY)

  return math.sqrt(distanceX^2 + distanceY^2)
end

local function midPoint(x1, y1, z1, x2, y2, z2)
  local mx = (x1 + x2) / 2
  local my = (y1 + y2) / 2
  local mz = (z1 + z2) / 2
  return mx, my, mz
end

local function Rectangle(x1,y1,x2,y2,px,py) -- bool\
    local mx1 = math.min(x1,x2)
    local mx2 = math.max(x1,x2)
    local my1 = math.min(y1,y2)
    local my2 = math.max(y1,y2)
    return mx1 <= px and px <= mx2 and my1 <= py and py <= my2
end

local function Distance(x1,y1,x2,y2) -- float
    return math.sqrt((x1-x2)^2+(y1-y2)^2)
end

local function Circle(cx,cy,x1,y1,px,py) -- bool
    local radius = Geo:Distance(cx,cy,x1,y1)
    return Geo:Distance(cx,cy,px,py) <= radius
end

local function getActiveVehicle(id) -- player_id -> server_car_id
    local data = CTS[MP.GetPlayerName(id)]
    if data == nil then
        return nil
    end
    local car_pid = data.activeVehicle
    local usercars = MP.GetPlayerVehicles(id)
    if usercars == nil then
        log({"User"..id.." "..MP.GetPlayerName(id).." | Car "..car_pid.." | MP.GetPlayerVehicles return nil",5})
        return nil
    end
    for car_id,datacar in pairs(usercars) do
        local s = string.find(datacar,'"vid":'..car_pid)
        if s ~= nil then
            return car_id
        end
    end
    return 0
end

local function getPos(id,server_car_id)
    local active = getActiveVehicle(id)
    if active == nil then
        log("User"..id.." | Car "..server_car_id.." | is not active",5)
        return 0,0,0
    end
    server_car_id = server_car_id or active or 0
    data = MP.GetPositionRaw(id,server_car_id) or nil
    if data == nil then
        log("User"..id.." | Car "..server_car_id.." | is not active",5)
        return 0,0,0
    end
    return data["pos"][1],data["pos"][2],data["pos"][3] -- x,y,z
end

local function getSpeed(id,server_car_id)
    local active = getActiveVehicle(id)
    if active == nil then
        return nil
    end
    server_car_id = server_car_id or active or 0
    data = MP.GetPositionRaw(id,server_car_id)["vel"]
    speed = math.sqrt(data[1]^2 + data[2]^2 + data[3]^2)*3.6
    return speed
end

local function getAngle(id,server_car_id)
    local active = getActiveVehicle(id)
    if active == nil then
        return nil
    end
    server_car_id = server_car_id or active or 0
    data = MP.GetPositionRaw(id,server_car_id)["rot"]
    return data[1],data[2] -- yaw, pitch
end


M.getAngle = getAngle
M.D3toD2 = D3toD2
M.Rectangle = Rectangle
M.Distance = Distance
M.Circle = Circle
M.getActiveVehicle = getActiveVehicle
M.getPos = getPos
M.getSpeed = getSpeed
M.minDistancePointRect = minDistancePointRect
M.midPoint = midPoint
return M