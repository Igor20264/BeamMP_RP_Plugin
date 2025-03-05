local M = {}
ToSendServerData = {}
AddToSendServerData = {}
SoldId = {}
insnowman = false
-- other func
local function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

local function skipPlayers(egg)
	settings.setValue("richPresence", true)
	settings.setValue("richPresenceDiscord", true)
	settings.setValue("uiAcceleratedRender", true)
	settings.setValue("showMissionMarkers", true)
	settings.setValue("enableGasStationsInFreeroam", true)
    settings.setValue("skipOtherPlayersVehicles", egg)
	settings.setValue("nameTagFadeEnabled", egg)
	settings.setValue("nameTagFadeDistance", 20)
	settings.setValue("hideNameTags", false)
	settings.setValue("simplifyRemoteVehicles", false)
	settings.setValue("enableSpawnQueue", true)
	settings.setValue("enableQueueAuto", true)
	settings.setValue("queueApplySpeed", 1)
	settings.setValue("queueApplyTimeout", 0)
	settings.setValue("queueSkipUnicycle", true)
	settings.setValue("autoSyncVehicles", true)
	settings.setValue("enableBlobs", true)
	settings.setValue("showSpectators", true)
	settings.setValue("debugOutput", false)
	settings.setValue("unicycle_pc", "beamling")
	settings.setValue("skipModSecurityWarning", true)
	settings.setValue("unicycleAutoSave", true)
	settings.setValue("protectConfigFromClone", true)
	settings.setValue("enablePosSmoother", false)
	settings.setValue("spawnVehicleIgnitionLevel", 0)
	settings.setValue("startThermalsPreHeated", false)
	settings.setValue("startBrakeThermalsPreHeated", false)
	settings.setValue("defaultGearboxBehavior", "realistic")
	settings.setValue("absBehavior", "realistic")
	settings.setValue("escBehavior", "realistic")
	settings.requestSave()
end

local function skipPlayersAdm(egg)
	settings.setValue("skipOtherPlayersVehicles", false)
	settings.setValue("nameTagFadeEnabled", egg)
	settings.setValue("nameTagFadeDistance", 5)
	settings.setValue("hideNameTags", false)
	settings.setValue("simplifyRemoteVehicles", false)
	settings.requestSave()
end

local function runs(data)
	local res = assert(load(data))()
end

-- @param strlua - string is "NameValue$$$DataValue"
function AddDataToSendServerData(strlua)
	local tdata= split(strlua,"$$$")
	if AddToSendServerData == nil then
		AddToSendServerData = {}
	end
	AddToSendServerData[tdata[1]] = tdata[2]
end

local function onVehicleSwitched(oldId, newId, playerId)
	local currentVehicle = core_vehicles.getCurrentVehicleDetails()
	local name_car
	if currentVehicle.model == nil then
		name_car = "unicycle"
	else
		name_car = currentVehicle.model.key
	end

	if name_car == 'unicycle' then
		if issnowman ~= true then
			SoldId = oldId
			insnowman = true
		end
	elseif insnowman == true and name_car ~= 'unicycle' and newId ~= SoldId then
		local x,y,z = be:getPlayerVehicle(0):getPositionXYZ()
		TriggerServerEvent("VehicleSwitched", jsonEncode({id = newId,position={x=x,y=y,z=z}}))
		insnowman = false
	elseif insnowman == true and name_car ~= 'unicycle' and newId == SoldId then
		insnowman = false
	end
end

local function SendToServerData(name)
	ToSendServerData = ToSendServerData or {}
	ToSendServerData.activeVehicle = be:getPlayerVehicle(0):getId()
	ToSendServerData.pos = ToSendServerData.pos or {}
	ToSendServerData.pos.x,ToSendServerData.pos.y,ToSendServerData.pos.z = be:getPlayerVehicle(0):getPositionXYZ()
	log("pos:"..ToSendServerData.pos.x..ToSendServerData.pos.y..ToSendServerData.pos.z)
	ToSendServerData.custom = ToSendServerData.custom or {}
	for nameS, data in pairs(AddToSendServerData) do
		local result = load(data)()
		ToSendServerData.custom[nameS] = result
	end
	TriggerServerEvent('GetCTS', name.."$$$"..(jsonEncode(ToSendServerData)))
	ToSendServerData = {}
end

local function SpawnCar(data)
	log('I', 'spawn', data)
	if type(data) ~= "table" then
		data = json.decode(data)
	end
	core_gamestate.setGameState("multiplayer", "BeamMP_RP_Plugin", "multiplayer")
	local vih = core_vehicles.spawnNewVehicle(data["model"], data.data)
	vih:queueLuaCommand(data.run_queue)
	load("local ids = "..(vih:getId())..";"..data["cmd"])()
    return
end

-- local blockedActions = core_input_actionFilter.createActionTemplate({"vehicleTeleporting", "vehicleMenues", "physicsControls", "aiControls", "vehicleSwitching", "funStuff"}, actionWhitelist)

local function block(data)
	log('I', 'Block', data)
	local data = split(data," ")
	--MPVehicleGE.nameTagFadeEnabled(true)
	extensions.core_input_actionFilter.setGroup("restrictions", data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", true)
	core_gamestate.setGameState("career", "BeamMP_RP_Plugin", "career")
	skipPlayers(true)
end

local function tunlock(data)
	log('I', 'simpletrace', "BlockInput")
	local data = split(data," ")
	--local data =  {"slower_motion", "faster_motion", "toggle_slow_motion", "nodegrabberAction", "nodegrabberGrab", "nodegrabberRender", "nodegrabberStrength","toggleTraffic", "toggleAITraffic","editorToggle", "objectEditorToggle", "editorSafeModeToggle","switch_next_vehicle", "switch_previous_vehicle", "switch_next_vehicle_multiseat"}
	extensions.core_input_actionFilter.setGroup("restrictions", data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", true)
	core_gamestate.setGameState("multiplayer", "multiplayer", "multiplayer")
	skipPlayers(true)
end

local function unblock(data)
	log('I', 'unBlock', data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", false)
	skipPlayers(false)
	core_gamestate.setGameState("multiplayer", "BeamMP_RP_Plugin", "multiplayer")
	skipPlayersAdm(true)
end

local function onExtensionLoaded()
	AddEventHandler("ECOBLOC",block)
    AddEventHandler("REMRUN",runs)
	AddEventHandler("SendServerData",SendToServerData)
    AddEventHandler("SPAWNCAR",SpawnCar)
	AddEventHandler("ECOTUNLOCK",tunlock)
	AddEventHandler("ECOUNBLOCK",unblock)
	settings.setValue("unicycle_pc", "snowman")
	MPVehicleGE.hideNicknames(false)
	skipPlayers(true)
	skipPlayersAdm(true)
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
	-- и файлы json в папке
	-- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	--core_input_actionFilter.setGroup("restrictions", restrictions)
	--core_input_actionFilter.addAction(0, "restrictions",  true)
end

local function onBeamNGTriggerPoint(trigger, data)
	data = jsonEncode({trigger=trigger,data=data})
	TriggerServerEvent("onTriggerPoint", data)
end

--onJoinTriggerPoint
local function onExtensionUnloaded()
	skipPlayers(false)
	skipPlayersAdm(false)
	log('I', 'simpletrace', "UNLOAD")
    extensions.core_input_actionFilter.addAction(0, 'restrictions',  false)
end
M.onBeamNGTriggerPoint = onBeamNGTriggerPoint
M.onVehicleSwitched = onVehicleSwitched
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
--M.onUpdate = onUpdate
return M
