local windowOpen = ui_imgui.BoolPtr(true)

local M = {}
M.dependencies = {"ui_imgui"}
M.core_camera = core_camera

local im = ui_imgui
local ffi = require("ffi")

--independent GUI
local showUI = nil
local tempFloat = nil

--ssao
local ssaoenabled = false
local isssaoenabled = false
--pssm
local pssmenabled = false
local pssmlenabled = false
local ispssmenabled = false
local ispsslmenabled = false
--terdet
local terenabled = false
local isterenabled = false
local terlenabled = false
local isterlenabled = false
--details
local detailenabled = false
local isdetailenabled = false
--textures
local textenabled = false
local istextenabled = false
--reflectors
local refenabled = false
local isrefenabled = false
local mirenabled = false
local ismirenabled = false
--rt distance
local rtVis = true

local camPos
local camDir
local camFov = 0

local rayTable = {}
local avgRay = 0
local rayAmnt

local distanceOffsetBias = im.FloatPtr(0)
local distanceOffset = 70
local targetDistance = 0

local counter = 0

--settings
local forcedsettings = false
local isforcedsettings = false
local disabledsettings = false
local isdisabledsettings = false
--onload
local LOD
local LODDEF
local pssmquality
local SQ
local lodBias = im.FloatPtr(0)
local grassBias = im.FloatPtr(0)
local uifps = im.FloatPtr(30)
local grass
local GQ
local terquat
local LT
local detailCount
local DC
local LQ
local tRL
local rTS
local dS
local mirTex
local refTex

--game version
local ver = nil
local bigver = nil

--platforms
local isVulkan = 0
local isLinux = 0
local gpuMem
local gpuName
local cpuName
local cpuCores
local cpuThreads
local totalUsage = 0
local physRam
local usedRam

--settings
local ProjectName = "BeamMP_RP_Plugin"
local logTag = 'BeamMP_RP_Plugin_mod'
local posPath = "/settings/BeamMP/RolePlay/"..ProjectName.."/position.json"
local settingsPath = "/settings/BeamMP/RolePlay/"..ProjectName.."/ckgraphics.json"
local appTitle = "Main Menu - ".. ProjectName

function round(numder,p)
	local p = p or 2
	return tonumber(string.format("%."..p.."f",numder)) 
end

local function onWorldReadyState(worldReadyState)
	if worldReadyState == 2 then
		local data = jsonReadFile(posPath)
		--core_vehicles.spawnNewVehicle("unicycle",{pos =vec3(1147,1030,163)})
		if type(data) == "nil" then
			log('D', 'simpletrace', "FileNotFaund")
			core_vehicles.spawnNewVehicle("unicycle",{pos = vec3(
			711+(math.random()),
			-54+(math.random()),
			53+(math.random())
			)})
		elseif type(data) == "table" then
			log("D", "simpletrace","HomeFindet")
			local x = tonumber(round(data[1]))
			local y = tonumber(round(data[2]))
			local z = tonumber(round(data[3]))
			local vec = vec3(x,y,z)
			core_vehicles.spawnNewVehicle("unicycle",{pos =vec})
		else
			log('W', 'simpletrace', "FileNotFaund")
			core_vehicles.spawnNewVehicle("unicycle",{pos = vec3(
			711+(math.random()),
			-54+(math.random()),
			53+(math.random())
			)})
		end
		core_camera.setByName(be:getPlayerVehicle(0))
	end
end

--game version check
local function gameVER()
  ver = beamng_version
  bigver = string.format("%0.4s", ver)
  --print(bigver)
end

--get api info to prevent vk
local function getGFX()
	gameVER()
	local gfx = Engine.Render.getAdapterType()
	if not string.match(gfx, "Direct3D11") then
	  isVulkan = 1
	  log('W', '', 'Vulkan API mode detected' )

	  else
	  log('I', '', 'Vulkan API mode not detected' )
	end
end

