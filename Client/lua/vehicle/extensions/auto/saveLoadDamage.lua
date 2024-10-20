local M = {}

local lastStoreVehData = {}
local loadCarState = false
local loadstatetimer = 0

local gearbox = powertrain.getDevice("gearbox")

local function store()

    local data = {}
    data.engineData = {}
    for k,v in pairs(powertrain.getDevicesByType("combustionEngine")) do
        data.engineData[v.name] = {}
        for a,b in pairs(v) do
            if type(b) ~= "function" and type(b) ~= "userdata" and type(b) ~= "table" and type(b) ~= "cdata" then
                data.engineData[v.name][a] = b
            end
        end
        --data.engineData[v.name] = v.outputAV1
    end

    data.pos = obj:getPosition()
    data.rot = quat(obj:getRotation())
    if gearbox then
        data.gearboxState = controller.mainController.getState()
        data.gear = gearbox.gearIndex
        data.gearmode = gearbox.mode
        data.gear1 = gearbox.gearIndex1
        data.gear2 = gearbox.gearIndex2
    end

    data.throttle = electrics.values.throttle_input
    data.clutch = electrics.values.clutch_input
    data.brake = electrics.values.brake_input
    data.steering_input = electrics.values.steering_input
    data.parkingbrake = electrics.values.parking
    data.vel = obj:getVelocity()
    data.rvel = vec3(-obj:getPitchAngularVelocity(),-obj:getRollAngularVelocity(),-obj:getYawAngularVelocity())
    data.luaState = serialize(serializePackages("save"))

    data.inputs = deepcopy(input)

    data.wheels = {}
    if wheels.wheelRotators then
        for id,wheel in pairs(wheels.wheelRotators) do
            data.wheels[id] = {}
            for a,b in pairs(wheel) do
                if type(b) ~= "function" and type(b) ~= "userdata" and type(b) ~= "table" and type(b) ~= "cdata" then
                    data.wheels[id][a] = b
                end
            end
        end
    end

    data.allhydros = {}
    if hydros.hydros then
        for key, h in pairs(hydros.hydros) do
            data.allhydros[key] = {}
            --data.hydros[key].savedState = h.state
            for name,var in pairs(h) do
                if type(var) == "number" then
                    data.allhydros[key][name] = var
                end
            end
        end
    end
    data.hydros = {}
    if v.data.hydros then
        for key, h in pairs(v.data.hydros) do
            data.hydros[key] = {}
            --data.hydros[key].savedState = h.state
            for name,var in pairs(h) do
                if type(var) == "number" then
                    data.hydros[key][name] = var
                end
            end
        end
    end
    data.torsionHydros = {}
    if v.data.torsionHydros then
        for key, h in pairs(v.data.torsionHydros) do
            data.torsionHydros[key] = {}
            --data.hydros[key].savedState = h.state
            for name,var in pairs(h) do
                if type(var) == "number" then
                    data.torsionHydros[key][name] = var
                end
            end
        end
    end
    data.nodes = {}
    if v.data.nodes then
        for k,n in pairs(v.data.nodes) do
            data.nodes[n.cid] = {}
            data.nodes[n.cid].Pos = obj:getNodePosition(n.cid)
            data.nodes[n.cid].Vel = obj:getNodeVelocityVector(n.cid) - data.vel -- applying to high node force breaks doors so converting to local velocity should prevent that
            data.nodes[n.cid].Mass = obj:getNodeMass(n.cid)
        end
    end

    data.beams = {}
    if v.data.beams then
        for k,beam in pairs(v.data.beams) do
            data.beams[beam.cid] = {}
            data.beams[beam.cid].Length = obj:getBeamRestLength(beam.cid)
            data.beams[beam.cid].Broken = obj:beamIsBroken(beam.cid)
            data.beams[beam.cid].Deform = obj:getBeamDeformation(beam.cid)
            data.beams[beam.cid].cid = beam.cid
            data.beams[beam.cid].beamPrecompression = beam.beamPrecompression
        end
    end
    data.torsionbars = {}
    if v.data.torsionbars then
        for _, h in pairs(v.data.torsionbars) do
            data.torsionbars[h.cid] = {}
            data.torsionbars[h.cid].broken = obj:torsionbarIsBroken(h.cid)
            data.torsionbars[h.cid].angle = obj:getTorsionbarAngle(h.cid)
            data.torsionbars[h.cid].spring = h.spring
            data.torsionbars[h.cid].damp = h.damp
        end
    end
    lastStoreVehData = data
    return data
end

local function load(data)
    data =  lastStoreVehData
    obj:queueGameEngineLua("loadCarDamage.loadDamage("..serialize(data)..","..obj:getID()..")")

    loadCarState = true

    lastStoreVehData.throttle = electrics.values.throttle_input
    lastStoreVehData.clutch = electrics.values.clutch_input
    lastStoreVehData.brake = electrics.values.brake_input
    lastStoreVehData.steering_input = electrics.values.steering_input
    lastStoreVehData.parkingbrake = electrics.values.parking
end

local OGsetGearIndex = nop
if gearbox then
    OGsetGearIndex = gearbox.setGearIndex
end

local function newsetGearIndex(device, index) -- bypasses not being able to set sequentials directly
    device.gearIndex = index -- sets old gear index to next gear to fool the sequential into thinking it can shift directly
    if OGsetGearIndex then OGsetGearIndex(device, index) end
end

if gearbox then
    gearbox.setGearIndexDirect = newsetGearIndex
end

