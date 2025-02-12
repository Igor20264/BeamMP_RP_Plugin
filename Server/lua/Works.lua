local M = {}
local DB = require "lib.database"

M.info = "Система работ"
M.ver = "1.2"

local function getonlineplayers()
	return MP.GetPlayerCount()
end


local Working = {}
Working.__index = Working
function Working:init()
	local obj = setmetatable({}, self)
    local privat = {}  --приватное свойство
        privat.working = {}
		privat.neworking = {}
		privat.workcars = load_database("work_cars.ixt") or {}

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
			privat.working[name] = {start = timer:get()}
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
		local money = (privat.neworking[name].dist*eco.database[name]["work"]["metr"])+(privat.neworking[name].lens*config.BonusOnCunt)
		if (privat.neworking[name].dist > 8096*1.4142) then
			SendMessage(MP.GetId(name), "Читер...")
			money = -money
		end
		gps:remove_active_path(name)
		local boost = 1
		if privat.neworking[name].end_temp and timer:get() < privat.neworking[name].end_temp then
			boost = privat.neworking[name].temp_boost
		end
		money = round(money*boost,2)*2
		eco:add(name,"money",money)
		statistic:addInfo(name,"workAddMoney",money)
		SendMessage(MP.GetId(name),"Вам выплатили "..money.." "..config.currency)
		privat.neworking[name].last_work_time = os.time()
		privat.neworking[name].last_uuid = uuid

		if privat.neworking[name].lens >= 50 then
			obj:stop(name)
			return false,"Вы выполнили недельный план работ. Может начать заново!"
		end
		if getonlineplayers() < config.PLAYERMIN and config.checktime == true then
			if 1 <= get_hour() and get_hour() <= 6 then
				obj:stop(name)
				return false,"Слишком мало игроков или время пойти поспать."
			end
		end
		privat.neworking[name].lens = privat.neworking[name].lens + 1
		local type_work = eco.database[name]["work"]["type"] or true

		-- Генерируем новую точку, пока она не будет на достаточном расстоянии
		local min_distance = 300 -- Минимальное расстояние в метрах
		local new_dist, new_uuid = gps:set_random_path(name, type_work,min_distance)

		privat.neworking[name].dist = new_dist
		privat.neworking[name].uuid = new_uuid
		privat.neworking[name].alltimemoney = privat.neworking[name].alltimemoney + money
	end

    function obj:stop(name,sender_id)
		if sender_id == nil then
			sender_id = MP.GetId(name)
		end
		MP.TriggerClientEvent(sender_id, "PacketNotify", Util.JsonEncode({color="yellow", title="Оповещение", text="Вы закончили работу"}));
		MP.TriggerClientEvent(sender_id, "PacketProfsUpdate", eco.database[name]["work"]["name"]);
		MP.TriggerClientEvent(sender_id, "PacketProfsButtonUpdate" ,"Начать работу")
		if privat.working[name] ~= nil then
			local EGG = 0
			local istEGG = 0
			if privat.working[name].start_temp ~= nil then
				local befor_temp = privat.working[name].start_temp-privat.working[name].start
				local temp = 0
				if privat.working[name].end_temp < timer:get() then
					temp = privat.working[name].end_temp-privat.working[name].start
				else
					temp = timer:get()-privat.working[name].start
				end
				local post_temp = 0
				if privat.working[name].end_temp < timer:get() then
					post_temp = timer:get()-privat.working[name].end_temp
				else
					post_temp = 0
				end
				EGG = (befor_temp + (temp*privat.working[name].temp_boost) + post_temp)
				istEGG = timer:get()-privat.working[name].start or 360
			else
				EGG = timer:get()-privat.working[name].start or (timer:get()-60)
				istEGG = EGG
			end
			istEGG = round(istEGG/3600)
			local pay = eco:value(name,"work","money")*round(EGG/3600) or 0
			eco:add(name,"money",pay)
			statistic:addInfo(name,"workTimeHour",istEGG)
			statistic:addInfo(name,"workAddMoney",pay)
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
-- вернул
    function obj:stats(name)
        return privat.working[name]
    end

	function obj:nestats(name)
		return privat.neworking[name]
	end

    --чистая магия!

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
			statistic:addInfo(sender_name,"startWork",1)
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
		local EGG = timer:get()-stats.start
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
		local EGG = timer:get()-work:stats(name).start
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

