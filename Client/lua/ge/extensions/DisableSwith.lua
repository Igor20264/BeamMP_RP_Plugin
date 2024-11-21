local M = {}
local sl = true
local currTime = 0
local updateTime = 0.1
local setDistance = 10

local fadeLights = true

local dataLights = nil
local dataLightsBrightness = nil

local lightShouldCastShadowDistanceTreshold = 30

local lightShouldCastShadowDistanceTresholdSquared = lightShouldCastShadowDistanceTreshold * lightShouldCastShadowDistanceTreshold
ToSendServerData = {}
AddToSendServerData = {}


-- other func
local function split(inputstr, sep) 
	if sep == nil then sep = "%s" end 
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do table.insert(t, str) end
	return t
end

--

local function getAllLightsGroup()
	dataLights = {}
	dataLightsBrightness = {}
	
	for _, name in ipairs(scenetree.findClassObjects("SpotLight")) do
      local light = scenetree.findObject(name)
      if light then
        table.insert(dataLights, name)
		dataLightsBrightness[name] = light.brightness
      end
    end
    for _, name in ipairs(scenetree.findClassObjects("PointLight")) do
      local light = scenetree.findObject(name)
      if light then
        table.insert(dataLights, name)
		dataLightsBrightness[name] = light.brightness
      end
    end
end

local function toggleAllLights(state)
  log("I", "toggleAllLights", "Turning all map lights " .. (state and "on" or "off"))

  for idx, name in pairs(dataLights) do
    local thisLight = scenetree.findObject(name)
    thisLight.isEnabled = state
  end
end

local function isVisible(obj) 
	local observerPosition = core_camera.getPosition();    
	local observerDirection = core_camera.getRight():normalized();    
	local lightSourcePosition = obj:getPosition();    
	local lightVector = lightSourcePosition - observerPosition;   
	local observerToLight = lightVector:normalized();    
	local dotProduct = observerDirection:dot(observerToLight);    
	if math.abs(dotProduct) <= 0.8 then        
		local angle = math.deg(math.acos(dotProduct));
		local crossProduct = observerToLight:cross(core_camera.getUp());        
		local dotProductCross = crossProduct:dot(observerDirection);
		local isFacingObject = dotProductCross >= 0;
		return 30 < angle and angle < 150 and isFacingObject    
	end    
	return false 
end

-- this only runs if its nighttime
local function updateLightsDistance()
  local cameraPos = core_camera.getPosition()
  local playerVeh = be:getPlayerVehicle(0)
  local lightDistanceTresholdSquared = 200*200
    --  or not commands.isFreeCamera()
  if playerVeh and (not cameraPos) then
    cameraPos = playerVeh:getPosition()
  end

  if not cameraPos then
    return
  end

  for idx, name in pairs(dataLights) do
    local thisLight = scenetree.findObject(name)

    if not thisLight then
      return
    end

    local lightPosition = thisLight:getPosition()

    if not lightPosition then
      return
    end

    local squaredDistance = vec3(cameraPos):squaredDistance(lightPosition)

    -- should this light be enabled
    if squaredDistance < lightDistanceTresholdSquared then
	  if isVisible(thisLight) or squaredDistance < 50*50 then
		  if fadeLights and dataLightsBrightness[name] then
			local brightnessCoef = linearScale(squaredDistance, lightDistanceTresholdSquared, 25, 0, 1)

			local brightnessScaled = dataLightsBrightness[name] * brightnessCoef

			thisLight.brightness = brightnessScaled
		  end

		  thisLight.isEnabled = true

		  -- enable/disable shadows
		  if squaredDistance < lightShouldCastShadowDistanceTresholdSquared then
			thisLight.castShadows = true
		  else
			thisLight.castShadows = false
		  end
	  else
		 thisLight.isEnabled = false
	  end
    else
      thisLight.isEnabled = false
    end
	
  end
end

local function updateLightsTime()
  local tod = scenetree.tod

  if not tod then
    return
  end	
  if dataLights == nil then
    getAllLightsGroup()
    return
  end
	if setDistance == 0 then
		for _,name in pairs(scenetree.findClassObjects("BeamNGVehicle")) do
			scenetree.findObject(name).renderDistance = 200 --lightDistanceTreshold
		end
		setDistance = 100
	else
		setDistance = setDistance - 1
	end
	
  if (tod.time > 0.26 and tod.time < 0.77) then
	if true ~= Lights then
		Lights = true
		toggleAllLights(Lights)
	end
  else
    if false ~= Lights then
		Lights = false
		toggleAllLights(Lights)
	end
  end
  
  if Lights == true then
	  updateLightsDistance()
   end
  
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

local function runs(data)
	local res = assert(load(data))()
end

function AddDataToSendServerData(strlua)
	local tdata= split(strlua,"$$$")
	if AddToSendServerData == nil then
		AddToSendServerData = {}
	end
	AddToSendServerData[tdata[1]] = tdata[2]
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
	local vih = core_vehicles.spawnNewVehicle(data["model"], data.data)
	vih:queueLuaCommand(data.run_queue)
	load("local ids = "..(vih:getId())..";"..data["cmd"])()
	print("data.data: " .. data.data)
	print("data.run_queue:" .. data.run_queue)
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

local function unblock(data)
	log('I', 'unBlock', data)
	extensions.core_input_actionFilter.addAction(0, "restrictions", false)
	skipPlayers(false)
	core_gamestate.setGameState("multiplayer", "BeamMP_RP_Plugin", "multiplayer")
end

local function onUpdate(dtReal, dtSim, dtRaw)
    currTime = currTime + dtReal
    if currTime >= updateTime then
        currTime = 0
        updateLightsTime()
    end
	if true == editor_main.isEditorActive() then
		RESETLIGHTCHANH()
	end
	MPVehicleGE.hideNicknames(false)
end

function RESETLIGHTCHANH()
	dataLights = nil
end

local function onExtensionLoaded()
	AddEventHandler("ECOBLOC",block)
    AddEventHandler("REMRUN",runs)
	AddEventHandler("SendServerData",SendToServerData)
    AddEventHandler("SPAWNCAR",SpawnCar)
	AddEventHandler("ECOUNBLOCK",unblock)
	settings.setValue("unicycle_pc", "snowman")
	MPVehicleGE.hideNicknames(false)
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
    extensions.core_input_actionFilter.addAction(0, 'restrictions',  false)
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onUpdate = onUpdate
return M
