local M = {}

local timeSinceLastUpdate = 0
local serverTod = nil
local doCompensation = false

local driftTreshold = 0.005

local maxHoursPerFrame = 100

local otherPlayerLightsOffTime = 0
local OTHER_PLAYER_LIGHTS_FREQUENCY = 1
local OTHER_PLAYER_LIGHTS_MIN_DISTANCE = 200

local timeSinceLastSkyBrightnessCheck = 0
local CHECK_SKY_BRIGHTNESS_INTERVAL = 3
local NIGHT_BRIGHTNESS = 2.5

local currentlyIsDay = true

local sunskyObject = nil

local function isDay(time)
	return time < 0.27 or time > 0.75
end

local function shouldLightsBeOn(time)
	return time > 0.22 and time < 0.79
end

local function signedSquare(x)
	if x < 0 then
		return -1 * x * x
	else
		return x * x
	end
end

local function gameToPrintable(gameTime)
	local tvelve2twentyfour = (gameTime + 0.5) % 1
	local hours = tvelve2twentyfour * 24

	local hoursWhole = math.floor(hours)

	local minsFraction = hours % 1
	local mins = minsFraction * 60
	local minsWhole = math.floor(mins)

	return string.format("%02d:%02d", hoursWhole, minsWhole)
end

local function getTimeOfDay()
	--return core_environment.getObject("TimeOfDay")
	return core_environment.getTimeOfDay()
end

-- returns how much a is ahead b (wraps around 1)
local function isAhead(a, b)
	local d = a - b

	if d > 0.5 then -- b wrapped around and is actually ahead
		d = d - 1
	elseif d < -0.5 then -- a wrapped around and is actually ahead
		d = 1 + d
	end

	return d
end

local canTurnLightsOn = true
local canTurnLightsOff = true
local function setLightsState(time, skipChecks)
	local playerVeh = be:getPlayerVehicle(0)
	if not playerVeh or not MPVehicleGE.isOwn(playerVeh:getId()) then
		return
	end

	-- night: turn lights on
	if shouldLightsBeOn(time) then
		if canTurnLightsOn or skipChecks then
			playerVeh:queueLuaCommand("electrics.setLightsState(2)")
			playerVeh:queueLuaCommand("electrics.set_fog_lights(1)")
			playerVeh:queueLuaCommand("electrics.values.underglow = 1")

			-- log('I', 'setLightsState', "Nighttime reached, turning on headlights")

			canTurnLightsOn = false
			canTurnLightsOff = true
		end
	else -- day: turn lights off
		if canTurnLightsOff or skipChecks then
			playerVeh:queueLuaCommand("electrics.setLightsState(0)")
			playerVeh:queueLuaCommand("electrics.set_fog_lights(0)")
			playerVeh:queueLuaCommand("electrics.values.underglow = 0")

			-- log('I', 'setLightsState', "Daytime reached, turning off headlights")

			canTurnLightsOff = false
			canTurnLightsOn = true
		end
	end
end

local function adjustTimeScale(tod, aheadByScaled, aheadByString)
	--mult = mult * -aheadByScaled
end

local function sendTimeToVE(t)
	local veh = be:getPlayerVehicle(0)

	if not veh or not MPVehicleGE.isOwn(veh:getId()) then
		return
	end

	veh:queueLuaCommand(string.format("if clock and clock.setTime then clock.setTime(%f) end", t))
end

local function checkTurnOtherPlayerLightsOff()
	if otherPlayerLightsOffTime <= OTHER_PLAYER_LIGHTS_FREQUENCY then
		return
	end

	otherPlayerLightsOffTime = 0

	local tod = getTimeOfDay()
	local playerVeh = be:getPlayerVehicle(0)
	local prePos = playerVeh:getPosition()
	local playerPos = {}
	table.insert(playerPos, prePos.x)
	table.insert(playerPos, prePos.y)
	table.insert(playerPos, prePos.z)

	if isDay(tod.time) then
		return
	end

	for _, nonPlayerCar in pairs(getAllVehicles()) do
		if not MPVehicleGE.isOwn(nonPlayerCar:getId()) then
			local preNonPos = nonPlayerCar:getPosition()
			local pos = {}
			table.insert(pos, prePos.x)
			table.insert(pos, prePos.y)
			table.insert(pos, prePos.z)

			local distance = math.abs(distance3d(playerPos, pos))

			if distance <= OTHER_PLAYER_LIGHTS_MIN_DISTANCE then
				print("TURNING LIGHTS OFF FOR: " .. nonPlayerCar:getId())
				nonPlayerCar:queueLuaCommand("electrics.setLightsState(2)")
				nonPlayerCar:queueLuaCommand("electrics.set_fog_lights(1)")
			else
				print("TURNING LIGHTS OFF FOR: " .. nonPlayerCar:getId())
				nonPlayerCar:queueLuaCommand("electrics.setLightsState(0)")
				nonPlayerCar:queueLuaCommand("electrics.set_fog_lights(0)")
			end
		end
	end
end

