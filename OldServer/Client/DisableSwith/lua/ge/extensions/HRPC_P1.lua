local M = {}

--[[
local function onUpdate()
	log('I', 'simpletrace',"update")
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
	-- и файлы json в папке
	-- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	-- MPVehicleGE.hideNicknames(true)
	--core_input_actionFilter.setGroup("restrictions", restrictions)
	--core_input_actionFilter.addAction(0, "restrictions", true)
end
--]]

local function arepairs()
	return 1
end

local function EGG()
	local blocked = {"accelerate","brake","accelerate_brake","steer_left","steer_right","steering","clutch","repair_car_rp"}
	extensions.core_input_actionFilter.setGroup("repairsssssss", blocked)
	
	local data = be:getPlayerVehicle(0):getPosition()
	local data = tostring(be:getPlayerVehicle(0):getPosition())
	if be:getPlayerVehicle(0):getVelocity():length()*3.6 <= 4 then
		guihooks.trigger("toastrMsg", {type="error", title="Управление заблокированно", msg="Включится при починке траспорта."})
		extensions.core_input_actionFilter.addAction(0, "repairsssssss", true)
		TriggerServerEvent("REPAIR", tostring(data))
		return 1
	else
		guihooks.trigger("toastrMsg", {type="error", title="Остановись", msg="Ремонт работает, только при стоянке."})
		return 0
	end
end

function REPAIRS_TIMER(timer)
	function myThread()
		log('I', 'simpletrace', "preyield")
		--local socket = require("socket")
		--socket.sleep(tonumber(timer))
		log('I', 'simpletrace', "postyield")
		REPAIRS()
	end
	
	myCoroutine = coroutine.create(myThread)
	coroutine.resume(myCoroutine)
end

function REPAIRS(times)
	extensions.core_input_actionFilter.addAction(0, "repairsssssss", false)
	--spawn.safeTeleport(be:getPlayerVehicle(0), be:getPlayerVehicle(0):getPosition(), be:getPlayerVehicle(0):getRotation());
	spawn.safeTeleport(be:getPlayerVehicle(0), be:getPlayerVehicle(0):getPosition());
end

local function onExtensionLoaded() -- LOAD
	log('I', 'simpletrace', "LOAD")
	AddEventHandler("REPAER", REPAIRS)
	AddEventHandler("REPAER_TIMER",REPAIRS_TIMER)
	MPVehicleGE.hideNicknames(true)
	skipPlayers(true)
end

local function onExtensionUnloaded() -- UNLOAD
	skipPlayers(false)
	MPVehicleGE.hideNicknames(false)
	log('I', 'simpletrace', "UNLOAD")
   --extensions.core_input_actionFilter.addAction(0, 'restrictions',  true)
end
M.arepairs = arepairs
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.updateGFX = updateGFX
return M