--get os version
local function getOS()
  local os = Engine.Platform.getOSInfo()
  --print(dump(os))
  --print(os.shortname)
  if os.type == "linux" then
    isLinux = 1
    log('I', '', 'Linux Detected' )
  elseif os.type == "windows" then
    log('I', '', 'Windows Detected' )
  else
    log('W', '', 'Couldnt get os type' )
    isLinux = 2
  end
end

local function getGPU()
  local gpu = Engine.Platform.getGPUInfo()
  if gpu then
    gpuName = gpu.name
    gpuMem = gpu.memoryMB
  end
end

local function setFPS(uifps)
	scenetree.maincef:setMaxFPSLimit(tonumber(uifps))
end 

local function getCPU()
  local cpu = Engine.Platform.getCPUInfo()
  if cpu then
    cpuName = cpu.name
    cpuCores = cpu.coresPhysical
    cpuThreads = cpu.coresLogical
  end
end

local function updateMemStats()
  local memory = Engine.Platform.getMemoryInfo()
  if memory then
    physRam = memory.osPhysAvailable
    usedRam = memory.processPhysUsed
  end
end

local function updateGPUStats()
  local vram
  if tonumber(bigver) >= 0.31 then
    vram = Engine.Render.calculateGfxMemory()
  end
  totalUsage = 0
  if vram then
    for k,v in pairs(vram) do
      totalUsage = totalUsage + v
    end
  end
end

local function settingsSave()
  updateMemStats()
  updateGPUStats()
  local s = {
    forcedsettings = forcedsettings,
    ssaoenabled = ssaoenabled,
    pssmenabled = pssmenabled,
    terenabled = terenabled,
    pssmlenabled = pssmlenabled,
    detailenabled = detailenabled,
    terlenabled = terlenabled,
    textenabled = textenabled,
    refenabled = refenabled,
    mirenabled = mirenabled,
    disabledsettings = disabledsettings,
    grass = grass,
    LOD = LOD,
  }
  jsonWriteFile(settingsPath, s, true)

end

local function settingsLoad()
  local s = jsonReadFile(settingsPath)
  if s then
    disabledsettings = s.disabledsettings or false
    if disabledsettings == true then
      log('W', '', 'User does not want to load settings' )
    else
    log('I', '', 'Applying settings' )
    forcedsettings = s.forcedsettings or false
    ssaoenabled = s.ssaoenabled or false
    pssmenabled = s.pssmenabled or false
    terenabled = s.terenabled or false
    pssmlenabled = s.pssmlenabled or false
    detailenabled = s.detailenabled or false
    terlenabled = s.terlenabled or false
    textenabled = s.textenabled or false
    refenabled = s.refenabled or false
    mirenabled = s.mirenabled or false
    grass = s.grass or grass or 1
    LOD = s.LOD or LODDEF or 1
    TorqueScriptLua.setVar("$pref::GroundCover::densityScale", grass)
    TorqueScriptLua.setVar("$pref::TS::detailAdjust", LOD)
    end
  end
end

local function onExtensionLoaded()
  getGFX(gfx)
  getOS(os)
  getGPU()
  getCPU()
  updateMemStats()
  updateGPUStats()
  if isVulkan ~= 2 then
    log('I', '', 'Graphics data is loaded' )
    LOD = tonumber(TorqueScriptLua.getVar("$pref::TS::detailAdjust"))
    pssmquality = tonumber(TorqueScriptLua.getVar("$pref::Shadows::textureScalar"))
    grass = tonumber(TorqueScriptLua.getVar("$pref::GroundCover::densityScale"))
    terquat = tonumber(TorqueScriptLua.getVar("$pref::Terrain::detailScale"))
    detailCount = tonumber(TorqueScriptLua.getVar("$pref::TS::maxDecalCount"))
    tRL = tonumber(TorqueScriptLua.getVar("$pref::Video::textureReductionLevel"))
    rTS = tonumber(TorqueScriptLua.getVar("$pref::Reflect::refractTexScale"))
    dS = tonumber(TorqueScriptLua.getVar("pref::Terrain::detailScale"))
    refTex = tonumber(TorqueScriptLua.getVar("$pref::BeamNGVehicle::dynamicReflection::textureSize"))
    mirTex = tonumber(TorqueScriptLua.getVar("$pref::BeamNGVehicle::dynamicMirrors::textureSize"))
    LODDEF = LOD
    SQ = pssmquality
    GQ = grass
    LT = terquat
    DC = detailCount
    LQ = tRL
    settingsLoad()
  end
  if showUI == nil then
    showUI = ui_imgui.BoolPtr(false)
  end