local function checkSkyBrightness(deltaTime, tod)
	if timeSinceLastSkyBrightnessCheck < CHECK_SKY_BRIGHTNESS_INTERVAL then
		timeSinceLastSkyBrightnessCheck = timeSinceLastSkyBrightnessCheck + deltaTime
		return
	end

	timeSinceLastSkyBrightnessCheck = 0

	if not sunskyObject then
		sunskyObject = scenetree.findObject("sunsky")
	end

	if sunskyObject and sunskyObject.setField then
		if isDay(tod.time) or not shouldLightsBeOn(tod.time) then
			sunskyObject:setField("brightness", 0, 1)

			sunskyObject:postApply()
		else
			sunskyObject:setField("moonElevation", 0, 90)
			sunskyObject:setField("moonLightColor", 0, "0.0196078438 0.0431372561 0.0980392247 1")
			sunskyObject:setField("brightness", 0, NIGHT_BRIGHTNESS)

			sunskyObject:postApply()
		end
	end
end

local function onUpdate(dtReal)
	-- otherPlayerLightsOffTime = otherPlayerLightsOffTime + dtReal
	-- checkTurnOtherPlayerLightsOff()
	local tod = getTimeOfDay()

	checkSkyBrightness(dtReal, tod)

	if not tod then
		return
	end

	sendTimeToVE(tod.time)

	if not doCompensation then
		return
	end

	timeSinceLastUpdate = timeSinceLastUpdate + dtReal

	local targetTime = lerp(serverTod.time, serverTod.nextTime, timeSinceLastUpdate / serverTod.tickrate)

	local secondsUntilNextUpdate = serverTod.tickrate - timeSinceLastUpdate

	local aheadBy = isAhead(tod.time, targetTime) -- positive means local time is ahead server time

	local serverScale = isDay(targetTime) and serverTod.dayScale or serverTod.nightScale

	local aheadByScaled = aheadBy / serverScale

	local aheadByString = string.format("raw: %.7f scaled: %.7f %.2f%%", aheadBy, aheadByScaled, aheadByScaled * 100)

	if math.abs(aheadBy) <= driftTreshold * 0.66 then -- aim to get closer
		doCompensation = false
		-- log('I', 'onUpdate', "reached target")
		tod.dayScale = serverTod.dayScale
		tod.nightScale = serverTod.nightScale
		tod.dayLength = serverTod.dayLength

		core_environment.setTimeOfDay(tod)

		return
	end

	local diff = -aheadByScaled -- x
	local blue = secondsUntilNextUpdate -- y
	local dayLength = serverTod.dayLength

	local bruh = diff / blue

	local bruhtimeslen = bruh * dayLength

	-- 1 ingame hour per 1 second
	local ingameHoursPerRealSecond = serverTod.dayLength / 24

	local fps = 1 / dtReal

	local maxDiff = (ingameHoursPerRealSecond / fps) * maxHoursPerFrame

	--local unclamped = -aheadByScaled * speedmultiplier
	--unclamped = signedSquare(unclamped)

	local currentScale = clamp(bruhtimeslen, -maxDiff, maxDiff) * serverScale

	tod.dayScale = currentScale
	tod.nightScale = currentScale

	-- log('I', 'onUpdate', string.format("Local time is out of sync, %s\t%s diff:%f blue:%f bruh:%f res:%f clamped:%f",
	-- (aheadByScaled > 0) and "slowing down" or "speeding up", aheadByString, diff, blue, bruh, bruhtimeslen, currentScale))

	tod.play = true

	core_environment.setTimeOfDay(tod)

	-- log('I', 'currentTime', gameToPrintable(tod.time))
end

local function receiveDayTimeFromServer(data)
	serverTod = jsonDecode(data)

	timeSinceLastUpdate = 0

	local tod = getTimeOfDay()
	if not tod then
		return
	end

	local aheadBy = isAhead(tod.time, serverTod.time) -- positive means local time is ahead server time

	local serverScale = isDay(serverTod.time) and serverTod.dayScale or serverTod.nightScale

	local aheadByScaled = aheadBy / serverScale

	-- log('I', 'currentTime', gameToPrintable(tod.time))

	-- --log('I', 'aheadBy', string.format("%.7f\t%.7f%%", aheadBy, aheadByScaled * 100))
	local aheadByString = string.format("raw: %.7f scaled: %.7f %.2f%%", aheadBy, aheadByScaled, aheadByScaled * 100)

	doCompensation = false

	if not tod.play then
		-- log('I', 'receiveDayTimeFromServer', "Local time not playing, forcing server time")
		tableMerge(tod, serverTod)
		tod.play = true

		core_environment.setTimeOfDay(tod)
	elseif math.abs(aheadBy) > driftTreshold then
		doCompensation = true
	else -- time is close enough
		-- log('I', 'receiveDayTimeFromServer', string.format("Local time is close enough (%s)", aheadByString))

		tod.dayScale = serverTod.dayScale
		tod.nightScale = serverTod.nightScale
		tod.dayLength = serverTod.dayLength

		core_environment.setTimeOfDay(tod)
	end

	-- turn car lights on/off automatically
	setLightsState(tod.time)
end

local function onExtensionLoaded()
	AddEventHandler("receiveDayTimeFromServer", receiveDayTimeFromServer)
	log("I", "onExtensionLoaded", "Time sync loaded!")
end

local function onVehicleResetted(vehID, other)
	local tod = getTimeOfDay()

	if not tod or not MPVehicleGE or not MPVehicleGE.isOwn(vehID) or not MPVehicleGE.getServerVehicleID(vehID) then
		return
	end

	-- setLightsState (skipChecks)
	setLightsState(tod.time, true)
end

M.isDay = isDay
M.shouldLightsBeOn = shouldLightsBeOn

M.onUpdate = onUpdate
M.onVehicleResetted = onVehicleResetted
M.onExtensionLoaded = onExtensionLoaded

return M
