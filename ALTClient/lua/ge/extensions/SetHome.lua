local M = {}
local windowOpen = ui_imgui.BoolPtr(true)
M.core_camera = core_camera
M.dependencies = {"ui_imgui"}

local FolderName = "BRP"
local im = ui_imgui
local work = true
function round(numder,p)
	local p = p or 2
	return tonumber(string.format("%."..p.."f",numder)) 
end

--independent GUI
local showUI = nil

local tool_version = "1.0"
local appTitle = " SetHome - ".. tool_version 

local function onWorldReadyState(worldReadyState)
	if worldReadyState == 2 then
		local data = jsonReadFile("/BeamMP/RolePlay/"..FolderName.."/position.json")
		--core_vehicles.spawnNewVehicle("unicycle",{pos =vec3(1147,1030,163)})
		if type(data) == "nil" then
			log('D', 'simpletrace', "FileNotFaund")
			core_vehicles.spawnNewVehicle("unicycle",{pos = vec3(
			-581+(math.random()),
			-547+(math.random()),
			-8+(math.random())
			)})
		elseif type(data) == "table" then
			log("D", "simpletrace","HomeFindet")
			local x = tonumber(round(data[1]))
			local y = tonumber(round(data[2]))
			local z = tonumber(round(data[3]))
			local vec = vec3(x,y,z)
			core_vehicles.spawnNewVehicle("unicycle",{pos =vec})
		end
		core_camera.setByName(be:getPlayerVehicle(0))
	end
end

local function onExtensionLoaded1()
	if showUI == nil then
	showUI = ui_imgui.BoolPtr(false)
	end
end

local function onUpdate()
	if not showUI[0] then
		return
    end
	im.Begin(appTitle, showUI, im.WindowFlags_AlwaysAutoResize)
	if im.Button("Set Home") then
		jsonWriteFile("/BeamMP/RolePlay/"..FolderName.."/position.json",{be:getPlayerVehicle(0):getPositionXYZ()})
    end
	im.End()
end

local function onWindowMenuItem()
  showUI[0] = true
end

local function openUI()
  showUI[0] = true
end

local function hideUI()
  showUI[0] = false
end

local function toggleUI()
  if showUI[0] then
    hideUI()
  else
    openUI()
  end
end

M.show = openUI
M.hide = hideUI
M.toggle = toggleUI
--M.onFreeroamLoaded = onWorldReadyState
M.onWorldReadyState = onWorldReadyState
--M.onClientPostStartMission = onExtensionLoaded
M.onExtensionLoaded = onExtensionLoaded1
M.onClientEndMission = onClientEndMission
M.onUpdate = onUpdate
M.onExit = onExit

--M.onLoadingScreenFadeout = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
return M