end

local function getConsoleNumber(varName)
  local result = getConsoleVariable(varName)
  return result == "" and -1 or result
end

local imguipos
local imguisize
local screenSize
local offset = {}

local function onPreRender()
  local ScreenBlurFX = scenetree.ScreenBlurFX
  if ScreenBlurFX and imguipos and imguisize and ui_visibility.get() ~= false and showUI[0] == true then
    local options = core_settings_graphic.getOptions()
    local displayMode = options.GraphicDisplayModes.displayMode
    local offsetW = {x = 0, y = 0}
    if displayMode == "Window" then
      offsetW = {x = 7, y = 31}
    end
    local xTCorner = (imguipos.x - offset[7]-offsetW.x) / screenSize.x
    local yTCorner = (imguipos.y - offset[8]-offsetW.y) / screenSize.y
    local xBCorner = imguisize.x / screenSize.x
    local yBCorner = imguisize.y / screenSize.y
    ScreenBlurFX.obj:addFrameBlurRect(xTCorner, yTCorner, xBCorner, yBCorner, ColorF(1, 1, 1, 1))
  end
end

local function resetSettings()
  log('I', '', "resetSettings")
 forcedsettings = false
 ssaoenabled = false
 pssmenabled = false
 terenabled = false
 pssmlenabled = false
 detailenabled = false
 terlenabled = false
 textenabled = false
 settingsSave()
 scenetree.SSAOPostFx:setSamples(16)
 if SQ == nil then
   TorqueScriptLua.setVar("$pref::Shadows::textureScalar", 1)
   TorqueScriptLua.setVar("$pref::Shadows::filterMode", "SoftShadowHighQuality")
 else
 TorqueScriptLua.setVar("$pref::Shadows::textureScalar", SQ)
 TorqueScriptLua.setVar("$pref::Shadows::filterMode", "SoftShadowHighQuality")
 end
 if GQ == nil then
   TorqueScriptLua.setVar("$pref::GroundCover::densityScale", 1)
 else
   TorqueScriptLua.setVar("$pref::GroundCover::densityScale", GQ)
 end
 if LT == nil then
   TorqueScriptLua.setVar("$pref::Terrain::lodScale", 0.75)
 else
   TorqueScriptLua.setVar("$pref::Terrain::lodScale", LT)
 end
 if LODDEF == nil then
   TorqueScriptLua.setVar("$pref::TS::detailAdjust", 1)
 else
 TorqueScriptLua.setVar("$pref::TS::detailAdjust", LODDEF)
 end
 if DC == nil then
   TorqueScriptLua.setVar("$pref::TS::maxDecalCount", 4000)
   TorqueScriptLua.setVar("$pref::TS::skipRenderDLs", 0)
 else
 TorqueScriptLua.setVar("$pref::TS::maxDecalCount", DC)
 TorqueScriptLua.setVar("$pref::TS::skipRenderDLs", 0)
 end
 if LQ == nil then
   TorqueScriptLua.setVar("$pref::Video::textureReductionLevel", LQ)
   TorqueScriptLua.setVar("$pref::Reflect::refractTexScale", rTS)
   TorqueScriptLua.setVar("$pref::Terrain::detailScale", dS)
   reloadTextures()
 else
   TorqueScriptLua.setVar("$pref::Video::textureReductionLevel", 0)
   TorqueScriptLua.setVar("$pref::Reflect::refractTexScale", 1)
   TorqueScriptLua.setVar("$pref::Terrain::detailScale", 1)
   reloadTextures()
 end
 if mirTex == nil then
   TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicMirrors::textureSize', 256 )
 else
   TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicMirrors::textureSize', mirTex )
 end
 if refTex == nil then
   TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize', 256 )
 else
   TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize', refTex )
 end
