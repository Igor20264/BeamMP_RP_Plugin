-- Импорты
local json = require("plugins.json")

-- Переменные
local filePath = "/home/container/Resources/Server/RolePlaySub/db/users.json"
local permissionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/perms.json"
local professionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/profs.json"
local CheckPointsFilePath = "/home/container/Resources/Server/RolePlaySub/db/CheckPoints.json"


JobsActivite = {}
DostavkaActive = {}

-- Функции
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
            local user = p[beammp_id]
            return user
        end
    end
    return
    print("User with ID " .. beammp_id .. " not found.")
end

function editUserData(user_id, table, value)
    local data = readJSON(filePath)
    for _, p in ipairs(data) do
        if p[user_id] then
            p[user_id][table] = value
            writeJSON(filePath, data)
            print("User data updated for user ID: " .. user_id)
            return true
        end
    end
    print("User with ID " .. user_id .. " not found.")
    return false
end



function permissionsCheck(name, required_level)
    local user = UserData(name)
    local userRole = user.perm
    local permissions = readJSON(permissionsFilePath)

    local userLevel = tonumber(permissions[userRole] or permissions["default"])

    return userLevel >= required_level
end

function Connecting_users(player_name, player_role, player_guest, player)

    local data = readJSON(filePath)
    
    local playerExists = false
    for _, p in ipairs(data) do
        if p[player.beammp] then
            playerExists = true
            break
        end
    end

    if not playerExists then
        local transformed = {
            [player.beammp] = {
                profs_id = "0",
                nick = player_name,
                perm = "defoult",
                bal = "0"
            }
        }
        table.insert(data, transformed)

        writeJSON(filePath, data)
        print("New player added: " .. player_name)
        print("User id: " .. player.beammp)
    else
        print("Player already exists: " .. player_name)
    end
end

function getProfs(profs_id)
    local data = readJSON(professionsFilePath)
    local id_str = tostring(profs_id)
    local profs = data[id_str]
    if profs then
        return profs
    else
        print("Get Profs id " .. profs_id .. " not found.")
        return nil
    end
end

local function extract_json_part(data)
    local json_part = data:match(":%b{}")
    if json_part then
        return json_part:sub(2)
    else
        return nil
    end
end

local function parseDate(dateString)
    local pattern = "(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)"
    local year, month, day, hour, min, sec = dateString:match(pattern)
    return { year = year, month = month, day = day, hour = hour, min = min, sec = sec }
end



function getCheckPointDostavka(profs_pos, use_pos, user_id)

    local profsUser = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id)

    local json_content = readJSON(CheckPointsFilePath)
    local points = json_content[profs_pos]
    local count = 0
    for _ in pairs(points) do
        count = count + 1
    end


    if DostavkaActive[user_id] then
        pay_use = true
    else
        DostavkaActive[user_id] = "unload"
        pay_use = false
    end
    if DostavkaActive[user_id] == "load" then
        DostavkaActive[user_id] = "unload"
        randPos = Util.RandomIntRange(1, count)
        data = points[profs_pos..randPos]

        pos_name = profs_pos..randPos
        pos_cord = {x=data[1],y=data[2],z=data[3]}
    
        local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
        local data_json = json.encode(data)
        MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)

        MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Езжяйте на выгрузку"}))

    elseif DostavkaActive[user_id] == "unload" then
        DostavkaActive[user_id] = "load"
        pos_cord = profs.dostavkapos
        pos_name = "pohta"

        local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
        local data_json = json.encode(data)
        MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)

        if pay_use == true then
            randBal = Util.RandomIntRange(150, 800)
            MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы получили "..randBal.."$ за работу"}))
            local new_bal = UserData(MP.GetPlayerName(user_id)).bal + randBal
            editUserData(getIdByNick(MP.GetPlayerName(user_id)),"bal", new_bal)
            BalanceUpdate(user_id, "")
        end
        

        MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Езжяйте на погрузку"}))
    end

end

