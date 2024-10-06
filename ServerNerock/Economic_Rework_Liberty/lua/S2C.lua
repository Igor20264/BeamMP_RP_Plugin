local penalties = {}
local M = {}
M.info = "Система Блокровка"
M.ver = "BETA 0.2"

function onSpawn(player_id, vehicle_id, data)
	MP.TriggerClientEvent(player_id, "ECOBLOC", M.data)
	return 0
end

local triggerPlaces = {
    [1] = "Западная улица 1-Мкр",
    [2] = "Западная улица 1-Мкр",
    [3] = "Окружная улица 2-Мкр",
    [4] = "Окружная улица 2-Мкр",
    [5] = "Автострада",
    [6] = "Автострада",
    [7] = "Highway в деревне",	
    [8] = "Highway в деревне",	
    [9] = "Солнечные панели",
    [10] = "Солнечные панели",
    [11] = "Окружная улица 4-Мкр",
    [12] = "Окружная улица 4-Мкр",  
    [13] = "Центральная улица 5-Мкр",
    [14] = "Центральная улица 5-Мкр"	    
}

working = {}

function speedTrap(player_id, data)
    local speedTrapData = Util.JsonDecode(data)
    local triggerName = speedTrapData.triggerName
    local triggerNumber = tonumber(string.match(triggerName, "%d+"))
    local triggerPlace = triggerPlaces[triggerNumber] or "Неизвестно"
    
    local penalty = string.format("%.1f км/ч в зоне %.0f км/ч. Превышение на: %.1f км/ч. Место: %s. Транспортное средство: %s. Номер: %s",
        speedTrapData.playerSpeed * 3.6, speedTrapData.speedLimit * 3.6, speedTrapData.overSpeed * 3.6, triggerPlace, speedTrapData.vehicleModel, speedTrapData.licensePlate)
    
    local penalty_time = os.date("%H:%M:%S")  -- Запоминаем время штрафа
    
    table.insert(penalties, {penalty = penalty, time = penalty_time})  -- Добавляем штраф в переменную
    
    if #penalties > 10 then  -- Если количество штрафов превышает 10, удаляем старые штрафы
        for i = 1, #penalties - 10 do
            table.remove(penalties, 1)  -- Удаляем старые штрафы
        end
    end   
    -- Отправить сообщение о штрафе всем полицейским, если игрок работает
    local players = MP.GetPlayers()
    local police_list = load_database("economica.ixt") or {}
    
    for target_id, target_name in pairs(players) do
        for case, data in pairs(working) do
            if target_name == case then
                for _, police_player in ipairs(police_list) do
                    if target_name == police_player[1] then
                        local playerRank = police_player[5]
                        if playerRank == "Рядовой" or playerRank == "Сержант" or playerRank == "Лейтенант" or playerRank == "Майор" or playerRank == "Полковник" or playerRank == "Генерал" then
                            MP.SendChatMessage(target_id, "Нарушение: " .. penalty)
                        end
                    end
                end
            end
        end
    end
end

function ShowPenalties(sender_id, sender_name, message)
    local police_list = load_database("economica.ixt") or {}
    local found = false
    
    for _, playerData in ipairs(police_list) do
        if playerData[1] == sender_name then
            if playerData[5] == "Рядовой" or playerData[5] == "Сержант" or playerData[5] == "Лейтенант" or playerData[5] == "Майор" or playerData[5] == "Полковник" or playerData[5] == "Генерал" then
                found = true
                break
            end
        end
    end
    
    if not found then
        SendMessage(sender_id, "^lУ вас нет разрешения на выполнение этой команды.")
        return 1
    end

    local penalties_found = false
    for i, penalty_data in ipairs(penalties) do
        for _, police_player in ipairs(police_list) do
            if sender_name == police_player[1] then
                local playerRank = police_player[5]
                if playerRank == "Рядовой" or playerRank == "Сержант" or playerRank == "Лейтенант" or playerRank == "Майор" or playerRank == "Полковник" or playerRank == "Генерал" then
                    penalties_found = true
                    SendMessage(sender_id, "[" .. penalty_data.time .. "] " .. penalty_data.penalty)
                end
            end
        end
    end

    if not penalties_found then
        SendMessage(sender_id, "Нет превышений скорости.")
    end

    return 0
end