function CheckTimeWork()
    for name, data in pairs(work:all()) do
        if type(data) ~= "number" and data.end_time <= timer:get() then
            STOP_WORK(MP.GetId(name), name, "")
        end
    end
end

-- TODO: Реализовать функцию спавна рабочей машины

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

function BoostWork(sender_id, sender_name, message)
    local args = string.split(message, " ")
    if #args < 2 then
        SendMessage(sender_id, "Использование: !work boostwork [игрок] [время в минутах] [multiplier=2]")
        return
    end

    local target_name = args[1]
    local duration = timeConverter(args[2]) or timeConverter("1h") -- Seconds
    if not duration or duration <= 0 then
        SendMessage(sender_id, "Неверное время. Укажите время в минутах.")
        return
    end
    local target_id = MP.GetId(target_name) or nil
    if not target_id then
        SendMessage(sender_id, "Игрок " .. target_name .. " не найден.")
        return
    end

    local boost_multiplier = tonumber(args[3]) or 2 -- Умножитель опыта
    local end_time = timer:get() + duration

    if work:stats(target_name) then
        work:stats(target_name).temp_boost = boost_multiplier
        work:stats(target_name).end_temp = end_time
		work:stats(target_name).start_temp = timer:get()
        SendMessage(target_id, "Вам назначен умножитель опыта x" .. boost_multiplier .. " на " .. duration/60 .. " минут.")
        SendMessage(sender_id, "Вы назначили умножитель опыта x" .. boost_multiplier .. " игроку " .. target_name .. " на " .. duration/60 .. " минут.")
    elseif work:nestats(target_name) then
        work:nestats(target_name).temp_boost = boost_multiplier
        work:nestats(target_name).end_temp = end_time
        SendMessage(target_id, "Вам назначен умножитель опыта x" .. boost_multiplier .. " на " .. duration/60 .. " минут.")
        SendMessage(sender_id, "Вы назначили умножитель опыта x" .. boost_multiplier .. " игроку " .. target_name .. " на " .. duration/60 .. " минут.")
    else
        SendMessage(sender_id, "Игрок " .. target_name .. " не работает.")
    end
end
--[[
function OFFBOOST(sender_id,sender_name, message)
	local name = erors(message)
	if work:stats(name) then
		work:stats(name).temp_boost = nil
		work:stats(name).start_temp = nil
		work:stats(name).end_temp = nil
		SendMessage(sender_id, "Вы отменили умножитель опыта.")
	elseif work:nestats(name) then
		work:nestats(name).temp_boost = nil
		work:nestats(name).end_temp = nil
		SendMessage(sender_id, "Вы отменили умножитель опыта.")
	else
		SendMessage(sender_id, "Игрок " .. sender_name .. " не работает.")
	end
end--]]

function WorkOFFGEt(sender_id,sender_name, message)
	block_ignore[sender_name] = true
	--RemoutRun(MP.GetId(p2), data_unblock)
	SendMessage(-1,"Игрок "..sender_name.." получил off для создания рабочей машины.")
	return 0
end

work = Working:init()
M.command = {
	{category = "work",command = "boostwork", help = "💼 Умножитель опыта.", args = "[игрок] [1s or 1m or 1h or 1d]",func = "BoostWork"},
	{category = "work",command = "getCar", help = "💼 Получить off для получения рабочей машины.",func = "WorkOFFGEt"},
    {category = "work",command = "start", help = "💼 Начать работу.",func = "START_WORK"},
    {category = "work",command = "stop", help = "💼 Закончить работу.",func = "STOP_WORK"},
	{category = "work",command = "info", help = "💼 Сколько я работал?",func = "STAT_WORK"},
	{category = "work",command = "why", help = "💼 Кто работает.",func = "WHY_WORK"},
	{category = "work",command = "astop", help = "💼 Принудительно закончить работу игрока.", args = "[name] ",func = "ASTOP_WORK", roles = {"moder","admin"}},
}


function M.load()
    MP.RegisterEvent("EventJobsButton", "PressButton")
    HeventTimer.addFunc(CheckWayPoint, 1)
    HeventTimer.addFunc(CheckWorkW, 10)
    --HeventTimer.addFunc(CheckTimeWork, 1) -- Проверка работы по времени
end

function M.unload()
end

return M