function getCheckPointMarshrute(profs_pos, use_pos, user_id)
    local json_content = readJSON(CheckPointsFilePath)
    local points = json_content[profs_pos]
    
    local pos_cord
    local pos_name

    profsUser = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id)
    if use_pos == profsUser.spawnposname then
        data = points[profs_pos.."1"]
        pos_name = profs_pos.."1"
        pos_cord = {x=data[1],y=data[2],z=data[3]}
        MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Начинайте работать"}))
    else
        local strNumber = string.gsub(use_pos, profs_pos,"")
        local Number = tostring(tonumber(strNumber)+1)
        data = points[profs_pos .. Number]
        if data == nil then
            data = points[profs_pos.."1"]
            pos_name = profs_pos.."1"
            pos_cord = {x=data[1],y=data[2],z=data[3]}
        else
            data = points[profs_pos..Number]
            pos_name = profs_pos..Number
            pos_cord = {x=data[1],y=data[2],z=data[3]}
        end


        if data[4] ~= 0 then
            local new_bal = UserData(MP.GetPlayerName(user_id)).bal + data[4]
            editUserData(getIdByNick(MP.GetPlayerName(user_id)),"bal", new_bal)
            BalanceUpdate(user_id, "")
            MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы получили ".. data[4] .."$ за работу"}))
        end
        
    end


    local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
    local data_json = json.encode(data)
    MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)
    
    
end




-- Команды

function CommandInChat(sender_id, sender_name, message)
	if string.find(string.sub(message, 1, 2), "/") ~= nil then
		if message == "/help" then
			MP.SendChatMessage(sender_id, "Команды: ");
            MP.SendChatMessage(sender_id, "/info - Показывает вашу статистику");
            MP.SendChatMessage(sender_id, "/pay <Ник> <Сумма> - Перевести деньги игроку");
        elseif message =="/info" then
            info(sender_id, sender_name, message)

        elseif string.sub(message, 1, 4) == "/pay" then
            pay(sender_id, sender_name, message)
            
        elseif string.sub(message, 1, 8) == "/profset" then
            profset(sender_id, sender_name, message)
        
        elseif message =="/test" then
            test(sender_id, sender_name, message)
        
            
        else
            MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Команда \"" .. message .. "\" не распознана."}))
			MP.SendChatMessage(sender_id, "Команда \"" .. message .. "\" не распознана.");
        end
    end
end



function test(sender_id, sender_name, message)
    MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="green", title="Оповещение", text="Тестовое оповещение."}))
    print(DostavkaActive)
    print(JobsActivite)
end


function profset(sender_id, sender_name, message)
    if permissionsCheck(sender_name, 5) then
        command, player, profid = string.match(message, "/(%w+)%s+(%w+)%s+(%d+)")
        editUserData(getIdByNick(player),"profs_id", profid)
        MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="green", title="Успешно", text="Вы успешно изменили профессию для ".. player}))
    else
        MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Команда /profset не распознана."}))
        MP.SendChatMessage(sender_id, "Команда /profset не распознана.");
    end
    
end

function balanceEdit(nick, value)
    new_bal = UserData(nick).bal + value
    print(UserData(nick).bal)
    print(new_bal)
    editUserData(getIdByNick(nick),"bal", new_bal)
    MP.TriggerGlobalEvent("PacketBalanceUpdateAll", "")
end

function pay(sender_id, sender_name, message)
    local command, player, amount = string.match(message, "/(%w+)%s+(%w+)%s+(%d+)")
    print(player)
    print(amount)
    if player then
        if amount then
            if player == sender_name then
                MP.SendChatMessage(sender_id, "Вы не можете перевести деньги самому себе");
            else
                balanceEdit(sender_name, -amount)
                balanceEdit(player, amount)
                MP.SendChatMessage(sender_id, "Вы перевели "..player.." сумму в размере " .. amount .."$");
            end
        else
            MP.SendChatMessage(sender_id, "/pay <Ник> <Сумма> - Перевести деньги игроку");
        end
    else
        MP.SendChatMessage(sender_id, "/pay <Ник> <Сумма> - Перевести деньги игроку");
    end

end

