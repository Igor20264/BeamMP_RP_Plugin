--[[
Created by vJoeyz#5115 (Uncle Joey)
Please do not redistribute
]]--

local config = {}
config.reset = {}
config.motd = {}
config.timesync = {}
config.weathersync = {}

config.messageDuration = 5000 -- global toast message duration in ms

config.restrictMenu = true -- enables or disables (side-)menu for mods, spawning vehicles, tuning, environment, trackbuilder and replay

config.reset.enabled = true -- enables or disables the ability to reset vehicles
config.reset.timeout = 10 -- how often a vehicle can be reset, -1 for no limit
config.reset.title = "Ограничение Удаления Авто" -- title shown when resetting is limited or disabled
config.reset.message = "Вы можете удалить машину через {secondsLeft} секунд." -- message shown when resetting is limited
config.reset.disabledMessage = "Vehicle resetting is disabled on this server." -- message shown when resetting is completely disabled

config.motd.enabled = true -- enables or disables the motd
config.motd.type = "htmlOnly" -- htmlOnly: simple (large) motd || selectableVehicle: motd with the ability to select a vehicle
config.motd.title = "Добро пожаловать на BeamMP_RP_Plugin!"
config.motd.description = [[
    [br]
    [br]
    [h2][color=#ff6600] Помните про правила и не нарушайте их![/color][/h2]
    [h2] Приятной игры на BeamMP_RP_Plugin❤️![/h2]
    [br][br]
    [color=#FFC0CB][i][right]by BeamMP_RP_Plugin[/right][/i][/color]
]] -- all bbcodes can be found in README.md

config.timesync.enabled = false -- enables or disables in-game time syncing to real world time
config.timesync.offsetHours = 0 -- 0 for utc, can be positive (+) or negative (-)
config.timesync.realtime = false -- whether in-game time should be actively synced with real world time (only works when timesync.enabled = true)

-- NOTE: not all weather settings work on all maps
config.weathersync.enabled = false -- enables or disables in-game weather syncing
config.weathersync.cloudCover = 30 -- 0-100 (0 = no clouds; 100 = very cloudy)
config.weathersync.windSpeed = 1 -- 0-10 (0 = no wind; 10 = very windy) -- affects clouds and rain
config.weathersync.rainDrops = 20 -- 0-100 (0 = no rain; 100 = very rainy)
config.weathersync.rainIsSnow = false -- set to true to enable snow
config.weathersync.fogDensity = 0 -- 0-100 (0 = no fog; 100 = very foggy)
config.weathersync.gravity = -9.81 -- -9.81 = earth

return config