function ON(sender_id, sender_name, message)
    local p2, case = MessageParser(message, " ", 2)
	-- Подробнее см. E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actionFilter.lua
    -- E:\SteamLibrary\steamapps\common\BeamNG.drive\lua\ge\extensions\core\input\actions
    local target_id = tonumber(p2)
    if target_id then
        MP.TriggerClientEvent(target_id, "ECOBLOC", M.data)
    else
        local players = GetPlayers() 
        local found = false
        for player_id, player_info in pairs(players) do
            if player_info.nickname == p2 then
                MP.TriggerClientEvent(player_id, "ECOBLOC", M.data)
                found = true
                break
            end
        end
        if not found then
            SendMessage(sender_id, "^lИгрок с ником " .. p2 .. " не найден.")
            return 1
        end
    end
    
    return 0
end

function RefreshTunList()
    local tun_list = load_database("tunlist.IXT") or {}
    M.tun_list = {}

    for _, player in pairs(tun_list) do
        table.insert(M.tun_list, player)
    end
end

function TUNOFF(sender_id, sender_name, message)
    local p2, case = MessageParser(message, " ", 2)

    RefreshTunList()

    local found = false
    for _, player in ipairs(M.tun_list) do
        if player == sender_name then
            found = true
            break
        end
    end

    if not found then
        SendMessage(sender_id, "^lУ вас нет разрешения на выполнение этой команды.")
        return 1
    end

    local target_id = tonumber(p2)
    if target_id then
        MP.TriggerClientEvent(target_id, "ECOTUNLOCK", M.data)
    end
    
    return 0
end

function TUNON(sender_id, sender_name, message)
    local p2, case = MessageParser(message, " ", 2)

    RefreshTunList()

    local found = false
    for _, player in ipairs(M.tun_list) do
        if player == sender_name then
            found = true
            break
        end
    end

    if not found then
        SendMessage(sender_id, "^lУ вас нет разрешения на выполнение этой команды.")
        return 1
    end

    local target_id = tonumber(p2)
    if target_id then
        MP.TriggerClientEvent(target_id, "ECOBLOC", M.data)
    end
    
    return 0
end

function OFF(sender_id, sender_name, message)
    local p2, case = MessageParser(message, " ", 2)
    
    local target_id = tonumber(p2)
    if target_id then
        MP.TriggerClientEvent(target_id, "ECOUNBLOCK", "SA")
    else
        local players = GetPlayers() 
        local found = false
        for player_id, player_info in pairs(players) do
            if player_info.nickname == p2 then
                MP.TriggerClientEvent(player_id, "ECOUNBLOCK", "SA")
                found = true
                break
            end
        end
        if not found then
            SendMessage(sender_id, "^lИгрок с ником " .. p2 .. " не найден.")
            return 1
        end
    end
    
    return 0
end

function GetPlayerVehicles(player_id)
    local player_vehicles = {}

    local vehicles = MP.GetPlayerVehicles(player_id)

    for vehicle_id, vehicle_data in pairs(vehicles) do
        player_vehicles[vehicle_id] = vehicle_data
    end

    return player_vehicles
end

function GETVEH(sender_id, sender_name, message)
    local player_id = sender_id

    local player_vehicles = GetPlayerVehicles(player_id)

    local response_msg = "^lСписок транспортных средств игрока:\n"
    
    for vehicle_id, vehicle_data in pairs(player_vehicles) do
        response_msg = response_msg .. "ID: " .. vehicle_id .. " - Данные: " .. vehicle_data .. "\n"
    end

    SendMessage(sender_id, response_msg)

    return 0
end

function REMOVEVEHICLE(sender_id, sender_name, message)
    local args = split(message, " ")
    if #args < 2 then
        SendMessage(sender_id, "Ошибка: необходимо указать айди игрока и идентификатор транспорта для удаления.")
        return
    end
    local target_id = tonumber(args[1])
    local vehicle_id = tonumber(args[2])
    if not vehicle_id then
        SendMessage(sender_id, "Ошибка: идентификатор транспорта должен быть числом.")
        return
    end
    MP.RemoveVehicle(target_id, vehicle_id)
    SendMessage(sender_id, "Транспорт с идентификатором " .. vehicle_id .. " успешно удален у игрока с айди " .. target_id .. ".")
end

