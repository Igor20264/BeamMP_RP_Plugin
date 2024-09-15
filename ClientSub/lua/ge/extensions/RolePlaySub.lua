-- Приватный мод для рп сервера Subter Role Play. Версия v0.0.1
-- Автор Jastickon. Дискорд jastickon.
-- Вся логика вынесена на сторону сервера.

local M = {}

local logTag = "RolePlaySub";

local CheckPoint

local rules_block = {'pause','toggleCamera','dropCameraAtPlayer','editorToggle','switch_previous_vehicle','switch_next_vehicle', 'slower_motion','faster_motion','toggle_slow_motion','modify_vehicle','vehicle_selector','saveHome','loadHome', 'reset_all_physics','toggleTraffic', "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "parts_selector", "dropPlayerAtCamera", "nodegrabberRender",'reset_physics','dropPlayerAtCameraNoReset'} 

local parking = require("cef.parking")

local function onJoinServer(pos_json)
	local pos = jsonDecode(pos_json) 
	log('D', 'User Join Server, pos', dump(pos))
	MPVehicleGE.hideNicknames(true)

	core_input_actionFilter.setGroup("Rules", rules_block)
	core_input_actionFilter.addAction(0, "Rules", true)

	core_vehicles.spawnNewVehicle('unicycle', {["pos"] = vec3(pos)})
end

local function packetJobsUpdate()
	TriggerServerEvent("EventJobsUpdate","")
end

local function profsUpdate(profs)
	log('D', 'onprofsUpdate', profs)
	guihooks.trigger('setRP-Jobs-name', profs)
end

local function ProfsButtonUpdate(buttonname)
	log('D', 'on ProfsButtonUpdate', buttonname)
	guihooks.trigger('setRP-Jobs-button-name', buttonname)
end

local function startworkbutton()
	TriggerServerEvent("EventJobsButton","")
end

local function SendpacketBalanceUpdate()
	TriggerServerEvent("EventBalanceUpdate", "")
end

local function balanceUpdate(new_balance)
	log('D', 'onBalanceUpdate', new_balance)
	guihooks.trigger('setRP-Balance', new_balance)
end

local function onfreezeVehicle(data_json)
	local data = jsonDecode(data_json)
	log('D', 'User freezed', dump(data))
	core_vehicleBridge.executeAction(be:getPlayerVehicle(0), 'setFreeze', data)
end

local function gpsset(pos_json)
	local pos = jsonDecode(pos_json) 
	log('D', 'User GPS Clear', "")
	core_groundMarkers.resetAll()
	core_groundMarkers.sendToApp()
	local color = {0, 0.4, 1}
	core_groundMarkers.setFocus(vec3(pos.x, pos.y, pos.z), nil, nil, nil, nil, nil, color)
	log('D', 'User GPS Seted', dump(pos))
end

function playSound(Name, volume)
	sound = "audio/".. Name ..".ogg"
	Engine.Audio.playOnce("AudioGui", sound, {volume = volume})

	guihooks.trigger('ChangeState', 'menu-subrp-test')
end

local function clearFocus()
	log('D', 'User GPS Clear', "")
	core_groundMarkers.resetAll()
	core_groundMarkers.sendToApp()
end

local function trigerPost(data_json)
	local data = jsonDecode(data_json)

	local VehObjekt = be:getPlayerVehicle(0)
  	local veh_id
  	if VehObjekt then
    	veh_id = VehObjekt:getID()
  	end

	local trigger_name = veh_id .. "_" .. data.user_id .. "_" .. data.logic .. "_" .. data.name
	log('D', 'trigerJobsPostGenerateName', trigger_name)

	log('D', 'trigerJobsPost', dump(data))
	CheckPoint = createObject("BeamNGTrigger")
	CheckPoint.loadmode = 1;
	CheckPoint:setField("triggerType", 0, 'Sphere')
	CheckPoint.debug = true;
	CheckPoint:registerObject(trigger_name)
	CheckPoint:setPosition(vec3(data.pos))
	CheckPoint:setScale(vec3(12,12,12))

	core_groundMarkers.resetAll()
	core_groundMarkers.sendToApp()
	local color = {0, 0.4, 1}
	core_groundMarkers.setFocus(vec3(data.pos), nil, nil, nil, nil, nil, color)
	
end

local function DeleteCheckpoint(data)
	if CheckPoint then
		core_groundMarkers.resetAll()
		core_groundMarkers.sendToApp()
		CheckPoint:delete()
	end	
end

local function Notify(data_json)
	local data = jsonDecode(data_json)

	if data.color == "green" then
		sound_name = "accept"
	elseif data.color == "yellow"  then
		sound_name = "info"
	elseif data.color == "red"  then
		sound_name = "deny"
	end
	playSound("Notify/"..sound_name, 0.8)
	

	guihooks.trigger('setNotify', data.color, data.title, data.text)
	log('D', 'onNotify', dump(data))
	
	
end




local function onBeamNGTrigger(data)
	log('D', 'onBeamNGTrigger', dump(data))
	if data.event == "enter" then
		local data_json = jsonEncode(data)
		TriggerServerEvent("TriggerEventSener", data_json)
		
	end
end

local function CarReplace(data_json)

	local Veh = be:getPlayerVehicle(0)

	log('D', 'onBeamNGVeh', Veh:getField('JBeam', ''))


    local data = json.decode(data_json)
    core_vehicles.replaceVehicle(data.car_name, {config = data.conf})
end

local function onExtensionLoaded()
	log('D', 'Working Started', "")
	AddEventHandler("PacketProfsButtonUpdate",              ProfsButtonUpdate)
	AddEventHandler("PacketProfsUpdate", 					profsUpdate)
	AddEventHandler("PacketBalanceUpdateAll",  				SendpacketBalanceUpdate)
	AddEventHandler("PacketbalanceUpdate", 					balanceUpdate)
	AddEventHandler("PacketDeleteCheckpoint", 					DeleteCheckpoint)
	AddEventHandler("packetgpsset", 					gpsset)
	AddEventHandler("freezeVehicle", 					onfreezeVehicle)
	AddEventHandler("SendonJoinServer", 					onJoinServer)
	AddEventHandler("PackettrigerPost",						trigerPost)
	AddEventHandler("CarReplacePacket", 							CarReplace)
	AddEventHandler("PacketNotify", 					Notify)
	
end;

M.profsUpdate = profsUpdate
M.ProfsButtonUpdate = ProfsButtonUpdate
M.startworkbutton = startworkbutton
M.packetJobsUpdate = packetJobsUpdate
M.SendpacketBalanceUpdate = SendpacketBalanceUpdate
M.balanceUpdate = balanceUpdate
M.trigerJobsPost = trigerPost
M.playSound = playSound
M.onfreezeVehicle = onfreezeVehicle
M.onJoinServer = onJoinServer
M.gpsset = gpsset
M.clearFocus = clearFocus
M.Notify = Notify
M.DeleteCheckpoint = DeleteCheckpoint

M.CarReplace = CarReplace

M.onExtensionLoaded = onExtensionLoaded
M.onBeamNGTrigger = onBeamNGTrigger

return M;