function info(sender_id, sender_name, message)
    local profs = getProfs(UserData(sender_name).profs_id)
    MP.SendChatMessage(sender_id, "---------------------------");
    MP.SendChatMessage(sender_id, "Ваша статистика: ");
    MP.SendChatMessage(sender_id, "Наличных: ".. UserData(sender_name).bal);
    MP.SendChatMessage(sender_id, "Профессия: ".. profs.name);
    MP.SendChatMessage(sender_id, "Зарплата: ".. profs.payday);
    if permissionsCheck(sender_name, 2) then
        MP.SendChatMessage(sender_id, "Админ права: ".. UserData(sender_name).perm);
    end
    MP.SendChatMessage(sender_id, "---------------------------");
end

-- Евенты

function BalanceUpdate(sender_id, data)
    local userbal = tostring(UserData(MP.GetPlayerName(sender_id)).bal)
    MP.TriggerClientEvent(sender_id, "PacketbalanceUpdate", userbal);
    
end

function ProfsUpdate(sender_id, data)
    local profsname = tostring(getProfs(UserData(MP.GetPlayerName(sender_id)).profs_id).name)
    MP.TriggerClientEvent(sender_id, "PacketProfsUpdate", profsname);

    if JobsActivite[sender_id] == nil then
        MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Начать работу")
        return
    end

    if JobsActivite[sender_id] == "spawncar" then
        MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Возьмите машину")
        return
    end

    if JobsActivite[sender_id] then
        MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"В работе")
        return
    end
end

function ProfsButton(sender_id, data)
    if JobsActivite[sender_id] == nil then
        if getProfs(UserData(MP.GetPlayerName(sender_id)).profs_id).caruse == true then

            JobsActivite[sender_id] = "spawncar"
            MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Возьмите рабочую машину"}))
            MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Возьмите машину")

            local profs = getProfs(UserData(MP.GetPlayerName(sender_id)).profs_id)
            local data = {pos = profs.spawnpos, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(sender_id)), name = profs.spawnposname}
            local data_json = json.encode(data)
            MP.TriggerClientEvent(sender_id, "PackettrigerPost" ,data_json)
            

            return
        end
        
        
        JobsActivite[sender_id] = os.date("%Y-%m-%d %H:%M:%S", os.time())
        MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"В работе")


        profs = getProfs(UserData(MP.GetPlayerName(sender_id)).profs_id)

        if profs.joblogic == "marshrute" then
            getCheckPointMarshrute(profs.checkpointname, profs.spawnposname, sender_id)
        elseif profs.joblogic == "dostavka" then
            DostavkaActive[sender_id] = nil
            getCheckPointDostavka(profs.checkpointname, profs.spawnposname, sender_id)
        elseif profs.joblogic == "none" then
            MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="У вас нету работы."}))
            return
        end


        MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы начали работать"}))
        return
    end

    if JobsActivite[sender_id] == "spawncar" then
        MP.TriggerClientEvent(sender_id, "PacketDeleteCheckpoint", "")
        MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Начать работу")
        JobsActivite[sender_id] = nil
        print("2")
        return
    end

    if JobsActivite[sender_id] then
        if DostavkaActive[sender_id] ~= nil then
            DostavkaActive[sender_id] = nil
        end
        
        MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Начать работу")

        profs = getProfs(UserData(MP.GetPlayerName(sender_id)).profs_id)
        if profs.joblogic ~= "none" then
            MP.TriggerClientEvent(sender_id, "PacketDeleteCheckpoint" ,"")
        end
        
        
        local date1 = parseDate(os.date("%Y-%m-%d %H:%M:%S", os.time()))
        local date2 = parseDate(JobsActivite[sender_id])
        local times1 = os.time(date1)
        local times2 = os.time(date2)
        local jobworktime = math.floor(os.difftime(times1, times2) / 60)

        JobsActivite[sender_id] = nil

        local new_bal = UserData(MP.GetPlayerName(sender_id)).bal + getProfs(UserData(MP.GetPlayerName(sender_id)).profs_id).payday * jobworktime
        editUserData(getIdByNick(MP.GetPlayerName(sender_id)),"bal", new_bal)

        BalanceUpdate(sender_id, "")
        MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы закончили работать, работали ".. jobworktime .." минут."}))
        MP.SendChatMessage(sender_id, "Вы закончили работать, работали ".. jobworktime .." минут.")
        return
    end
end