function GETPLAYERVEHICLES(sender_id, sender_name, message)
    local args = split(message, " ")
    if #args < 1 then
        SendMessage(sender_id, "Ошибка: необходимо указать идентификатор игрока для получения списка его машин.")
        return
    end
    local player_id = tonumber(args[1])
    if not player_id then
        SendMessage(sender_id, "Ошибка: идентификатор игрока должен быть числом.")
        return
    end
    
    local vehicles = MP.GetPlayerVehicles(player_id)
    if vehicles then
        local vehiclesStr = "Машины игрока с идентификатором " .. player_id .. ": "
        local isFirstVehicle = true
        for vehicle_id, vehicle_data in pairs(vehicles) do
            local jbmIndex = string.find(vehicle_data, '"jbm"')
            if jbmIndex then
                local startQuoteIndex = string.find(vehicle_data, '"', jbmIndex + 6)
                if startQuoteIndex then
                    local endQuoteIndex = string.find(vehicle_data, '"', startQuoteIndex + 1)
                    if endQuoteIndex then
                        local firstWord = string.sub(vehicle_data, startQuoteIndex + 1, endQuoteIndex - 1)
                        if not isFirstVehicle then
                            vehiclesStr = vehiclesStr .. "; "
                        end
                        vehiclesStr = vehiclesStr .. "ID: " .. vehicle_id .. ", " .. firstWord
                        isFirstVehicle = false
                    else
                        vehiclesStr = vehiclesStr .. "; ID: " .. vehicle_id .. ", Не удалось извлечь данные"
                    end
                else
                    vehiclesStr = vehiclesStr .. "; ID: " .. vehicle_id .. ", Не удалось найти первое слово после 'jbm'"
                end
            else
                vehiclesStr = vehiclesStr .. "; ID: " .. vehicle_id .. ", 'jbm' не найден в данных"
            end
        end
        SendMessage(sender_id, vehiclesStr)
    else
        SendMessage(sender_id, "Нет информации о машинах для указанного игрока.")
    end
end

M.data = ""
local data = {"vehicleEditorToggle", "editorToggle", "toggleCamera", "dropCameraAtPlayer", "slower_motion", "faster_motion", "debugmode_toggle", "toggleTraffic", "toggle_slow_motion", "nodegrabberAction", "nodegrabberStrength", "dropPlayerAtCamera", "dropPlayerAtCameraNoReset", "recover_vehicle", "recover_vehicle_alt", "recover_to_last_road", "goto_checkpoint", "reload_vehicle", "reload_all_vehicles", "loadHome", "saveHome", "toggleAITraffic", "vehicledebugMenu", "reset_physics", "menu_item_select", "reset_all_physics", "editorToggle", "objectEditorToggle", "editorSafeModeToggle", "parts_selector", "vehicleSwitching", "funBoom", "pause", "forceField", "funBreak", "cycleTimeOfDay"}
for i,case in ipairs(data) do 
	M.data = M.data.." "..case
end
-- 
M.config = load_config("settings/S2C")
local prefix = M.config.prefix
M.command = {
	{command = prefix.."on",help = "^3^l!on^r [name] - блокировка некоторых опций бимки ", func = "ON", admin = true,hide = false},
	{command = prefix.."tunoff", help = "^3^l!tunoff^r [name] - разблокировка тюнинга ", func = "TUNOFF", admin = false, hide = false},	
	{command = prefix.."tunon", help = "^3^l!tunon^r [name] - блокировка тюнинга ", func = "TUNON", admin = false, hide = false},	
	{command = prefix.."getveh", help = "^3^l!getveh^r - Получить список транспортных средств игрока", func = "GETVEH", admin = true, hide = false},
	{command = prefix.."gpv", help = "^3^l!gpv^r [id] - получить список машин", func = "GETPLAYERVEHICLES", admin = true, hide = false},
	{command = prefix.."rv", help = "^3^l!rv^r [id] [vehicle_id] - удалить транспорт", func = "REMOVEVEHICLE", admin = true, hide = false},
	{command = prefix.."tickets", help = "^3^l!tickets^r - превышения скорости", func = "ShowPenalties", admin = false, hide = false},	
	{command = prefix.."off",help = "^3^l!off^r [name] - откл блокировка некоторых опций бимки ", func = "OFF", admin = true,hide = false}
	}

function M.load() 
	MP.RegisterEvent("onVehicleSpawn", "onSpawn")
	MP.RegisterEvent("speedTrap", "speedTrap")
    MP.RegisterEvent("redLight", "redLight")
	tun_list = load_database("tunlist.IXT") or {}
	police_list = load_database("economica.ixt") or {}	
	M.command = RegEvent(M.command)
end

function M.unload()
end

return M

--[[function onVehicleEdited(player_id, vehicle_id, data)
	local s = data:find('%{')
	data = data:sub(s)
	data = Util.JsonDecode(data)
	players[player_id].vehicles[vehicle_id] = data.jbm
end
--]]

--function onVehicleReset(player_id, vehicle_id, data)