local M = {}

local engine = nil -- mainEngine
local function onVehicleLoaded()
	engine = powertrain.getDevice("mainEngine")
	if not engine or (engine and engine.type ~= "combustionEngine") then
		engine = nil
		return
	end
end

local function updateGFX(dt)
	if not engine then
		return
	end

	local t = {
		current = engine.combustionTorque,
		damage = engine.overTorqueDamage,
		rating = engine.maxTorqueRating,
		limit = engine.maxOverTorqueDamage,
		maxTorque = engine.maxTorque,
		maxPower = engine.maxPower,
		maxTorqueRPM = engine.torqueData.maxTorqueRPM,
		maxPowerRPM = engine.torqueData.maxPowerRPM,
		curves = engine.torqueData.curves
	}
	gui.send("overtorque", t)
end

M.onVehicleLoaded = onVehicleLoaded
M.updateGFX = updateGFX

return M