function triggerEvent(user_id, data_json)
    local data = json.decode(data_json)
    local car_id, beam_id, type, name = string.match(data.triggerName, "(%d+)_(%d+)_(%w+)_(%w+)")
    if tonumber(car_id) == tonumber(data.vehId) then
        local user_beam_id = getIdByNick(MP.GetPlayerName(user_id))
        if tonumber(user_beam_id) == tonumber(beam_id) then
            MP.TriggerClientEvent(user_id, "PacketDeleteCheckpoint", "")
            profs = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id)
            if type == "jobs" then
                if JobsActivite[user_id] == "spawncar" then
                    local data = getProfs(UserData(MP.GetPlayerName(user_id)).profs_id).car
                    local data_json = json.encode(data)
                    MP.TriggerClientEvent(user_id, "CarReplacePacket", data_json)
                    JobsActivite[user_id] = os.date("%Y-%m-%d %H:%M:%S", os.time())
                    MP.TriggerClientEvent(user_id, "PacketProfsButtonUpdate" ,"В работе")
                end

                local checkpointname = profs.checkpointname
                local joblogic = profs.joblogic

                if joblogic == "marshrute" then
                    getCheckPointMarshrute(checkpointname, name, user_id)
                elseif joblogic == "dostavka" then
                    getCheckPointDostavka(checkpointname, name, user_id)
                elseif joblogic == "none" then
                    MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Начинайте работать."}))
                end
            end
        end    
    end
end


function spawnVeh(player_id, vehicle_id, data)
    local json_data = extract_json_part(data)
    if json_data then
        local parsed_data, pos, err = json.decode(json_data, 1, nil)
        vid = parsed_data.vid
    end
end

function SpawnSnowMan(user_id)
    JobsActivite[user_id] = nil
    print("1")
    local cord_spawn = {
        x=0,
        y=0,
        z=0
    }
    --local cord_spawn = {
    --    x=-570.193,
    --    y=-550.296,
    --    z=-11.392
    --}
    local cord_spawn_json = json.encode(cord_spawn)
    MP.TriggerClientEvent(user_id, "SendonJoinServer", cord_spawn_json);

    MP.SendChatMessage(user_id, "Добро пожаловать на Subter Role Play");
    MP.SendChatMessage(user_id, "Если вы зашли впервые, то введите команду /help");
end

-- Импорты
local json = require("plugins.json")



-- Переменные
local filePath = "/home/container/Resources/Server/RolePlaySub/db/users.json"
local permissionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/perms.json"
local professionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/jobs.json"
local configFilePath = "/home/container/Resources/Server/RolePlaySub/config.json"


-- Функции
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

function getUserProfession(nick)
    local user = UserData(nick)
    if not user then
        return nil
    end

    local professions = readJSON(professionsFilePath)
    local professionId = user.profs_id

    return professions[professionId]
end

function permissionsCheck(name, required_level)
    local user = UserData(name)
    local userRole = user.perm
    local permissions = readJSON(permissionsFilePath)

    local userLevel = tonumber(permissions[userRole] or permissions["default"])
    print(userLevel)


    return userLevel >= required_level
end

function calculateDistance(posU1, posU2)
    local dx = posU1[1] - posU2[1]
    local dy = posU1[2] - posU2[2]
    local dz = posU1[3] - posU2[3]
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Connecting_users(player_name, player_role, player_guest, player)

    local data = readJSON(filePath)

    local playerExists = false
    for _, p in ipairs(data) do
        if p[player.beammp] then
            playerExists = true
            break
        end
    end

    if not playerExists then
        local transformed = {
            [player.beammp] = {
                profs_id = "0",
                nick = player_name,
                perm = "defoult",
                bal = "0"
            }
        }
        table.insert(data, transformed)

        writeJSON(filePath, data)
        print("New player added: " .. player_name)
        print("User id: " .. player.beammp)
    else
        print("Player already exists: " .. player_name)
    end
end

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
            local user = p[beammp_id]
            return user
        end
    end
    print("User with ID " .. beammp_id .. " not found.")
end

function updateUser(beammp_id,table, new_value)
    local data = readJSON(filePath)

    for _, p in ipairs(data) do
        if p[beammp_id] then
            p[beammp_id][table] = tostring(new_value)
            writeJSON(filePath, data)
            print("User ".. table .." updated for ID: " .. beammp_id)
            return
        end
    end
    print("User with ID " .. beammp_id .. " not found.")
