-- Импорты
local json = require("plugins.json")

-- Переменные
local filePath = "/home/container/Resources/Server/RolePlaySub/db/users.json"
local permissionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/perms.json"
local professionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/jobs.json"
local CheckPointsFilePath = "/home/container/Resources/Server/RolePlaySub/db/CheckPoints.json"

local playerStates = {}
local user_carId

-- Функции для работы с JSON
local function readJSON(filePath)
    local file = io.open(filePath, "r")
    if not file then return {} end
    local content = file:read("*a")
    file:close()
    return json.decode(content)
end

local function writeJSON(filePath, data)
    local file = io.open(filePath, "w")
    file:write(json.encode(data))
    file:close()
end

-- Функции для работы с игроками
function getIdByNick(nick)
    local data = readJSON(filePath)
    for _, p in ipairs(data) do
        for id, user in pairs(p) do
            if user.nick == nick then
                return id
            end
        end
    end
    return nil
end

function UserData(nick)
    local beammp_id = getIdByNick(nick)
    local data = readJSON(filePath)
    for _, p in ipairs(data) do
        if p[beammp_id] then
            return p[beammp_id]
        end
    end
    print("User with ID " .. beammp_id .. " not found.")
end

function updateUser(beammp_id, table, new_value)
    local data = readJSON(filePath)
    for _, p in ipairs(data) do
        if p[beammp_id] then
            p[beammp_id][table] = tostring(new_value)
            writeJSON(filePath, data)
            print("User " .. table .. " updated for ID: " .. beammp_id)
            return
        end
    end
    print("User with ID " .. beammp_id .. " not found.")
end

function transferBalance(from_id, to_id, amount)
    local data = readJSON(filePath)
    local fromUser, toUser = nil, nil

    for _, p in ipairs(data) do
        if p[from_id] then fromUser = p[from_id] end
        if p[to_id] then toUser = p[to_id] end
        if fromUser and toUser then break end
    end

    if not fromUser then
        print("User with ID " .. from_id .. " not found.")
        return "Пользователь не найден."
    end
    if not toUser then
        print("User with ID " .. to_id .. " not found.")
        return "Пользователь не найден."
    end

    local fromBalance = tonumber(fromUser.bal)
    local toBalance = tonumber(toUser.bal)

    if fromBalance < amount then
        return "Недостаточно денег на балансе."
    end

    fromUser.bal = tostring(fromBalance - amount)
    toUser.bal = tostring(toBalance + amount)

    writeJSON(filePath, data)
    print("Transferred " .. amount .. " from user " .. UserData(from_id).nick .. " to user " .. UserData(to_id).nick)
    return "Вы успешно перевели деньги."
end

-- Функции для работы с состояниями игроков
function setPlayerState(player_id, state)
    playerStates[player_id] = state
end

function getPlayerState(player_id)
    return playerStates[player_id]
end

function removePlayerState(player_id)
    playerStates[player_id] = nil
end

-- Функции для работы с профессиями
function getUserProfession(nick)
    local user = UserData(nick)
    if not user then return nil end

    local professions = readJSON(professionsFilePath)
    return professions[user.profs_id]
end

-- Функции для работы с триггерами
function setCheckPoint(user_id, checkpoint)
    local data = {name = "test", pos = {10, 50, 0}, user_id = user_id}
    local data_json = json.encode(data)
    MP.TriggerClientEvent(user_id, "PackettrigerJobsPost", data_json)
end

function TriggerJobsLogic(user_id, data_json)
    local data = json.decode(data_json)
    local veh_id, pos_name, user_id_pos = data.triggerName:match("(%d+)_(%a+)_(%d+)")

    print(user_id .. " приехал на триггер " .. data.triggerName)
    MP.SendChatMessage(user_id, "Вы проехали триггер " .. data.triggerName)
    if tonumber(user_id_pos) == tonumber(user_id) then
        if tonumber(veh_id) == tonumber(data.vehId) then
            print("Машина та же")
            print(pos_name)
            MP.TriggerClientEvent(user_id, "PacketDeleteCheckpoint", "")
        else
            print("Другая машина")
        end
    else
        print("Вы невладелец тригера")
    end
end

-- Функции для работы с консолью
function CommandInChat(sender_id, sender_name, message)
    if string.find(message, "^/") then
        local command, arg1, arg2 = string.match(message, "^/(%w+)%s*(%S*)%s*(%S*)")
        if command == "help" then
            MP.SendChatMessage(sender_id, "Команды: /pay <Ник> <Сумма> - Перевод денег   /profs - Узнать информацию о профессии")
        elseif command == "test" then
            local data = json.encode{10, 50, 0}
            MP.TriggerClientEvent(-1, 'packetgpsset', data)
        elseif command == "test2" then
            setCheckPoint(sender_id)
        elseif command == "adminmode" then
            if permissionsCheck(sender_name, 5) then
                local mode = arg1 == "on" and false or true
                MP.SendChatMessage(sender_id, "Админ мод " .. (mode and "выключен" or "включен"))
                MP.TriggerClientEvent(sender_id, 'packetadminmode', json.encode(mode))
            else
                MP.SendChatMessage(sender_id, "Недостаточно прав.")
            end
        elseif command == "freeze" or command == "unfreeze" then
            if permissionsCheck(sender_name, 5) then
                local userid = tonumber(arg1)
                local freeze = command == "freeze"
                MP.SendChatMessage(sender_id, "Вы " .. (freeze and "зафризили" or "разфризили") .. " " .. userid)
                MP.TriggerClientEvent(userid, 'freezeVehicle', freeze)
            else
                MP.SendChatMessage(sender_id, "Недостаточно прав.")
            end
        else
            MP.SendChatMessage(sender_id, "Команда \"" .. message .. "\" не распознана.")
        end
    end
end

-- Функции для работы с игроками
function Connecting_users(player_name, player_role, player_guest, player)
    local data = readJSON(filePath)
    if not data[player.beammp] then
        data[player.beammp] = {
            profs_id = "0",
            nick = player_name,
            perm = "defoult",
            bal = "0",
            bank_bal = "0"
        }
        writeJSON(filePath, data)
        print("New player added: " .. player_name)
        print("User id: " .. player.beammp)
    else
        print("Player already exists: " .. player_name)
    end
end

function SpawnSnowMan(user_id)
    local cord_spawn = {x = 10, y = 20, z = 3}
    local cord_spawn_json = json.encode(cord_spawn)
    MP.TriggerClientEvent(user_id, "SendonJoinServer", cord_spawn_json)
end

-- Инициализация
function onInit()
    MP.RegisterEvent("onChatMessage", "CommandInChat")
    MP.RegisterEvent("TriggerJobs", "TriggerJobsLogic")
    MP.RegisterEvent("onVehicleSpawn", "spawnVeh")
    MP.RegisterEvent("onPlayerJoin", "SpawnSnowMan")
    MP.RegisterEvent("onPlayerAuth", "Connecting_users")

    print("----------------------")
    print("RolePlaySub | System Started")
    print("----------------------")
end

onInit()