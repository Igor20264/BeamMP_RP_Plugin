local M = {}
local distancem = 0
local distanceTotalm = 0
local distanceTotalkm = 0
local Speed = 0
local topSpeed = 0
local state = {}
local all = {}

local function onInit()
	distanceTotalm = 0
	topSpeed = 0
	--print('onInit')	
	--print("Totalm: " .. distanceTotalm)
	state.progress = distanceTotalm
	guihooks.trigger('sendState', state)
end

local function onReset()
	distanceTotalm = 0
	topSpeed = 0
	--print('onReset')
	--print("Totalm: " .. distanceTotalm)
	state.progress = distanceTotalm
	guihooks.trigger('sendState', state)
end

local function updateGFX(dt)
	distancem = electrics.values.wheelspeed * dt
	distanceTotalm = distancem + distanceTotalm
	Speed = electrics.values.wheelspeed * 3.6
	if Speed > topSpeed then
	  topSpeed = Speed
	end
end

local function getVar()
	state.fuelPercent = electrics.values['fuel']
	state.fuelCap = electrics.values['fuelCapacity']
	state.fuelVol = electrics.values['fuelVolume']
	state.tSpeed = topSpeed
	state.carModel = v.config.model
	state.carConfig = v.config.partConfigFilename
	state.progress = distanceTotalm
	guihooks.trigger('sendState', state)
	--return distanceTotalm
end

local function getAllVar()
	all.carConfig2 = v.config.partConfigFilename
	all.progress2 = distanceTotalm
	guihooks.trigger('sendAllState', all)
	--return distanceTotalm
end

M.onInit = onInit
M.onReset = onReset
M.updateGFX = updateGFX
M.getVar = getVar
M.getAllVar = getAllVar

return M
