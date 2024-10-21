local M = {}

local CheckPoint
local balance


local function setgps(x,y,z)
	log('D', 'User GPS Clear', "")
	core_groundMarkers.resetAll()
	core_groundMarkers.sendToApp()
	local color = {0, 0.4, 1}
	core_groundMarkers.setFocus(vec3(x, y, z), nil, nil, nil, nil, nil, color)
end

local function playSound(Name, volume)
	sound = "audio/".. Name ..".ogg"
	Engine.Audio.playOnce("AudioGui", sound, {volume = volume})
	--uihooks.trigger('ChangeState', 'menu-subrp-test')
end

local function onJoinServer(data)
	log('D', 'User Join Server, pos', dump(pos))
	MPVehicleGE.hideNicknames(true)
	--core_vehicles.spawnNewVehicle('unicycle', {["pos"] = vec3(pos)})
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

local function balanceUpdate(new_balance)
	log('D', 'onBalanceUpdate', new_balance)
	guihooks.trigger('setRP-Balance', new_balance)
	new_balance = tonumber(new_balance)
	if new_balance == nil then
		return
	end
	if new_balance > balance then
		playSound("monneyadd", 0.7)
	end
	balance = new_balance
end

local function gpsset(pos_json)
	local pos = jsonDecode(pos_json) 
	log('D', 'User GPS Clear', "")
	setgps(pos.x, pos.y, pos.z)
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

	setgps(data.pos.x, data.pos.y, data.pos.z)
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

local function packetJobsUpdate()
	log('D', 'packetJobsUpdate', dump(data))
	TriggerEventSener("packetJobsUpdate")
end

local function CarReplace(data_json)
	local Veh = be:getPlayerVehicle(0)
	log('D', 'onBeamNGVeh', Veh:getField('JBeam', ''))
    local data = json.decode(data_json)
    core_vehicles.replaceVehicle(data.car_name, {config = data.conf})
end

local function banned(data)
	playSound("tobycon", 1)
end

local function onExtensionLoaded()
	log('D', 'Working Started', "")
	AddEventHandler("PacketBannedSub",              banned)
	AddEventHandler("PacketProfsButtonUpdate",      ProfsButtonUpdate)
	AddEventHandler("PacketProfsUpdate", 			profsUpdate)

	AddEventHandler("PacketDeleteCheckpoint", 		DeleteCheckpoint)
	AddEventHandler("packetgpsset", 				gpsset)
	AddEventHandler("PackettrigerPost",				trigerPost)
	AddEventHandler("CarReplacePacket", 			CarReplace)

	AddEventHandler("PacketbalanceUpdate", 			balanceUpdate)
	AddEventHandler("PacketNotify", 				Notify)
	--AddEventHandler("SendonJoinServer", onJoinServer)
end;

M.banned =  banned
M.onExtensionLoaded = onExtensionLoaded
M.profsUpdate = profsUpdate
M.ProfsButtonUpdate = ProfsButtonUpdate
M.startworkbutton = startworkbutton
M.balanceUpdate = balanceUpdate
M.trigerJobsPost = trigerPost
M.playSound = playSound
M.onJoinServer = onJoinServer
M.gpsset = gpsset
M.Notify = Notify
M.DeleteCheckpoint = DeleteCheckpoint
M.CarReplace = CarReplace
M.onBeamNGTrigger = onBeamNGTrigger
M.packetJobsUpdate = packetJobsUpdate
return M;