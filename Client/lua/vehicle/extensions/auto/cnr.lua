local M = {}
local own = false
local fuelName = "mainTank"
local myTime = 0
local lightbarEnabled = "false"
local posTime = 0
local idleTime = 0
local fuelSendTime = 0
curValue = 0

function PTW()
	local p = powertrain.getDevicesByCategory("engine")[1].maxPower
	local w = obj:calcBeamStats().total_weight
	local data = tostring(string.format("%.2f",p/w))
	obj:queueGameEngineLua('cnr.ptw(' .. data .. ')')
end

--Really should make this into the other function but im the only one who works on this so whatever
function PTW2()
	local p = powertrain.getDevicesByCategory("engine")[1].maxPower
	local w = obj:calcBeamStats().total_weight
	local data = tostring(string.format("%.2f",p/w))
	obj:queueGameEngineLua('cnr.setPerfLevel(' .. data .. ')')
end

function freezeCar(state)
    controller.setFreeze(state)
end

function setCur(data)
	curValue = tonumber(data)
end

function setTankName(data)
	if data ~= nil then	
		fuelName = data
	end
end

function setOwn()
	if own == false then
		own = true
		fuelName = "mainTank"
	end
end

function dStat()
	local q = 0
	local p = 0
	if own == true then
	local dam = beamstate.getPartDamageData()
		if dam ~= nil then
			for k,v in pairs(dam) do
				p = p + 1
				q = dam[k].damage + q
			end
		end
	end
	obj:queueGameEngineLua('cnr.setD(' .. tostring(p) .. ')')
	obj:queueGameEngineLua('cnr.setDs(' .. tostring(q) .. ')')
	q = 0
	p = 0
end

local dTime = 0
local function updateGFX(dt)
	if own == true then
		dTime = dTime + dt
		posTime = posTime + dt
		if dTime >= .5 then
			dStat()
			dTime = 0
			if ai.mode ~= "disabled" then
				obj:queueGameEngineLua('cnr.robFail()')
				ai.setMode("disabled")
			end
		end

		if posTime >= 1 then
			fuelSendTime = fuelSendTime + 1
			vehicleSpeed()
			--dStat()
			if electrics.values.lightbar >= 1 and lightbarEnabled == "false" then
				lightbarEnabled = "true"
				obj:queueGameEngineLua('cnr.lightbar(' .. tostring(lightbarEnabled) .. ')')
				print("datasending")
				posTime = 0
			elseif electrics.values.lightbar == 0 and lightbarEnabled == "true" then
				lightbarEnabled = "false"
				obj:queueGameEngineLua('cnr.lightbar(' .. tostring(lightbarEnabled) .. ')')
				print("datasending")
				posTime = 0
			end
			posTime = 0

		end
		if fuelSendTime >= 30 then
			fuelSendTime = 0
			for name, storage in pairs(energyStorage.getStorages()) do
				--Temp patch for NOS bug
				print(storage.energyType)
				if storage.energyType == "n2o" or storage.energyType == "air" then
				else
					print("--------------------------------------------------------------------")
					local x = energyStorage.getStorage(name).remainingRatio
					obj:queueGameEngineLua("cnr.sendFuel(" .. tostring(x).. ")")
				end
			end
		end
	end	
end

--Needs to be changed soon, will store gas on an X gallons/liters instead of % tank -Done server side
function setFuel(data)
	print("setfuel")
		print(data)
	if data ~= nil then
		print(data)
		local i = 0
		local total = tonumber(data)
		
		for name, storage in pairs(energyStorage.getStorages()) do
			--Temp patch for NOS bug
				if storage.energyType == "n2o" or storage.energyType == "air" then
			else
				i = i + 1
			end
		end
		if i > 1 then
			for name, storage in pairs(energyStorage.getStorages()) do
			--Temp patch for NOS bug
				if storage.energyType == "n2o" or storage.energyType == "air" then
				else
				--very dirty temp fix
					energyStorage.getStorage(name):setRemainingRatio(total + (1/i))
				end
			end
		else
			for name, storage in pairs(energyStorage.getStorages()) do
			--Temp patch for NOS bug
				if storage.energyType == "n2o" or storage.energyType == "air" then

				else
					energyStorage.getStorage(name):setRemainingRatio(total)
				end
			end
		end
	end
end

M.PTW = PTW	
M.PTW2 = PTW2	
M.setFuel = setFuel
M.setTankName = setTankName	
M.setCur = setCur
M.vehicleSpeed = vehicleSpeed
M.setOwn = setOwn
M.freezeCar = freezeCar
M.updateGFX = updateGFX


return M
	