local function updateWheelBrakeABS(wd, brake, invAirspeed, airspeed, airspeedCutOff, dt)
    local brakeTorque = wd.brakeTorque * electrics.values.brake_input
    --log("D", "airbrakes.updateWheelBrake", string.format("returning %.2fNm/%.2fNm for wheel %q with service: %.2f and park: %.2f", brakeTorque, wd.brakeTorque, wd.name, brakeTorqueCoef, springTorqueCoef))
    return brakeTorque
  end

  local function updateWheelBrakeNoABS(wd, brake, invAirspeed, airspeed, airspeedCutOff, dt)
    local brakeTorque = wd.brakeTorque * electrics.values.brake_input
    --log("D", "airbrakes.updateWheelBrake", string.format("returning %.2fNm/%.2fNm for wheel %q with service: %.2f and park: %.2f", brakeTorque, wd.brakeTorque, wd.name, brakeTorqueCoef, springTorqueCoef))
    return brakeTorque
end

local function loadCarStateSimple2(data,setvel)
    loadstatetimer = 0
    data = data or lastStoreVehData
    beamstate.update = nop -- this updates the precompressionTime values and disables itselfe once done, so since we set the beams instantly we don't want this to run at all

    --for _, wd in pairs(wheels.wheels) do -- this was to overide the air brake system, could work for syncing on multiplayer but not for single player
    --    wheels.setWheelBrakeUpdate(wd.name, updateWheelBrakeABS, updateWheelBrakeABS)
    --end

    for key, h in pairs(data.allhydros) do
        for name,var in pairs(h) do
            hydros.hydros[key][name] = var
        end
    end
    for k, h in pairs(data.torsionbars) do
        local torsionbar = v.data.torsionbars[k]
        obj:setTorsionbarPrecompressionAngle(k, torsionbar.precompressionAngle)
        obj:setTorsionbarAngle(k,h.angle)
    end
    for key, h in pairs(data.hydros) do
        for name,var in pairs(h) do
            v.data.hydros[key][name] = var
        end
    end
    for key, h in pairs(data.torsionHydros) do
        obj:setTorsionbarSpringDamp(h.cid,0,0)
        for name,var in pairs(h) do
            v.data.torsionHydros[key][name] = var
        end
    end
    for _,beam in pairs(data.beams) do
        obj:setPrecompressionRatio(beam.cid,beam.beamPrecompression)
        obj:setBeamLength(beam.cid,beam.Length)
        if beam.Broken then
            obj:breakBeam(beam.cid)
        end
        if beam.savedDeform and beam.savedDeform ~= 0 then
            beamstate.beamDeformed(beam.cid, beam.savedDeform)
        end
    end
    for k,n in pairs(data.nodes) do
        obj:setNodePosition(k,n.Pos)
        obj:setNodeMass(k,n.Mass)
    end
    obj:commitLoad() -- used in beamstate save load, without this suspension and steering breaks

    for k,v in pairs(data.engineData) do
        local engine = powertrain.getDevice(k)
        for a,b in pairs(v) do
            if engine[a] then
                engine[a] = b
            end
        end
    end

    -- code above should already be setting this value
    --for k,v in pairs(powertrain.getDevicesByType("combustionEngine")) do
    --     v.outputAV1 = data.engineData[v.name]
    --end

    input.event('throttle', data.throttle, 2)
    input.event('clutch', data.clutch, 2)
    input.event('brake', data.brake, 2)
    input.event('parkingbrake', data.parkingbrake, 2)
    input.event('steering', data.steering_input, 2)

    importPersistentData(data.luaState)
    tableMergeRecursive(input,data.inputs)

    -- applying relatie node velocity, setting all velocity like this will break things, but doing most of it in GE and only doing relative velocity here seems to work
    -- this also applies angular velocity, might be more stable to do that with cluster velocity, but then it would have to be 
    for k,n in pairs(data.nodes) do
        obj:applyForceVector(k,(n.Vel)*n.Mass*2000)
    end

    if gearbox then
        local gearboxState = controller.mainController.getState()
        local isArcade = false


        if gearboxState.grb_bhv == "arcade" then
            isArcade = true
            controller.mainController.setGearboxMode("realistic") -- this seem to cause some issues with sequentials, especially if it's saved in the highest gear
        end

        if data.gearmode then
            if data.gear > 0 then
                controller.mainController:shiftUpOnDown()
                controller.mainController:shiftUpOnUp() -- not sure if this is necessary but the input has it so maybe it's useful?
            else
                controller.mainController:shiftDownOnDown()
                controller.mainController:shiftDownOnUp() -- not sure if this is necessary but the input has it so maybe it's useful?
            end
        end
        if gearbox.setGearIndex then
            gearbox:setGearIndexDirect(data.gear) -- custom function to bypass sequential up down lock
        end
        if gearbox.setGearIndex1 then -- DCT has two gear indexes
            gearbox:setGearIndex1(data.gear1,0)
        end
        if gearbox.setGearIndex2 then -- DCT has two gear indexes
            gearbox:setGearIndex2(data.gear2,0)
        end
        controller.mainController.setState(data.gearboxState) -- sets it to S or M mode
        if isArcade then
            controller.mainController.setGearboxMode("arcade")
        end
    end
end

local function updateGFX(dt)
    if loadCarState then
        for _, h in pairs(lastStoreVehData.torsionHydros) do
            local torsionBar = lastStoreVehData.torsionbars[h.cid]
            if torsionBar.spring and torsionBar.damp then
                obj:setTorsionbarSpringDamp(h.cid,torsionBar.spring*loadstatetimer,torsionBar.damp)
            end
        end
        if loadstatetimer > 1 then
            loadCarState = false
            loadstatetimer = 0
        end
        loadstatetimer = loadstatetimer + (dt)
    end
end

M.updateGFX = updateGFX

M.loadCarStateSimple2 = loadCarStateSimple2

M.store = store
M.load = load

return M