local M = {}
M.info = "Система Блокровка"
M.ver = "BETA 0.2"

function onSpawn(player_id, vehicle_id, data)
	MP.TriggerClientEvent(player_id, "ECOBLOC", M.data)
	return 0
end

function ON(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
    -- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	MP.TriggerClientEvent(MP.GetId(p2), "ECOBLOC", M.data)
	return 0
end

function OFF(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	MP.TriggerClientEvent(MP.GetId(p2), "ECOUNBLOCK", "SA")
	return 0
end


M.data = ""
local data = {"toggleCamera", "dropCameraAtPlayer", "slower_motion", "faster_motion", "toggle_slow_motion","nodegrabberAction", "nodegrabberStrength","editorToggle", "objectEditorToggle", "editorSafeModeToggle","dropPlayerAtCamera", "dropPlayerAtCameraNoReset", "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "reload_vehicle", "reload_all_vehicles", "loadHome", "saveHome", "reset_physics","reset_all_physics"}
for i,case in ipairs(data) do 
	M.data = M.data.." "..case
end
-- 
M.config = load_config("settings/S2C")
local prefix = M.config.prefix
M.command = {
	{command = prefix.."on",help = "блокировка некоторых опций бимки "..prefix.."on [name]", func = "ON", admin = true,hide = false},
	{command = prefix.."off",help = "откл блокировка некоторых опций бимки "..prefix.."off [name]", func = "OFF", admin = true,hide = false}
	}

function M.load() 
	MP.RegisterEvent("onVehicleSpawn","onSpawn")
	M.command = RegEvent(M.command)
end

function M.unload()
end

return M

--[[function onVehicleEdited(player_id, vehicle_id, data)
	local s = data:find('%{')
	data = data:sub(s)
	data = Util.JsonDecode(data)
	players[player_id].vehicles[vehicle_id] = data.jbm
end
--]]

--function onVehicleReset(player_id, vehicle_id, data)