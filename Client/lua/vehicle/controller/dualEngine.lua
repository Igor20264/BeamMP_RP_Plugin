-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}
M.type = "auxiliary"

local mainEngine, rearEngine
local frontGearbox, rearGearbox

local syncGears = true

local function updateSimpleControlButtons()
	local color = syncGears and "3096F1" or "98FB00" 
	ui_simplePowertrainControl.setButton(
		"syncRearGearbox", "Sync Rear Gearbox", "powertrain_gearbox_manual", color, nil, "controller.getController('".. M.name .."').toggleRearGearboxSync()")
end

local function toggleRearGearboxSync()
	syncGears = not syncGears
	updateSimpleControlButtons()
end


local function updateGFX(dt)
	if not frontGearbox or not rearGearbox then return end

	if syncGears then
		rearGearbox:setGearIndex(frontGearbox.gearIndex)
	end


	if not mainEngine or not rearEngine then return end

	if mainEngine.ignitionCoef ~= rearEngine.ignitionCoef then
		rearEngine:setIgnition(mainEngine.ignitionCoef)
	end

	if mainEngine.starterEngagedCoef == 1 then
		rearEngine:activateStarter()
	elseif rearEngine.starterEngagedCoef == 1 then
		rearEngine:deactivateStarter()
	end
end

local function init()
	mainEngine = powertrain.getDevice("mainEngine")
	rearEngine = powertrain.getDevice("rearEngine")

	frontGearbox = powertrain.getDevice("gearbox")
	rearGearbox = powertrain.getDevice("rearGearbox")
end

M.init = init
M.updateGFX = updateGFX

M.updateSimpleControlButtons = updateSimpleControlButtons
M.toggleRearGearboxSync = toggleRearGearboxSync

return M
