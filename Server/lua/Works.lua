local M = {}
local DB = require "lib.database"

M.info = "Система работ"
M.ver = "1.2"
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

local function getonlineplayers()
	return MP.GetPlayerCount()
end

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


local Working = {}
function Working:init()
    local privat = {}  --приватное свойство
        privat.working = {}
		privat.neworking = {}
		privat.workcars = load_database("work_cars.ixt") or {}
    local obj= {} --публичное свойство
		obj.workcars = privat.workcars

    function obj:all()
        return privat.working
    end

	function obj:neall()
		return privat.neworking
	end

    function obj:start(name,sender_id)
		MP.TriggerClientEvent(sender_id, "PacketNotify", Util.JsonEncode({color="yellow", title="Оповещение", text="Возьмите рабочую машину"}))
		MP.TriggerClientEvent(sender_id, "PacketProfsUpdate", eco.database[name]["work"]["name"]);
		MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Закончить работу")
		if eco.database[name]["work"]["money"] ~= 0 then
			privat.working[name] = timer:get()
			eco.database[name]["work"]["is_working"] = true
			local work = eco.database[name]["work"]["name"]
			--SpawnWorkCar(name, work)
			block_ignore[name] = true
			return eco.database[name]["work"]["name"], eco.database[name]["work"]["money"], false
		else
			local type_work = eco.database[name]["work"]["type"] or true
			local dist,uuid = gps:set_random_path(name,type_work)
			privat.neworking[name] = {lens=0,dist=dist,uuid=uuid,alltimemoney=0,last_uuid="RANDOM",last_work_time = os.time()}
			if eco.database[name]["work"]["metr"] == nil then
				eco.database[name]["work"]["metr"] = config.P4M
			end
			return eco.database[name]["work"]["name"],eco.database[name]["work"]["metr"],true
		end

		--local data = {pos = profs.spawnpos, logic = "jobs", user_id = MP.GetId(name), name = eco.database[name]["work"]["name"]}
		--local data_json = json.encode(data)
		--MP.TriggerClientEvent(sender_id, "PackettrigerPost" ,data_json)
    end

	function obj:get_next_point(name,uuid)
		if privat.neworking[name] == nil then
			return true
		end
		if privat.neworking[name].uuid ~= uuid then
			if privat.neworking[name].last_uuid ~= uuid then
				privat.neworking[name].last_uuid = uuid
				SendMessage(MP.GetId(name),"Вы приехали не туда.")
				return true
			else
				return true
			end
		end

		if (os.time()-privat.neworking[name].last_work_time) < 40 then
			print(os.time()-privat.neworking[name].last_work_time,"overspeed",name)
			return true
		end
		gps:remove_active_path(name)
		local money = (privat.neworking[name].dist*config.P4M)+(privat.neworking[name].lens*config.BonusOnCunt)
		money = round(money,2)*2
		eco:add(name,"money",money)
		SendMessage(MP.GetId(name),"Вам выплатили "..money.." "..config.currency)
		if privat.neworking[name].lens >= 50 then
			obj:stop(name)
			return false,"Вы выполнили недельный план работ. Может начать заново!"
		end
		if getonlineplayers() < config.PLAYERMIN then
			if 1 <= get_hour() and get_hour() <= 6 then
				return false,"Слишком мало игроков или время пойти поспать."
			end
		end
		privat.neworking[name].last_work_time = os.time()
		privat.neworking[name].last_uuid = uuid
		privat.neworking[name].lens = privat.neworking[name].lens + 1
		local type_work = eco.database[name]["work"]["type"] or true
		privat.neworking[name].dist,privat.neworking[name].uuid = gps:set_random_path(name,type_work)
		privat.neworking[name].alltimemoney = privat.neworking[name].alltimemoney + money
	end

    function obj:stop(name,sender_id)
		MP.TriggerClientEvent(sender_id, "PacketNotify", Util.JsonEncode({color="yellow", title="Оповещение", text="Вы закончили работу"}));
		MP.TriggerClientEvent(sender_id, "PacketProfsUpdate", eco.database[name]["work"]["name"]);
		MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Начать работу")
		if privat.working[name] ~= nil then
			local EGG = timer:get()-privat.working[name] or (timer:get()-60)
			local pay = eco:value(name,"work","money")*round(EGG/3600) or 0
			eco:add(name,"money",pay)
			eco.database[name]["work"]["is_working"] = false
			privat.working[name] = nil
			block_ignore[name] = false
			--RemoutRun(MP.GetId(name), "extensions.vehiclesUni.removeCurrent()")
			return pay, false
		elseif privat.neworking[name] ~= nil then
			local money = privat.neworking[name].alltimemoney or 0
       	 	privat.neworking[name] = nil
			gps:remove_active_path(name)
			return money, true
		end
    end

    function obj:stats(name)
        return privat.working[name]
    end

	function obj:nestats(name)
		return privat.neworking[name]
	end

    --чистая магия!
    setmetatable(obj, self)
    self.__index = self
	return obj
end

function PressButton(id,data)
	local name = MP.GetPlayerName(id)
	log({id,name,data})
	if work:stats(name) == nil and work:nestats(name) == nil then
		START_WORK(id,name,data)
	else
		STOP_WORK(id,name,data)
	end

end

