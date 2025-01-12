--[[
Челы могут сами выбирать работу

1. Из точки в точку
2. По вызову или времени

if random(0,100) and work.police.iswork == true then
	nelegal = true
	if random(0,100)>10 then
		send_team_msg("police","Поступила информация о перевозке нелегального груза"
elseif random(0,100)<10 then
	send_team_msg("police","Поступила информация о перевозке нелегального груза"
С вероятностью 5-10% и если на сервере есть полиция  могут предложить нелегал.
Стоимость груза + 100% (При поимке нелегала) Выдаётся штрав в размере х2 товара

1 доставка = 2000 * 1.3 + бонус за время (300 секунд - время за которое доехал чел)*2 = 2600

-- point to point
Система премий за X подряд работы
каждая:
20 доставка + 10% от суммы заказа


Супер премия (Игроки не могут знать) :
10к доставка + 1млн
77.777 доставка + 77.777.777р

Схема подсчёта премий
(Базавая сумма * 1.10)+Супер премия

Такси
Автобусы
Грузовик

# Из базы в точку (Отвечает деньгами за груз) (Возможен нелегал)
Доставка на pigeon 80к (Со склада в точка(рандом))
Водитель скорой 100к (Больница точка(рандом))
Водитель пожарного (Грузовик 125) 100к (Из Депо в точки ?)
Доставщик Еды 100к (Еда точка(рандом))

# Мини игры или зоны (Ни чего не нужно для работы)
Уборка мусора 75к (очистка опр зоны)
Работник нод автодор 100к (Зоны (или точки в которых мини игры))
Обслуживание ветряков 100к (Мини игры)

# Из нескольких точек в одну точку (Отвечает деньгами за груз) (Возможен нелегал)
	# Точка за точкой пока не набран лимит
		Водитель автобуса 127к (Остановки)
		Водитель мусоровоза 125 (Известно только колл-во точек)(из точек в точку (Бонус за все точки))
	# Получает список точек по которым нужно проехать
		Доставщик на (Scout,H,D 120к) 80к (Со склада точки(рандом))
		Работа на грузовике 125 (Из производств в склады, из складов в склады, из складов в производства)
--]]



--[[

local function extract_json_part(data)
    local json_part = data:match(":%b{}")
    if json_part then
        return json_part:sub(2)
    else
        return nil
    end
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
        randPos = math.random(1, count)
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
            randBal = math.random(150, 800)
            MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы получили "..randBal.."$ за работу"}))
            local new_bal = UserData(MP.GetPlayerName(user_id)).bal + randBal
            editUserData(getIdByNick(MP.GetPlayerName(user_id)),"bal", new_bal)
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
            MP.TriggerClientEvent(user_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы получили ".. data[4] .."$ за работу"}))
        end

    end
    local data = {pos = pos_cord, logic = "jobs", user_id = getIdByNick(MP.GetPlayerName(user_id)), name = pos_name}
    local data_json = json.encode(data)
    MP.TriggerClientEvent(user_id, "PackettrigerPost" ,data_json)
end

-- Евенты

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

function onInit()
    MP.RegisterEvent("TriggerJobs", "TriggerJobsLogic")
    MP.RegisterEvent("onVehicleSpawn", "spawnVeh")
    MP.RegisterEvent("TriggerEventSener", "triggerEvent")
    MP.RegisterEvent("onChatMessage", "CommandInChat");
end


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

        MP.TriggerClientEvent(sender_id, "PacketNotify", json.encode({color="yellow", title="Оповещение", text="Вы закончили работать, работали ".. jobworktime .." минут."}))
        MP.SendChatMessage(sender_id, "Вы закончили работать, работали ".. jobworktime .." минут.")
        return
    end
end

    MP.RegisterEvent("EventJobsButton", "ProfsButton
--]]