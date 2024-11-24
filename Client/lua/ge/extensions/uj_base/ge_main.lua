--[[
Created by vJoeyz#5115 (Uncle Joey)
Edit by Hlebushek_Igor for BeamMP_RP_Plugin
Please do not redistribute
]]--

local M = {}

local config
local timeElapsedReset = 0
local timeElapsed = 0
local tryResetOld
local envObjectIdCache = {}
local tickrate = 1 -- in seconds

local vehicleSpawned

local function disableActions()
    if config.restrictActions then
        extensions.core_input_actionFilter.setGroup('uj_base', config.disabledActions)
        extensions.core_input_actionFilter.addAction(0, 'uj_base', true)
    end
end

local function tryReset(playerID)
    if not config.reset.enabled then
        guihooks.trigger('toastrMsg', {type="warning", title = config.reset.title, msg = config.reset.disabledMessage, config = {timeOut = config.messageDuration}})
        return
    end

    if timeElapsedReset >= config.reset.timeout or config.reset.timeout == -1 then
        timeElapsedReset = 0
        be:resetVehicle(playerID)
    else
        local message = config.reset.message:gsub("{secondsLeft}", math.floor(config.reset.timeout - timeElapsedReset))
        guihooks.trigger('toastrMsg', {type="warning", title = config.reset.title, msg = message, config = {timeOut = config.messageDuration}})
    end
end

local function replaceResetHook()
    tryResetOld = extensions.freeroam_freeroam.onResetGameplay
    extensions.freeroam_freeroam.onResetGameplay = tryReset
end

local function getObject(className, preferredObjName)
    if envObjectIdCache[className] then
        return scenetree.findObjectById(envObjectIdCache[className])
    end

    envObjectIdCache[className] = 0
    local objNames = scenetree.findClassObjects(className)
    if objNames and tableSize(objNames) > 0 then
        for _,name in pairs(objNames) do
            local obj = scenetree.findObject(name)
            if obj and (name == preferredObjName or not preferredObjName) then
                envObjectIdCache[className] = obj:getID()
                return obj
            end
        end
    end

    return nil
end

local function setPrecipitation(rainDrops) -- rain function has typo in core ng code
    local rainObj = getObject("Precipitation", "rain_coverage") or getObject("Precipitation")
    if rainObj and rainDrops then
        rainObj.numDrops = rainDrops

        if config.weathersync.rainIsSnow then
            rainObj.dataBlock = scenetree.findObject("Snow_menu")
        end
    end
end

local function setInitialWeather()
    if config.weathersync.enabled then
        local cloudCover = (config.weathersync.cloudCover / 100) * 2.5
        core_environment.setCloudCover(cloudCover)

        local fogDensity = config.weathersync.fogDensity / 10000
        core_environment.setFogDensity(fogDensity)

        local rainDrops = config.weathersync.rainDrops * 10
        setPrecipitation(rainDrops)

        core_environment.setWindSpeed(config.weathersync.windSpeed)

        core_environment.setGravity(config.weathersync.gravity)
    end
end

local function setTime(hours, minutes)
    local tod = core_environment.getTimeOfDay()
    tod.time = (math.abs((hours + minutes / 60) - 12) / 12) * 0.5
    core_environment.setTimeOfDay(tod)

    --print(tod.time)
end

local function syncTime(minutes)
    if config.timesync.realtime and config.timesync.enabled then
        local datetime = os.date("!*t", os.time() + (config.timesync.offsetHours * 60 + minutes) * 60)
        setTime(datetime.hour, datetime.min)
    end
end

local function setInitialTime()
    if config.timesync.enabled then
        local datetime = os.date("!*t", os.time() + config.timesync.offsetHours * 60 * 60)
        setTime(datetime.hour, datetime.min)
    end
end

local function getSign(offset)
    if offset >= 0 then
        return "+"
    end
    return ""
end

local function enableMotd()
    if config.motd.enabled then
        local description = config.motd.description:gsub("{serverTime}", os.date("!%I:%M %p", os.time() + config.timesync.offsetHours * 60 * 60) .. " UTC" .. getSign(config.timesync.offsetHours) .. config.timesync.offsetHours)
        guihooks.trigger('ScenarioChange', {name = config.motd.title, description = description, introType = config.motd.type})

        --        guihooks.trigger('ChangeState', {state = 'scenario-start', params = {data = {name=config.motd.title,buttonText="УРА!",description=description,introType=config.motd.type,showDataImmediately=true}}})
    end
end
local function onScenarioUIReady(state)
    print({state = state,text = "onScenarioUIReady"})
    if state == "start" then
        enableMotd()
    elseif state == "play" then
        if not vehicleSpawned then
            log("W", "Vehicle not spawned")
            --spawnVehicle("pickup", {})
        end
    end
end

local function spawnVehicle(model, options)
    local currentUserVehicle = be:getPlayerVehicle(0)
    if currentUserVehicle then
        core_vehicles.replaceVehicle(model, options)
    else
        core_vehicles.spawnNewVehicle(model, options)
    end
end

local function onVehicleSelected(vehicleData)
    print({vehicleData = vehicleData,text = "onVehicleSelected"})
    if config.motd.type == "selectableVehicle" then
        --enableMotd()
        if vehicleData.model and vehicleData.config then
            local userSpawningData = createPlayerSpawningData(vehicleData.model, vehicleData.config, vehicleData.color, vehicleData.licenseText)
            spawnVehicle(userSpawningData.model, userSpawningData.options)
            vehicleSpawned = true
        end
    end
end

local function onUpdate(dtReal, dtSim, dtRaw)
     timeElapsed = timeElapsed + dtReal
    if timeElapsed >= tickrate then
        syncTime(timeElapsed / 60)
    end
    timeElapsedReset = timeElapsedReset + dtReal
end

local function onExtensionLoaded()
    config = require("settings/config")
    log("W", "onExtensionLoaded")
    if config.motd.enabled then
        guihooks.trigger("ChangeState", {state = "scenario-start"})
    end

    if config.restrictMenu then
        extensions.core_gamestate.setGameState("scenario", "BeamMP_RP_Plugin","uj_base")
    end
    setInitialTime()
    setInitialWeather()
    replaceResetHook()
    disableActions()
    log("I", config.name,  "version " .. config.version .. " loaded")
end

local function onExtensionUnloaded()
    --extensions.core_gamestate.setGameState("freeroam", "freeroam", "freeroam") commenting this out fixes mp error 10038

    extensions.freeroam_freeroam.onResetGameplay = tryResetOld
    extensions.core_input_actionFilter.addAction(0, 'uj_base', false)
    log("I", config.name,  "version " .. config.version .. " unloaded, goodbye!")
    Lua:requestReload()
end

M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded
M.onUpdate = onUpdate
M.onVehicleSelected = onVehicleSelected
M.onScenarioUIReady = onScenarioUIReady

return M