end

local function settingsMenu()
  if im.Button("Set Home") then
	jsonWriteFile(posPath,{be:getPlayerVehicle(0):getPositionXYZ()})
  end
  im.Separator()
  if im.TreeNode1("Включатели Крутой Графики") then
  im.Separator()

  local ssaoQEnabled = im.BoolPtr(ssaoenabled)
  if im.Checkbox("Quality GTAO", ssaoQEnabled) then
    ssaoenabled = ssaoQEnabled[0]
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Изменяет количество образцов окружающей окклюзии и ее радиус")
    im.EndTooltip()
  end
  im.Separator()

  local pssmQEnabled = im.BoolPtr(pssmenabled)
  if im.Checkbox("Более высокое разрешение теней", pssmQEnabled) then
    pssmenabled = pssmQEnabled[0]
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Устанавливает для всех солнечных теней значение 4096px")
    im.EndTooltip()
  end
  im.Separator()
  
  im.TreePop()
  end

  im.Separator()

  if im.TreeNode1("Включатели Картошко Графики") then
    im.Separator()

    local pssmLQEnabled = im.BoolPtr(pssmlenabled)
    if im.Checkbox("Более низкое разрешение теней", pssmLQEnabled) then
      pssmlenabled = pssmLQEnabled[0]
    end
    if im.IsItemHovered() then
      im.BeginTooltip()
      im.Text("Устанавливает для всех солнечных теней значение 128px и отключает фильтрацию PSSM")
      im.EndTooltip()
    end
    im.Separator()

    local textLQEnabled = im.BoolPtr(textenabled)
    if im.Checkbox("Более низкое качество текстуры", textLQEnabled) then
      textenabled = textLQEnabled[0]
    end
    if im.IsItemHovered() then
      im.BeginTooltip()
      im.Text("Уменьшает разрешение текстуры, снижает качество преломления и изменяет расстояние рендеринга текстуры рельефа")
      im.EndTooltip()
    end
    im.TreePop()
  end

	im.Separator()

  im.Text("Базовые настройки")
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Изменяет плотность почвенного покрова и расстояние рендеринга")
    im.EndTooltip()
  end
  grassBias[0] = tonumber(TorqueScriptLua.getVar("$pref::GroundCover::densityScale") or 1) * 100
  im.PushItemWidth(128)
  if im.SliderFloat("", grassBias, 50, 800, "%.1f") then
    grass = grassBias[0] / 100
    TorqueScriptLua.setVar("$pref::GroundCover::densityScale", grass)
    settingsSave()
  end
  im.SameLine()
  if im.Button("Сбросить Колл-во Травы") then
    forcedsettings = false
    if GQ == nil then
      TorqueScriptLua.setVar("$pref::GroundCover::densityScale", 1)
    else
    TorqueScriptLua.setVar("$pref::GroundCover::densityScale", GQ)
    end
  end
  im.Separator()

  im.Text("Дальность видимости LOD")
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Изменяет степень рендеринга объектов")
    im.EndTooltip()
  end
  lodBias[0] = tonumber(TorqueScriptLua.getVar("$pref::TS::detailAdjust") or 1) * 100
  im.PushItemWidth(128)
  if im.SliderFloat("##", lodBias, 50, 400, "%.1f") then
    LOD = lodBias[0] / 100
    TorqueScriptLua.setVar("$pref::TS::detailAdjust", LOD)
    settingsSave()
  end
  im.SameLine()
  if im.Button("Сбросить LOD") then
    forcedsettings = false
    if LODDEF == nil then
      TorqueScriptLua.setVar("$pref::TS::detailAdjust", 1)
    else
    TorqueScriptLua.setVar("$pref::TS::detailAdjust", LODDEF)
    end
  end
  im.Separator()


  if im.SliderFloat("Max FPS Виджетов", uifps, 14, 244, "%.0f") then
    setFPS(uifps[0])
  end
  im.Separator()


  if im.Button("Сбросить все") then
    resetSettings()
  end
  if im.IsItemHovered() then
    im.BeginTooltip()
    im.Text("Сбрасывает все настройки до исходных")
    im.EndTooltip()
  end
