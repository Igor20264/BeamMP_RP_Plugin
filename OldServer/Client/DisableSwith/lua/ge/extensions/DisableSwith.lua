local M = {}
M.time = 0

local function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

function RUN_ON_CLIENT(data)
	log('I', 'simpletrace', 'run_clien')
	local case = loadstring(data)
	local egg, ret = case()
	return true
end

function skipPlayers(value)
	settings.setValue("skipOtherPlayersVehicles",value)
	settings.requestSave()
end
 
local function updateGFX(dt)
	M.time = M.time + 1
end

local function block(data)
	log('I', 'simpletrace', "BlockInput")
	local data = split(data," ")
	--local data =  {"slower_motion", "faster_motion", "toggle_slow_motion", "nodegrabberAction", "nodegrabberGrab", "nodegrabberRender", "nodegrabberStrength","toggleTraffic", "toggleAITraffic","editorToggle", "objectEditorToggle", "editorSafeModeToggle","switch_next_vehicle", "switch_previous_vehicle", "switch_next_vehicle_multiseat"}
	extensions.core_input_actionFilter.setGroup("restrictions", data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", true)
	skipPlayers(true)
end

local function unblock(data)
	log('I', 'simpletrace', "UNInput")
	extensions.core_input_actionFilter.setGroup("restrictions", data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", false)
	skipPlayers(false)
end

local function onExtensionLoaded()
	log('I', 'simpletrace', "LOAD")
	AddEventHandler("ADAADA",block)
	AddEventHandler("ADAADD",unblock)
	AddEventHandler("RUNONCKIENT",RUN_ON_CLIENT)
	MPVehicleGE.hideNicknames(true)
	skipPlayers(true)
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
	-- и файлы json в папке
	-- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	--core_input_actionFilter.setGroup("restrictions", restrictions)
	--core_input_actionFilter.addAction(0, "restrictions",  true)
end

local function onExtensionUnloaded()
	skipPlayers(false)
	MPVehicleGE.hideNicknames(false)
	log('I', 'simpletrace', "UNLOAD")
   --extensions.core_input_actionFilter.addAction(0, 'restrictions',  true)
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.updateGFX = updateGFX
--M.onUpdate = onUpdate
return M