end

function transferBalance(from_id, to_id, amount)
    local data = readJSON(filePath)
    local fromUser, toUser = nil, nil

    for _, p in ipairs(data) do
        if p[from_id] then
            fromUser = p[from_id]
        end
        if p[to_id] then
            toUser = p[to_id]
        end
        if fromUser and toUser then
            break
        end
    end

    if not fromUser then
        local noneuser = "Пользователь не найден."
        print("User with ID " .. from_id .. " not found.")
        return noneuser
    end

    if not toUser then
        local noneuser = "Пользователь не найден."
        print("User with ID " .. to_id .. " not found.")
        return noneuser
    end

    local fromBalance = tonumber(fromUser.bal)
    local toBalance = tonumber(toUser.bal)

    if fromBalance < amount then
        local nonebalance = "Недостаточно денег на балансе."

        return nonebalance
    end

    fromUser.bal = tostring(fromBalance - amount)
    toUser.bal = tostring(toBalance + amount)

    writeJSON(filePath, data)
    print("Transferred " .. amount .. " from user " .. UserData(from_id).nick .. " to user " .. UserData(to_id).nick)
    local status = "Вы успешно перевели деньги."
    return status
end

local PeremennyeDljaOtladki = {
	["sd"] = false,
	["ms"] = false,
	["ss"] = false,
	["r1"] = false,
	["r2"] = false,
	["kf"] = false,
	["md"] = false,
	["kfch"] = false
}

function setMarker(user_id, cord)
    local datacord = cord
    MP.TriggerClientEvent(user_id, "setMarkerClient", datacord);

end

function CommandInChat(sender_id, sender_name, message)

	if string.find(string.sub(message, 1, 2), "/") ~= nil then
		if message == "/help" then
			MP.SendChatMessage(sender_id, "Команды: /pay <Ник> <Сумма> - Перевод денег   /profs - Узнать информацию о профессии");
        elseif string.sub(message, 1, 4) == "/pay" then
            local pattern = "^/pay%s+(%S+)%s+(%d+)"
            local user_name, amount_str = string.match(message, pattern)
            if user_name == sender_name then
                MP.SendChatMessage(sender_id, "Вы не можете переводить деньги самому себе.")
           	else
                if user_name and amount_str then
                    local amount = tonumber(amount_str)
                    if amount and amount > 0 then
                        local to_id = getIdByNick(user_name)
                        local sender_user_id = getIdByNick(sender_name)
                        if to_id then
                            local status = transferBalance(sender_user_id, to_id, amount)
                            print(sender_id)
                            MP.SendChatMessage(sender_id, status)
                        else
                            MP.SendChatMessage(sender_id, "Пользователь с ником " .. user_name .. " не найден.")
                        end
                    else
                        MP.SendChatMessage(sender_id, "Некорректная сумма.")
                    end
                else
                    MP.SendChatMessage(sender_id, "Использование: /pay <Ник> <Сумма>")
                end
            end
        elseif message == "/setjob" then
            if permissionsCheck(sender_name, 1) then

                MP.SendChatMessage(sender_id, "Доступ")
            else
                MP.SendChatMessage(sender_id, "У вас недостаточно прав для использования этой команды.")
            end
        elseif message == "/profs" then
            local profession = getUserProfession(sender_name)
            if profession then
                local professionInfo = "Ваша профессия: " .. profession.name .. ". Выплата: " .. profession.payday
                MP.SendChatMessage(sender_id, professionInfo)
            else
                MP.SendChatMessage(sender_id, "Информация о вашей профессии не найдена.")
            end
        elseif message =="/test" then
            local cord_spawn = json.encode{x=1,y=2,z=3}
    		MP.TriggerClientEvent(0, "SendonJoinServer", cord_spawn);
        else
            local KomandaNeRaspoznana = true;
			local messageBezSlesha = string.sub(message, 2, string.len(message));
			for Peremennaja, Znachenie in pairs(PeremennyeDljaOtladki) do
				if messageBezSlesha == Peremennaja then
					PeremennyeDljaOtladki[Peremennaja] = not Znachenie;
					KomandaNeRaspoznana = false;
				end;
			end;
			if KomandaNeRaspoznana then
				MP.SendChatMessage(IdIgroka, "Команда \"" .. message .. "\" не распознана.");
			end;
        end
    end
