local M = {}
print("Loading DisableSwith...")

local function onUpdate()
	log('I', 'simpletrace',"update")
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
	-- и файлы json в папке
	-- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
	MPVehicleGE.hideNicknames(true)
	--core_input_actionFilter.setGroup("restrictions", restrictions)
	--core_input_actionFilter.addAction(0, "restrictions", true)
end

local function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

function skipPlayers(egg)
	settings.setValue("skipOtherPlayersVehicles",egg)
	settings.requestSave()
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
	--extensions.core_input_actionFilter.setGroup("restrictions", data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", false)
	skipPlayers(false)
end

local function onExtensionLoaded()
	log('I', 'simpletrace', "LOAD")
	AddEventHandler("ECOBLOC",block)
	AddEventHandler("ECOUNBLOCK",unblock)
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
	log('I', 'simpletrace', "UNLOAD")
   --extensions.core_input_actionFilter.addAction(0, 'restrictions',  true)
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
--M.onUpdate = onUpdate
return M