end

local frameCnt = 0
local function statisticsMenu()
  frameCnt = frameCnt + 1
  if frameCnt > 10 then
    updateMemStats()
    updateGPUStats()
    frameCnt = 0
  end
  local dataText
  im.Text("Graphics API: ")
    im.SameLine()
    if isVulkan == 1 then
      im.Text("Vulkan API")
    else
      im.Text("Direct3D11")
    end
    im.Text("OS: ")
    --same but Linux
    im.SameLine()
    if isLinux == 1 then
      im.Text("Linux")
    elseif isLinux == 2 then
      im.Text("nil")
    else
      im.Text("Windows")
    end
    im.Text("CPU: ")
    im.SameLine()
    im.Text(tostring(cpuName))
    im.Text("CPU Cores: ")
    im.SameLine()
    im.Text(tostring(cpuCores)..'/'..tostring(cpuThreads))
    im.Text("RAM: ")
    im.SameLine()
    im.Text(string.format("%d", tostring(usedRam*0.000001))..'MB/'..string.format("%d", tostring(physRam*0.000001))..'MB')
    im.Text("GPU: ")
    im.SameLine()
    im.Text(tostring(gpuName))
    im.Text("GPU Memory: ")
    im.SameLine()
    im.Text(string.format("%d", tostring(totalUsage*0.000001))..'MB/'..tostring(gpuMem)..'MB')
    im.Text("FPS: ")
    im.SameLine()
    dataText = string.format("%d", getConsoleNumber("fps::instantaneous"))
    im.Text(dataText)
    im.Text("Drawcalls: ")
    im.SameLine()
    dataText =  string.format("%d", getConsoleNumber("$GFXDeviceStatistics::drawCalls"))
    im.Text(dataText)
    im.Text("Polycount: ")
    im.SameLine()
    dataText =  string.format("%d", getConsoleNumber("$GFXDeviceStatistics::polyCount"))
    im.Text(dataText)
end

local function renderImgui()
  im.PushStyleVar1(im.StyleVar_WindowRounding, 3.0)
  im.PushStyleVar1(im.StyleVar_WindowBorderSize, 0.0)
  im.PushStyleColor2(im.Col_TitleBgActive, im.ImVec4(0.15, 0.15, 0.15, 0.75))
  im.PushStyleColor2(im.Col_TitleBg, im.ImVec4(0.15, 0.15, 0.15, 0.75))
  im.PushStyleColor2(im.Col_WindowBg, im.ImVec4(0.15, 0.15, 0.15, 0.75))
  im.PushStyleColor2(im.Col_TitleBgCollapsed, im.ImVec4(0.15, 0.15, 0.15, 0.45))
  im.PushStyleColor2(im.Col_FrameBg, im.ImVec4(0.1, 0.1, 0.1, 0.45))
  im.PushStyleColor2(im.Col_PopupBg, im.ImVec4(0.1, 0.1, 0.1, 0.95))
  im.PushStyleColor2(im.Col_PlotHistogram, im.ImVec4(0.9, 0.4, 0.1, 1))
  im.PushStyleColor2(im.Col_PlotHistogramHovered, im.ImVec4(1, 0.5, 0.1, 1))
  im.SetNextWindowSizeConstraints(im.ImVec2(600, 260), im.ImVec2(600, 260))
  im.Begin(appTitle, showUI, im.WindowFlags_AlwaysAutoResize+im.WindowFlags_NoResize)
  imguipos = im.GetWindowPos()
  screenSize = im.GetMainViewport().Size
  imguisize = im.GetWindowSize()
  im.BeginChild1("SettingChild", im.ImVec2(imguisize.x/2, 0, false, im.WindowFlags_ChildWindow))
  settingsMenu()
  im.EndChild()
  im.SameLine()
  im.BeginChild1("StatisticChild", im.ImVec2(imguisize.x/2, 0, false, im.WindowFlags_ChildWindow))
  statisticsMenu()
  im.EndChild()
  im.End()
