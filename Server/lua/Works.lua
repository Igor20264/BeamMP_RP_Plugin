local M = {}
local DB = require "lib.database"

M.info = "Система работ"
M.ver = "1.2"

local function getonlineplayers()
	return MP.GetPlayerCount()
end


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
-- вернул
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
