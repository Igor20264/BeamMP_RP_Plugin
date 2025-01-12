
local M = {}
local requestDamage = false
local damageData = {}
local lastDT = 0

--local function loadDamage(data,vehicleID)
--    requestDamage = true
--    damageData[vehicleID] = data
--    damageData[vehicleID].set = true
--end

local function applyDamage(data,vehicleID)
    local veh = be:getObjectByID(vehicleID)
    --local vel = veh:getVelocity()
    --local vehPos = veh:getPosition()
    --local pos = data.pos + (vel*(lastDT*2))
    --veh:setPositionRotation(pos.x,pos.y,pos.z,data.rot.x,data.rot.y,data.rot.z,data.rot.w)

    veh:setPositionRotation(data.pos.x,data.pos.y,data.pos.z,data.rot.x,data.rot.y,data.rot.z,data.rot.w)

    veh:resetBrokenFlexMesh()
    veh:queueLuaCommand("saveLoadDamage.loadCarStateSimple2()")

    --local clusters = veh:getNodeClusters()
    ----for k,v in pairs(clusters) do
    ----    if v ~= 0 then
    ----        dump(k,v)
    ----    end
    ----end
    veh:applyClusterVelocityScaleAdd(veh:getRefNodeId(), 1, data.vel.x, data.vel.y, data.vel.z)
end

local function onPreRender(dt)
    lastDT = dt
    --if requestDamage then
    --    requestDamage = false
    --    for vehicleID, data in pairs(damageData) do
    --        if data.set then
    --            applyDamage(data,vehicleID,dt)
    --            data.set = false
    --        end
    --    end
    --end
end

M.loadDamage = applyDamage
M.onPreRender = onPreRender

return M