function START_WORK(sender_id,sender_name, message)
	if work:stats(sender_name) == nil and work:nestats(sender_name) == nil then
		if config.PLAYERMIN <= getonlineplayers() then
			local works,zp,isnew = work:start(sender_name,sender_id)
			zp = tonumber(zp) or 0.1
			if isnew then
				SendMessage(sender_id,"💼 Вы начали доставку. Ваша работа: "..works.." | Зп за километр "..(tonumber(zp)*1000)..""..config.currency)
			else
				SendMessage(sender_id,"💼 Вы начали работать. Ваша работа: "..works.." | Зп "..zp..""..config.currency)
			end
		else
			SendMessage(sender_id,"Для работы на сервере нужно ещё "..config.PLAYERMIN-getonlineplayers().." игрока.")
		end
	else
		SendMessage(sender_id,"💼 Вы уже работаете.")
	end
end

function STOP_WORK(sender_id,sender_name, message)
	local pay,isnew = work:stop(sender_name,sender_id)
	if isnew then
		SendMessage(sender_id,"Вы закончили работать. За время работы вам выплатили: "..pay.." "..config.currency)
	else
		SendMessage(sender_id,"Вы закончили работать. Вам заплатили: "..(pay or 0).." "..config.currency)
	end
end

function ASTOP_WORK(sender_id,sender_name, message)
	local user = erors(message, 2)
	local pay,isnew = work:stop(user,MP.GetId(user))
	if isnew then
		SendMessage(user,"Вы принудительно закончили работать. За время работы вам выплатили: "..pay.." "..config.currency)
		SendMessage(sender_id,"Вы заставили закончили работать игрока "..user..". За время работы ему выплатили: "..pay.." "..config.currency)
	else
		SendMessage(user,"Вы принудительно закончили работать. Вам заплатили: "..pay.." "..config.currency)
		SendMessage(sender_id,"Вы заставили закончили работать игрока "..user.." Ему заплатили: "..pay.." "..config.currency)
	end
end

function STAT_WORK(sender_id,sender_name, message)
    local stats = work:stats(sender_name)
	local nestats = work:nestats(sender_name)
	if stats then
		local EGG = timer:get()-stats
		if EGG/60 > 2 then --Если минуты
			SendMessage(sender_id,"💼 Вы работали: "..tostring(round(EGG/60,0)).." мин. | Заработанно: "..round(eco:value(sender_name,"work","money")*(EGG/3600),0).." "..config.currency)
		else
			SendMessage(sender_id,"💼 Вы работали: "..tostring(EGG).." сек. | Заработанно: "..round(eco:value(sender_name,"work","money")*(EGG/3600),0).." "..config.currency)
		end
	elseif nestats then
		SendMessage(sender_id,"💼 Вы доставили: "..nestats.lens.." шт. | Выплачено: "..round(nestats.alltimemoney,0).." "..config.currency)
	else
		SendMessage(sender_id,"💼 Вы не работаете. ")
	end
end

function WHY_WORK(sender_id,sender_name, message)
	for name,time in pairs(work:all()) do
		local EGG = timer:get()-work:stats(name)
		if EGG/60 > 2 then --Если минуты
			SendMessage(sender_id,name.."| "..eco:value(name,"work","name").." | "..tostring(round(EGG/60,0)).." мин.")
		else
			SendMessage(sender_id,name.." | "..eco:value(name,"work","name").." | "..tostring(EGG).." сек.")
		end
	end
	for name,time in pairs(work:neall()) do
		SendMessage(sender_id,name.." | "..eco:value(name,"work","name").." | "..time.lens.." шт. | Выплачено: "..round(time.alltimemoney,0).." "..config.currency)
	end
end

function CheckWorkW()
	if getonlineplayers() < config.PLAYERMIN then
		if 1 <= get_hour() and get_hour() <= 6 then
			for name, time in pairs(work:all()) do
				STOP_WORK(MP.GetId(name),name,"")
			end
		end
	end
end

function CheckWayPoint()
	local s = gps:get_user_in_point()
	if s ~= nil then
		for name, uuid in pairs(s) do
			local notend, message = work:get_next_point(name,uuid)
			if notend == false then
				SendMessage(MP.GetId(name),message)
			end
		end
	end
end

function SpawnWorkCar(name, workname)
	if work.workcars[workname] == nil then
		return
	end
	local car = work.workcars[workname][math.random(1, #work.workcars[workname])]
	local car_model = car.model
	local car_config = car.config

	--MP.TriggerClientEvent(MP.GetId(name), "ECOUNBLOCK", "SA")
	block_ignore[name] = true
	RemoutRun(MP.GetId(name), "core_vehicles.spawnNewVehicle(\""..car_model.."\", {config = \""..car_config.."\"})")
	--MP.TriggerClientEvent(MP.GetId(p2), "ECOBLOC", M.data)
end

function UpdateWorkButton(id,data)
	MP.TriggerClientEvent(id, "PacketProfsUpdate", eco.database[name]["work"]["name"]);
	MP.TriggerClientEvent(id, "PacketProfsButtonUpdate" ,"Начать работу");
end

work = Working:init()
M.command = {
    {category = "work",command = "start", help = "💼 Начать работу.",func = "START_WORK"},
    {category = "work",command = "stop", help = "💼 Закончить работу.",func = "STOP_WORK"},
	{category = "work",command = "info", help = "💼 Сколько я работал?",func = "STAT_WORK"},
	{category = "work",command = "why", help = "💼 Кто работает.",func = "WHY_WORK"},
	{category = "work",command = "astop", help = "💼 Принудительно закончить работу игрока.", args = "[name] ",func = "ASTOP_WORK", roles = {"moderator","admin"}},
}


function M.load()
	MP.RegisterEvent("EventJobsButton", "PressButton")
	HeventTimer.addFunc(CheckWayPoint, 1)
	HeventTimer.addFunc(CheckWorkW, 10)
end

function M.unload()
end

return M