end

local function onUpdate(dtReal)
    --background service
    if ssaoenabled == true and isssaoenabled == false then
      isssaoenabled = true
       log('I', '', "high quality gtao")
       settingsSave()
      scenetree.SSAOPostFx:setSamples(32)
    end

    if ssaoenabled == false and isssaoenabled == true then
      isssaoenabled = false
       log('I', '', "low quality gtao")
       settingsSave()
      scenetree.SSAOPostFx:setSamples(16)
    end

    if pssmenabled == true and ispssmenabled == false then
      ispssmenabled = true
       log('I', '', "high quality pssm")
       settingsSave()
       pssmlenabled = false
      TorqueScriptLua.setVar("$pref::Shadows::textureScalar", 4)
    end

    if pssmenabled == false and ispssmenabled == true then
      ispssmenabled = false
       log('I', '', "low quality pssm")
       settingsSave()
      if SQ == nil then
        TorqueScriptLua.setVar("$pref::Shadows::textureScalar", 2)
      else
      TorqueScriptLua.setVar("$pref::Shadows::textureScalar", SQ)
      end
    end

    if terenabled == true and isterenabled == false then
      isterenabled = true
       log('I', '', "high quality ter")
       settingsSave()
       terlenabled = false
      TorqueScriptLua.setVar("$pref::Terrain::lodScale", 0.4)
    end

    if terenabled == false and isterenabled == true then
      isterenabled = false
       log('I', '', "low quality ter")
       settingsSave()
      if LT == nil then
        TorqueScriptLua.setVar("$pref::Terrain::lodScale", 0.75)
      else
        TorqueScriptLua.setVar("$pref::Terrain::lodScale", LT)
      end
    end

    if pssmlenabled == true and ispsslmenabled == false then
      ispsslmenabled = true
       log('I', '', "ultra low quality pssm")
       settingsSave()
       pssmenabled = false
      TorqueScriptLua.setVar("$pref::Shadows::textureScalar", 0.1)
      TorqueScriptLua.setVar("$pref::Shadows::filterMode", "None")
    end

    if pssmlenabled == false and ispsslmenabled == true then
      ispsslmenabled = false
       log('I', '', "low quality pssm")
       settingsSave()
      if SQ == nil then
        TorqueScriptLua.setVar("$pref::Shadows::textureScalar", 1)
        TorqueScriptLua.setVar("$pref::Shadows::filterMode", "SoftShadowHighQuality")
      else
      TorqueScriptLua.setVar("$pref::Shadows::textureScalar", SQ)
      TorqueScriptLua.setVar("$pref::Shadows::filterMode", "SoftShadowHighQuality")
      end
    end

    if detailenabled == true and isdetailenabled == false then
      isdetailenabled = true
       log('I', '', "skip rendering details")
       settingsSave()
      TorqueScriptLua.setVar("$pref::TS::maxDecalCount", 0)
      TorqueScriptLua.setVar("$pref::TS::skipRenderDLs", 8)
    end

    if detailenabled == false and isdetailenabled == true then
      isdetailenabled= false
       log('I', '', "render details")
       settingsSave()
      if DC == nil then
        TorqueScriptLua.setVar("$pref::TS::maxDecalCount", 4000)
        TorqueScriptLua.setVar("$pref::TS::skipRenderDLs", 0)
      else
      TorqueScriptLua.setVar("$pref::TS::maxDecalCount", DC)
      TorqueScriptLua.setVar("$pref::TS::skipRenderDLs", 0)
      end
    end

    if terlenabled == true and isterlenabled == false then
      isterlenabled = true
       log('I', '', "ultra low quality ter")
       settingsSave()
       terenabled = false
      TorqueScriptLua.setVar("$pref::Terrain::lodScale", 8)
    end

    if terlenabled == false and isterlenabled == true then
      isterlenabled = false
       log('I', '', "low quality ter")
       settingsSave()
      if LT == nil then
        TorqueScriptLua.setVar("$pref::Terrain::lodScale", 0.75)
      else
        TorqueScriptLua.setVar("$pref::Terrain::lodScale", LT)
      end
    end

    if textenabled == true and istextenabled == false then
      istextenabled = true
       log('I', '', "ultra low quality textures")
       settingsSave()
      TorqueScriptLua.setVar("$pref::Video::textureReductionLevel", 3)
      TorqueScriptLua.setVar("$pref::Reflect::refractTexScale", 0.1)
      TorqueScriptLua.setVar("$pref::Terrain::detailScale", 0.05)
      reloadTextures()
    end

    if textenabled == false and istextenabled == true then
      istextenabled = false
       log('I', '', "low quality textures")
       settingsSave()
      if LQ == nil then
        TorqueScriptLua.setVar("$pref::Video::textureReductionLevel", LQ)
        TorqueScriptLua.setVar("$pref::Reflect::refractTexScale", rTS)
        TorqueScriptLua.setVar("$pref::Terrain::detailScale", dS)
        reloadTextures()
      else
        TorqueScriptLua.setVar("$pref::Video::textureReductionLevel", 0)
        TorqueScriptLua.setVar("$pref::Reflect::refractTexScale", 1)
        TorqueScriptLua.setVar("$pref::Terrain::detailScale", 1)
        reloadTextures()
      end
    end

    if refenabled == true and isrefenabled == false then
      isrefenabled = true
      settingsSave()
      TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize', 2048 )
    end

    if mirenabled == true and ismirenabled == false then
      ismirenabled = true
      settingsSave()
      TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicMirrors::textureSize', 2048 )
    end

    if refenabled == false and isrefenabled == true then
      isrefenabled = false
      settingsSave()
      if refTex == nil then
        TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize', 256 )
      else
        TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicReflection::textureSize', refTex )
      end
    end

    if mirenabled == false and ismirenabled == true then
      ismirenabled = false
      settingsSave()
      if mirTex == nil then
        TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicMirrors::textureSize', 256 )
      else
        TorqueScriptLua.setVar( '$pref::BeamNGVehicle::dynamicMirrors::textureSize', mirTex )
      end
    end

    if forcedsettings == true and isforcedsettings == false then
      log('I', '', "Settigns are forced")
      settingsSave()
    end

    if forcedsettings == true then
      isforcedsettings = true

       local LODnow = tonumber(TorqueScriptLua.getVar("$pref::TS::detailAdjust"))
       if LOD then
        if LODnow ~= LOD then
          TorqueScriptLua.setVar("$pref::TS::detailAdjust", LOD)
         end
       end

       local GCnow = tonumber(TorqueScriptLua.getVar("$pref::GroundCover::densityScale"))
       if grass then
        if GCnow ~= grass then
          TorqueScriptLua.setVar("$pref::GroundCover::densityScale", grass)
         end
       end

       if ssaoenabled == true then
        scenetree.SSAOPostFx:setSamples(32)
       end

    end

    if forcedsettings == false and isforcedsettings == true then
      isforcedsettings = false
       log('I', '', "Disabled forcing settings")
       settingsSave()
       local LOD = tonumber(TorqueScriptLua.getVar("$pref::TS::detailAdjust"))
       local GC = tonumber(TorqueScriptLua.getVar("$pref::GroundCover::densityScale"))
    end

  if not showUI[0] then
     return
    end
  --imgui app
  local canvas = scenetree.findObject("Canvas")
  canvas = tostring(canvas:getPlacement())
  offset = {}
  for x in canvas:gmatch("%-?%d+") do table.insert(offset, x) end
  renderImgui()
end

local function onClientEndMission()
  if disabledsettings == true then
    resetSettings()
  end
end

local function onExit()
   log('I', '', "Quitting game, resetting all changes")
   resetSettings()
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
M.onWorldReadyState = onWorldReadyState
M.onExtensionLoaded = onExtensionLoaded
M.onClientEndMission = onClientEndMission
M.onPreRender = onPreRender
M.onUpdate = onUpdate
M.onExit = onExit
return M