end

-- Вспомогательные функции

function ObjektVJSON(Objekt)
	local Stroka = jsonEncode(Objekt);
	-- Двоеточие ":" нельзя передавать между клиентом и сервером.
	local StrokaSZamenoj = string.gsub(Stroka, ":", "=Dvoetochie=");
	return StrokaSZamenoj;
end;

function JSONVObjekt(Stroka)
	-- Двоеточие ":" нельзя передавать между клиентом и сервером.
	local StrokaSZamenoj = string.gsub(Stroka, "=Dvoetochie=", ":");
	local Objekt = jsonDecode(StrokaSZamenoj);
	return Objekt;
end;

function handleConsoleInput(cmd)
    local delim = cmd:find(' ')
    if delim then
        local nick = cmd:sub(delim+1)
        if cmd:sub(1, delim-1) == "test" then
            test(0)
            return nick
        end
    end
end

function otvet(data)
    print("Отработало ".. data)
end

function onInit()
    MP.RegisterEvent("onChatMessage", "CommandInChat");
    MP.RegisterEvent("TriggerJobs", "TriggerJobsLogic")
    MP.RegisterEvent("onVehicleSpawn", "spawnVeh")
    MP.RegisterEvent("onPlayerJoin", "SpawnSnowMan")
    MP.RegisterEvent("onPlayerAuth", "Connecting_users")
    MP.RegisterEvent("EventBalanceUpdate", "BalanceUpdate")
    MP.RegisterEvent("onChatMessage", "CommandInChat");
    MP.RegisterEvent("TriggerEventSener", "triggerEvent")
    MP.RegisterEvent("EventJobsUpdate", "ProfsUpdate")
    MP.RegisterEvent("EventJobsButton", "ProfsButton")
    MP.RegisterEvent("onVehicleSpawn", "spawnVeh")
    MP.RegisterEvent("onPlayerAuth", "Connecting_users")
    MP.RegisterEvent("onConsoleInput", "handleConsoleInput")
    MP.RegisterEvent("onChatMessage", "CommandInChat");
    MP.RegisterEvent("onPlayerAuth", "Connecting_users")
end



print("----------------------")
print("System Started!!!")
print("----------------------")

-- Таблица данных
local data = {
    bus = {
        bus1 = {10, 50, 0, 0},
        bus2 = {50, 50, 0, 0},
        bus3 = {50, 10, 0, 0},
        bus4 = {10, 10, 0, 100}
    },
    bus2 = {
        bus21 = {10, 50, 0, 0},
        bus22 = {50, 50, 0, 0},
        bus23 = {50, 10, 0, 0},
        bus24 = {10, 10, 0, 100}
    }
}

function containsValue(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Пример использования функции с MP.GetPlayers()
local players = MP.GetPlayers()
local valueToFind = "Jastickon"
local isPresent = containsValue(players, valueToFind)

if isPresent then
    print(valueToFind .. " найден в таблице игроков.")
else
    print(valueToFind .. " не найден в таблице игроков.")
end

function findPos(busName)


    for category, poses in pairs(data) do
        if poses[busName] then
            local Data = poses[busName]
            return {
                name = busName,
                pos = {Data[1], Data[2], Data[3]},
                pay_day = Data[4]
            }
        end
    end
    return nil
end

local function getNextPos(Name)
    local prefix, number = Name:match("^(%a+)(%d+)$")
    if not prefix or not number then
        return nil
    end
    local nextNumber = tonumber(number) + 1
    local nextBusName = prefix .. nextNumber
    return nextBusName
end

local function getEndPos(busName)
    local prefix, number = busName:match("^(%a+)(%d+)$")
    if not prefix or not number then
        return nil
    end
    local nextNumber = 1
    local nextBusName = prefix .. nextNumber
    return nextBusName
end

function CheckPointInfo(name)
    local PosInfo = findPos(name)
    if PosInfo then
        trigger = string.format("name = \"%s\", pos = {%d, %d, %d}, pay_day = %d", PosInfo.name, PosInfo.pos[1], PosInfo.pos[2], PosInfo.pos[3], PosInfo.pay_day)
    end
    newPosName = getNextPos(name)
    newPos = findPos(newPosName)
    if newPos then
        print("")
    else
        newPosName = getEndPos(name)
        newPos = findPos(newPosName)
    end
    new_trigger = string.format("name = \"%s\", pos = {%d, %d, %d}, pay_day = %d", newPos.name, newPos.pos[1], newPos.pos[2], newPos.pos[3], newPos.pay_day)
    data = {
        [0] = trigger,
        [1] = new_trigger
    }
    return data
end
print(CheckPointInfo("bus1")[0])

function splitString(inputString)
    local underscorePosition = string.find(inputString, "_")
    if underscorePosition then
        local part1 = string.sub(inputString, 1, underscorePosition - 1)
        local part2 = string.sub(inputString, underscorePosition + 1)
        return part1, part2
    else
        return inputString, ""
    end
end

function TriggerJobsLogic(user_id, data_json)
    local data = json.decode(data_json)

    local veh_id, posCheckName = splitString(data.triggerName)

    if veh_id == data.vehId then
        print("Вы владелец тригера")
    else
        print("Вы невладелец тригера")
    end


    local data_json = json.encode(data)
    MP.TriggerClientEvent(user_id,"PackettrigerJobsPost", data_json)
end

-- Таблица для хранения состояния игроков
playerStates = {}

-- Функция для добавления или обновления состояния игрока
function setPlayerState(player_id, state)
    playerStates[player_id] = state
end

-- Функция для получения состояния игрока
function getPlayerState(player_id)
    return playerStates[player_id]
end

-- Функция для удаления состояния игрока
function removePlayerState(player_id)
    playerStates[player_id] = nil
end

-- Функция для вывода состояния всех игроков (для отладки)
function printPlayerStates()
    for player_id, state in pairs(playerStates) do
        print("Player ID: " .. player_id)
        for key, value in pairs(state) do
            print(key .. ": " .. tostring(value))
        end
        print("------")
    end
end

-- Пример использования
setPlayerState(1, {health = 100, position = {x = 10, y = 20}, status = "alive"})
setPlayerState(2, {health = 90, position = {x = 30, y = 40}, status = "injured"})

print("Состояние игрока 1:")
local player1State = getPlayerState(1)
for key, value in pairs(player1State) do
    print(key .. ": " .. tostring(value))
end

print("------")

print("Все состояния игроков:")
printPlayerStates()

-- Удаление состояния игрока
removePlayerState(1)

print("Состояние после удаления игрока 1:")
printPlayerStates()

-- Импорты
local json = require("plugins.json")

-- Переменные
local filePath = "/home/container/Resources/Server/RolePlaySub/db/users.json"
local permissionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/perms.json"
local professionsFilePath = "/home/container/Resources/Server/RolePlaySub/db/jobs.json"
local CheckPointsFilePath = "/home/container/Resources/Server/RolePlaySub/db/CheckPoints.json"


local playerStates = {}

local user_carId



-- Функции временных данных

-- Функция для добавления или обновления состояния игрока
function setPlayerState(player_id, state)
    playerStates[player_id] = state
end

-- Функция для получения состояния игрока
function getPlayerState(player_id)
    return playerStates[player_id]
end

-- Функция для удаления состояния игрока
function removePlayerState(player_id)
    playerStates[player_id] = nil
end

-- Функции
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

function SetGPSPosition(user_id, pos)
    local data = json.encode{x=95.737,y=-298,z=133}
    MP.TriggerClientEvent(user_id, 'packetgpsset', data)
end

function UserData(nick)
    local beammp_id = getIdByNick(nick)
    local data = readJSON(filePath)

    for _, p in ipairs(data) do
        if p[beammp_id] then
            local user = p[beammp_id]
            return user
        end
    end
    print("User with ID " .. beammp_id .. " not found.")
end



function permissionsCheck(name, required_level)
    local user = UserData(name)
    local userRole = user.perm
    local permissions = readJSON(permissionsFilePath)

    local userLevel = tonumber(permissions[userRole] or permissions["default"])
    print(userLevel)


    return userLevel >= required_level
end

function Connecting_users(player_name, player_role, player_guest, player)

    local data = readJSON(filePath)

    local playerExists = false
    for _, p in ipairs(data) do
        if p[player.beammp] then
            playerExists = true
            break
        end
    end

    if not playerExists then
        local transformed = {
            [player.beammp] = {
                profs_id = "0",
                nick = player_name,
                perm = "defoult",
                bal = "0",
                bank_bal = "0"
            }
        }
        table.insert(data, transformed)

        writeJSON(filePath, data)
        print("New player added: " .. player_name)
        print("User id: " .. player.beammp)
    else
        print("Player already exists: " .. player_name)
    end
end

function CommandInChat(sender_id, sender_name, message)

	if string.find(string.sub(message, 1, 2), "/") ~= nil then
		if message == "/help" then
			MP.SendChatMessage(sender_id, "Команды: ");

        elseif message =="/test" then
            local data = json.encode{10,50,0}
            MP.TriggerClientEvent(-1, 'packetgpsset', data)


        elseif message =="/test2" then
            setCheckPoint(sender_id)

        elseif message == "/adminmode on" then
            if permissionsCheck(sender_name, 5) then
                MP.SendChatMessage(sender_id, "Админ мод включен");
                local data = false
                local data_json = json.encode(data)
                MP.TriggerClientEvent(sender_id, 'packetadminmode', data_json)
            else
                MP.SendChatMessage(sender_id, "Недостаточно прав.");
            end

        elseif message == "/adminmode off" then
            if permissionsCheck(sender_name, 5) then
                MP.SendChatMessage(sender_id, "Админ мод выключен");
                local data = true
                local data_json = json.encode(data)
                MP.TriggerClientEvent(sender_id, 'packetadminmode', data_json)
            else
                MP.SendChatMessage(sender_id, "Недостаточно прав.");
            end

        elseif string.sub(message, 1, 7) == "/freeze" then
            if permissionsCheck(sender_name, 5) then
                local pattern = "^/freeze%s+(%S+)"
                local userid = tonumber(string.match(message, pattern))
                MP.SendChatMessage(sender_id, "Вы зафризили ".. userid);
                MP.TriggerClientEvent(userid, 'freezeVehicle', true)
            else
                MP.SendChatMessage(sender_id, "Недостаточно прав.");
            end

        elseif string.sub(message, 1, 9) == "/unfreeze" then
            if permissionsCheck(sender_name, 5) then
                local pattern = "^/freeze%s+(%S+)"
                local userid = tonumber(string.match(message, pattern))
                MP.SendChatMessage(sender_id, "Вы зафризили ".. userid);
                MP.TriggerClientEvent(userid, 'freezeVehicle', false)
            else
                MP.SendChatMessage(sender_id, "Недостаточно прав.");
            end

        else
			MP.SendChatMessage(sender_id, "Команда \"" .. message .. "\" не распознана.");
        end
    end
end



function setCheckPoint(user_id, checkpoint)

    local data = {name = "test", pos = {10,50,0}, user_id = user_id}
    local data_json = json.encode(data)
    MP.TriggerClientEvent(user_id,"PackettrigerJobsPost", data_json)
end

function TriggerJobsLogic(user_id, data_json)
    local data = json.decode(data_json)
    local veh_id, pos_name, user_id_pos = data.triggerName:match("(%d+)_(%a+)_(%d+)")

    print(user_id .." приехал на триггер ".. data.triggerName)
    MP.SendChatMessage(user_id, "Вы проехали триггер "..  data.triggerName);
    if tonumber(user_id_pos) == tonumber(user_id) then
        if tonumber(veh_id) == tonumber(data.vehId) then
            print("Машина та же")
            print(pos_name)
            MP.TriggerClientEvent(user_id,"PacketDeleteCheckpoint", "")



        else
            print("Другая машина")
        end
    else
        print("Вы невладелец тригера")
    end
end


local function extract_json_part(data)
    local json_part = data:match(":%b{}")
    if json_part then
        return json_part:sub(2)
    else
        return nil
    end
end

function spawnVeh(player_id, vehicle_id, data)
    local json_data = extract_json_part(data)
    if json_data then
        local parsed_data, pos, err = json.decode(json_data, 1, nil)
        vid = parsed_data.vid
    end
end