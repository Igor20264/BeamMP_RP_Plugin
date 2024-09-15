local M = {}
M.info = "Экономическая система"
M.ver = "1.5"

M.money= {}
Eco = {}
function Eco:init()
 -- свойства
	local privat = {}  --приватное свойство
	
    local obj= {} --публичное свойство
		obj.s = load_database("economica.ixt")
		obj.world_balans = load_database("world_money.ixt")
    -- метод
	
	function obj:inList(name)
		for i,case in ipairs(self.s) do	
			if name == case[1] then -- name,$,payday,bank$,WorkName,taxIP
				return true
			end
		end
		return false
	end
	
	function obj:getId(name)
		for i, case in ipairs(self.s) do 
			if name == case[1] then return i end -- name,$,payday,bank$,WorkName,taxIP
		end
		return nil
	end

	function obj:bal(name,type)
		local id = obj:getId(name)
		if id == nil then log("Игрок с ником "..name.." не найден.",4); SendMessage(name,"Ошибка! [ЭСоБ#34] передайте код ошибки администратору!") end
		return self.s[id][type]
	end

	function obj:new(id)
		local name = MP.GetPlayerName(id)
		if obj:inList(name) == false then
			local startparam = M.config
			self.s[#self.s+1]={name,startparam.start_money,startparam.payday,0,startparam.namework,startparam.taxIP} -- name,$,payday,bank$,WorkName,taxIP
			obj:save()
			local mess = name.. " Впервые на сервере, создал счёт!"
			log(mess,4)
		end 
	end
	
	function obj:set(name,type,new_value)
		local id = obj:getId(name)
		self.s[id][type] = new_value
		obj:save()
		return self.s[id][type]
	end
	
	function obj:add(name,type,new_value)
		local id = obj:getId(name)
		self.s[id][type] = new_value+self.s[id][type]
		obj:save()
		return self.s[id][type]
	end

	function obj:replaci(name,new_ball,types)
		self.s[obj:getId(name)][types] = new_ball
	end
	
	function obj:save()
		save_database("economica.ixt",self.s)
		save_database("world_money.ixt",self.world_balans)
	end
	
    --чистая магия!
    setmetatable(obj, self)
    self.__index = self
	return obj
end

-- конец основых функций


-- ADMIN COMMAND
function SET(sender_id,sender_name,message)
	local cur = M.config.currency
	local case = split(message," ")
	case[1] = erors(case[1],2)
	case[3] = tonumber(case[3])
	if case[3] == 3 then
		log("установить зп игроку: "..case[1].." в размере "..case[2])
		eco:set(case[1],case[3],tonumber(case[2]))
		local ret = case[1]..": "..eco:bal(case[1],case[3]) 
		SendMessage(sender_id,ret)
	elseif case[3] == 5 then
		log("Установить Название работы игроку: "..case[1])
		eco:set(case[1],case[3],case[2])
		local ret = case[1]..": "..eco:bal(case[1],case[3])
		SendMessage(sender_id,ret)
		
	elseif case[3] == 4 or case[3] == 1  or case[3] == 2 then  
		SendMessage(sender_id,"У вас нет прав редактировать этот параметр") 
	end
end

function ADD(sender_id,sender_name, message)   -- name,$,payday,bank$,WorkName,taxIP
	local cur = M.config.currency
	local case = split(message," ")
	case[1] = erors(case[1],2)
	case[3] = tonumber(case[3])
	if case[3] == 2 then 
		if eco.world_balans.money <= 0 then
			SendMessage(sender_id,"Денег нет но вы держитесь")
		else
			--local p2,case = MessageParser(message," ") -- имя и колл-во денег
			if eco.world_balans.money - tonumber(case[2]) <= 0 then 
				SendMessage(sender_id,"В мире нету столько денег") 
				return 1
			else
				eco:add(case[1],case[3],tonumber(case[2]))
				eco.world_balans.money = eco.world_balans.money - tonumber(case[2])
				local ret = case[1]..": ".. eco:bal(case[1],case[3])
				SendMessage(sender_id,ret)
				return 1
			end
		end
	elseif case[3] == 3 then
		--local p2,case = MessageParser(message," ") -- имя и колл-во денег
		log("Добавить зп игроку: "..case[1].." в размере "..case[2])
		eco:add(case[1],case[3],tonumber(case[2]))
		local ret = case[1]..": "..eco:bal(case[1],case[3])
		SendMessage(sender_id,ret)
		return 1
	elseif case[3] == 4 or case[3] == 1 then  
		SendMessage(sender_id,"У вас нет прав редактировать этот параметр") 
		return 1
	end
end

function CHEK(sender_id,sender_name, message)
	local cur = M.config.currency
	local case = split(message," ")
	case[1] = erors(case[1],2)
	SendMessage(sender_id,""..eco:bal(case[1],tonumber(case[2]))) 
end

function SaS(id,percent_cfg,limit_percent)
	if eco.s[id][4] >= limit_percent then 
		local procent = round(((eco.s[id][4]+1)/100)*percent_cfg)
		eco.s[id][4] = eco.s[id][4]-procent
	else	
		local procent = round(((eco.s[id][4]+1)/100)*percent_cfg)
		eco.s[id][4] = eco.s[id][4]+procent
	end
	return eco.s[id][3]
end
--
local working = {}

function START_WORK(sender_id,sender_name, message)
	if working[sender_name] == nil then
		if M.config.PLAYERMIN <= #MP.GetPlayers() then
			working[sender_name] = {work = sender_id,Stime = timer:Get()}
			SendMessage(sender_id,"Вы начали работать. Ваша работа: "..eco:bal(sender_name,5))
		else
			SendMessage(sender_id,"Для работы слишком мало игроков")
		end
	else
		SendMessage(sender_id,"Вы уже работает.")
	end
end

function STOP_WORK(sender_id,sender_name, message)
	local EGG = timer:Get()-(working[sender_name].Stime)
	local pay = eco:bal(sender_name,3)*round(EGG/3600)
	eco:add(sender_name,4,pay)
	working[sender_name] = nil
	SendMessage(sender_id,"Вы закончили работать. Вам заплатили: "..pay.." "..M.config.currency)
end

function STAT_WORK(sender_id,sender_name, message)
	if working[sender_name] then
		local EGG = timer:Get()-(working[sender_name].Stime)
		if EGG/60 > 2 then --Если минуты
			SendMessage(sender_id,"Вы работали: "..tostring(round(EGG/60,0)).." мин. | Заработанно: "..round(eco:bal(sender_name,3)*(EGG/3600),0).." "..M.config.currency)
		elseif EGG/3600> 1 then
			SendMessage(sender_id,"Вы работали: "..tostring(round(EGG/3600,0)).." ч. | Заработанно: "..round(eco:bal(sender_name,3)*(EGG/3600),0).." "..M.config.currency)
		else
			SendMessage(sender_id,"Вы работали: "..tostring(EGG).." сек. | Заработанно: "..round(eco:bal(sender_name,3)*(EGG/3600),0).." "..M.config.currency)
		end
	else
		SendMessage(sender_id,"Вы не работаете. ")
	end
end

function WHY_WORK(sender_id,sender_name, message)
	log(working,2)
	for case in pairs(working) do
		EGG = timer:Get()-(working[case].Stime)
		if EGG/60 > 2 then --Если минуты
			SendMessage(sender_id,case.." | "..tostring(round(EGG/60,0)).." мин.")
		elseif EGG/3600> 1 then
			SendMessage(sender_id,case.." | "..tostring(round(EGG/3600,0)).." ч.")
		else
			SendMessage(sender_id,case.." | "..tostring(EGG).." сек.")
		end
	end
end
--[[
function PAYDAY(sender_id,sender_name, message)  -- name,$,payday,bank$,WorkName,taxIP
	if eco.world_balans.money <= 0 then
		SendMessage(-1,"Денег нет но вы держитесь")
		return 1
	else
		local cur = M.config.currency
		local is_only = M.config.payday_only_online
		local percent_cfg = M.config.percent
		local limit_percent = M.config.limit_percent
		local mu = 0
		
		if is_only == false then
			log("PayDay_all")
			for i,case in ipairs(self.s) do
				mu = mu+Sas(i,percent_cfg,limit_percent)
				SendMessage(MP.GetId(case[1]),"Вам начислены зарплата в размере "..case[3].." "..cur.." | За работу: "..case[5].." ")
			end
		elseif is_only == true then
			log("PayDay_Online")
			for i,name in pairs(MP.GetPlayers()) do 
				local idl = eco:getId(name)
				mu = mu+SaS(idl,percent_cfg,limit_percent)
				SendMessage(MP.GetId(name),"Вам начислена зарплата в размере "..eco.s[idl][3].." "..cur.." | За работу: "..eco.s[idl][5])
			end
		end
		eco.world_balans.money = eco.world_balans.money - mu
		eco:save()
		return 1
	end
end
--]]
-- end ADMIN COMMAND

function EXITPLAYER(player_id)
	for case in pairs(working) do
		if working[case].work == player_id then
			log("Work_Stop "..case,3)
			local EGG = timer:Get()-(working[case].Stime)
			local pay = eco:bal(case,3)*round(EGG/3600)
			eco:add(case,4,pay)
			working[case] = nil
			return 1
		end
	end
end

-- USER COMMAND [[
function BAL(sender_id,sender_name, message)
	local cur = M.config.currency
	local id_list = eco:getId(sender_name)
	SendMessage(sender_id, "Ваш Баланс: "..eco.s[id_list][2].." "..cur.." | Зарплата: "..eco.s[id_list][3].." "..cur.." за работу "..eco.s[id_list][5].." | В банке: "..eco.s[id_list][4].." "..cur)
	return 1
end

function BANKPAY(sender_id,sender_name, message)
	local p2,case = MessageParser(message," ",2) -- имя и колл-во денег
	--local player_id,rass = MP.check_in_online(p2) --
	local currency = M.config.currency
	if MP.check_in_online(p2) == true or p2 == "CMD" then 
		if (eco:bal(sender_name,4)-math.abs(tonumber(case[1])) >= 0) then
			log("Начало передачи денег")
			eco:replaci(sender_name,eco:bal(sender_name,4)-math.abs(tonumber(case[1])),4)
			if p2 == "CMD" then
				eco.world_balans.money = eco.world_balans.money + math.abs(tonumber(case[1]))
			else
				eco:replaci(p2 ,eco:bal(p2,4)+math.abs(tonumber(case[1])),4)
			end
			eco:save()
			local mess = "Игрок " .. sender_name .." перевёл игроку ".. p2 .. " деньги в размере " .. tonumber(case[1]) .. " "..currency
			SendMessage(sender_id, mess)
			SendMessage(MP.GetId(p2), mess)
		else
			SendMessage(sender_id, "У вас не хватает денег в банке | Положить деньги в банк !put [money]")
		end
	else 
		SendMessage(sender_id, "Проверьте написание. "..p2)
	end 
	return 1
end

function PAY(sender_id,sender_name, message) -- Перевод от одного к другому
	local p2,case = MessageParser(message," ",2) -- имя и колл-во денег
	--local player_id,rass = MP.check_in_online(p2) --
	local currency = M.config.currency
	local limit = M.config.limit_pay
	if MP.check_in_online(p2) == true or p2 == "CMD" then 
		if (eco:bal(sender_name,2)-math.abs(tonumber(case[1])) >= 0) then
			if (tonumber(case[1]) <= limit) then
				log("Начало передачи денег")
				eco:replaci(sender_name,eco:bal(sender_name,2)-math.abs(tonumber(case[1])),2)
				if p2 == "CMD" then
					eco.world_balans.money = eco.world_balans.money + math.abs(tonumber(case[1]))
				else
					eco:replaci(p2 ,eco:bal(p2,2)+math.abs(tonumber(case[1])),2)
				end
				log("okey #2")
				eco:save()
				local mess = "Игрок " .. sender_name .." передал игроку ".. p2 .. " деньги в размере " .. tonumber(case[1]) .. " "..currency
				SendMessage(MP.GetId(p2), mess)
				SendMessage(sender_id, mess)
			else
				SendMessage(sender_id, "Превышен лимит передачи денег | лимит "..limit.." | Используйте команду !bpay [name] [money]")
			end
		else
			SendMessage(sender_id, "У вас не хватает денег")
		end
	else 
		SendMessage(sender_id, "Проверьте написание. "..p2)
	end 
	return 1
end

function REM(sender_id,sender_name, message) --снятие
	local currency = M.config.currency
	if (eco:bal(sender_name,4)-math.abs(tonumber(message)) >= 0) then
		log("Начало передачи денег")
		eco:replaci(sender_name,eco:bal(sender_name,4)-math.abs(tonumber(message)),4)
		eco:replaci(sender_name,eco:bal(sender_name,2)+math.abs(tonumber(message)),2)
		eco:save()
		local mess = "Вы сняли из банка " .. tonumber(message) .. " "..currency
		SendMessage(sender_id, mess)
	else
		SendMessage(sender_id, "У вас не хватает денег")
	end
	return 1
end

function PUT(sender_id,sender_name, message) -- положить
	local currency = M.config.currency
	if (eco:bal(sender_name,2)-math.abs(tonumber(message)) >= 0) then
		log("Начало передачи денег")
		eco:replaci(sender_name,eco:bal(sender_name,2)-math.abs(tonumber(message)),2)
		eco:replaci(sender_name,eco:bal(sender_name,4)+math.abs(tonumber(message)),4)
		eco:save()
		local mess = "Вы положили в банк " .. tonumber(message) .. " "..currency
		SendMessage(sender_id, mess)
	else
		SendMessage(sender_id, "У вас не хватает денег")
	end
	return 1
end


--

 
function GROUPJOIN(sender_id,sender_name, message) --   !group join [group_name]
	local groupName = message
	print(groupName)
	if Group.groups[groupName].leave_only_kick then
		if Group:addUser(groupName,sender_name) then
			SendMessage(sender_id,"Вы присоединились к: "..groupName)
		else
			SendMessage(sender_id,"Доступ запрещен к: "..groupName)
		end
	else
		SendMessage(sender_id,"Запросите доступ к: "..groupName..". У "..Group.groups[groupName].playerDay)
	end
	
end

function GROUPLEAVLE(sender_id,sender_name, message) --   !group exit [group_name]
	local groupName = message
	if Group.groups[groupName].leave_only_kick then
		Group:removeUser(groupName,sender_name)
		SendMessage(sender_id,"Вы покинули: "..groupName)
	else
		SendMessage(sender_id,"Вы не можете покинуть: "..groupName.." Попоросите администратора группы исключить вас.")
	end
end

function MYGROUP(sender_id,sender_name, message)  --   !group worked
	SendMessage(sender_id,"[A] - Вы можете управлять группой | [H] - Это скрытая группа | [F] - Свободный вход-выход")
	local currency = M.config.currency
	local isadmin = false
	for i,case in ipairs(Group:getGroupsForName(sender_name)) do
		if Group:isModerator(case,sender_name) and isadmin==false then isadmin = true;setAdmin(sender_name,"group",1) end
		SendMessage(sender_id,case.." | ЗП: "..Group.groups[case].Value.." "..currency.." | Владелец: "..Group.groups[case].playerDay)
	end
	if isadmin == false then
		setAdmin(sender_name,"group",0)
	end
	
end

function GROUPLISTALL(sender_id,sender_name, message) --   !group list
	SendMessage(sender_id,"[F] - Свободный вход-выход. Некоторые группы запрещают находится в [F] Группах")
	for case in pairs(Group.groups) do
		local ret = ""
		if Group.groups[case].hide then
		else
			if Group.groups[case].leave_only_kick then ret = ret.."[F]" end
			SendMessage(sender_id,ret.." "..case.." | Владелец: "..Group.groups[case].playerDay) 
		end
	end
end

function GROUPINFO(sender_id,sender_name, message)  --   !group info [group_name]
	local currency = M.config.currency
	local groupName = message
	local s = Group.groups[groupName]
	SendMessage(sender_id,groupName.." | ЗП: "..s.Value.." "..currency.." | "..s.description)
	
end

function ADDREUER(sender_id,sender_name, message) -- !gruop add req [name_group] [req_group] [1\2] 
	local mes = split(message," ")
	if not Group:isModerator(groupName,sender_name) then
		return 0
	end
	if toboolean(mes[3]) == false then
	 value = nil
	else
	 value = true
	end
	Group.groups[mes[1]].Reqvaer[mes[2]] = value
	Group:save()
end

function GROUPEDIT(sender_id,sender_name, message) -- !group edit GaZ [group_name] [param] [value] |1 - ЗП [число], 2 - скрытая ли группа [1]\[0], 3 - кто платит зп [name], 4 - свободный вход выход [1]\[0], 5 - Заблокировать[1]\разблокировать[0]|
	local mes = split(message," ")
	local groupName = mes[1]
	if not Group:isModerator(groupName,sender_name) then
		return 0
	end
	Group:setValue(groupName,mes[3],mes[2])
end

function ADMINLISTGROUP(sender_id,sender_name, message) -- !group alist
	for case in pairs(Group.groups) do
		SendMessage(sender_id,case.." | Владелец: "..Group.groups[case].playerDay) 
	end
end

function CREATEGROUP(sender_id,sender_name, message) -- !group create [group_name] [value]
	local mes = split(message," ")
	log(#mes,2)
	Group:create(mes[1],tonumber(mes[2]))
	SendMessage(sender_id,"Создана группа.")
	Group:addUser(mes[1],sender_name,true)
end

function DELETGROUP(sender_id,sender_name, message) --!group remove yes [group_name]
	local mes = split(message," ")
	log(#mes,2)
	if Group:remove(mes[1]) then
		SendMessage(sender_id,"Группа "..mes[1].." удалена")
	else 
		SendMessage(sender_id,"Ошибка.")
	end
end

function ADMINADDTOGROUP(sender_id,sender_name, message) --!group up [group_name] [player_name]
	local mes = split(message," ")
	local groupName = mes[1]
	if not Group:isModerator(groupName,sender_name) then
		return 0
	end
	Group:setAdmin(groupName,mes[2],toboolean(mes[3]))
	SendMessage(sender_id,"Администратор "..mes[2].." добавлен")
	return true
end

function KICKGROUP(sender_id,sender_name, message) -- !group kick [group_name] [player_name]
	local mes = split(message," ")
	local groupName = mes[1]
	if not Group:isModerator(groupName,sender_name) then
		return 0
	end
	
	Group:removeUser(groupName,mes[2])
	SendMessage(sender_id,"Пользователь исключон из группы "..groupName)
	return true
end

function ADDPLAYERTOGROUP(sender_id,sender_name, message) -- !group addto [group_name] [player_name]
	local mes = split(message," ")
	local groupName = mes[1]
	if not Group:isModerator(groupName,sender_name) then
		return 0
	end
	Group:addUser(groupName,mes[2])
	SendMessage(sender_id,"Пользователя добавили в группу "..groupName)
	return true
end

function INGROUPPLAYERS(sender_id,sender_name, message) --!group ingroup [name]
	local mes = split(message," ")
	for i,case in ipairs(Group:getGroupsForName(sender_name)) do
		SendMessage(sender_id,case.." | Владелец: "..Group.groups[case].playerDay) 
	end
end

--[[
function PAYDAY_TIMER()
	log("Timer_PayDay_Event")
	if M.config.PLAYERMIN <= #MP.GetPlayers() then
		PAYDAY(-2,"CMD","TIMER")
	end
end
--]]
--end timer
-- LOAD PEREMENNI
eco = Eco:init()

function AddtoList(id)
	eco:new(id)
end
--Group.TEST()
M.eco = eco
local seconds = 0
M.config = load_config("settings/Economic_Settings")
local prefix = M.config.prefix
M.command = {
	{command = prefix.."bal",    help = "Узнать баланс. "..prefix.."bal ",              func = "BAL",admin = false,hide = false},
	{command = prefix.."pay",    help = "Перевод денег. "..prefix.."pay [name] [money] ",func = "PAY",admin = false,hide = false},
	{command = prefix.."payday", help = "Начисление зарплат. "..prefix.."payday ",      func = "PAYDAY",admin = true,hide = false},
	{command = prefix.."add",    help = "Добавить денег из бюджета. "..prefix.."add [name] [money] [type] |-,$,payday,-,Work|",func = "ADD",admin = true,hide = false},
	{command = prefix.."set",    help = "Установить значение. "..prefix.."set [name] [money] [type] |-,$,payday,-,Work|",func = "SET",admin = true,hide = false},
	{command = prefix.."bank rem",    help = "Снять деньги из банка. "..prefix.."bank rem [money]",func = "REM",admin = false,hide = false},
	{command = prefix.."bank put",    help = "Положить деньги в банк. "..prefix.."bank put [money]",func = "PUT",admin = false,hide = false},
	{command = prefix.."bank pay",   help = "Перевод денег из банка в банк. "..prefix.."bank pay [name] [money] ", func = "BANKPAY",admin = false,hide = false},
	{command = prefix.."chek",   help = "Узнать баланс игрока. "..prefix.."chek [name] [type] |name,$,payday,bank,Work,tax|", func = "CHEK",admin = true,hide = false},
	{command = prefix.."work start", help = "Начать работу "..prefix.."works tart",func = "START_WORK",admin = false,hide = false},
	{command = prefix.."work stop", help = "Закончить работу "..prefix.."work stop",func = "STOP_WORK",admin = false,hide = false},
	{command = prefix.."work info", help = "Сколько я работал? "..prefix.."work info",func = "STAT_WORK",admin = false,hide = false},
	{command = prefix.."work why", help = "Кто работает. "..prefix.."work why",func = "WHY_WORK",admin = true,hide = false},
	{command = prefix.."group list",help = "Кто работает. "..prefix.."group list",func = "GROUPLISTALL",admin = false,hide = false},
	{command = prefix.."group join",help = "Кто работает. "..prefix.."group join",func = "GROUPJOIN",admin = false,hide = false},
	{command = prefix.."group exit",help = "Кто работает. "..prefix.."group exit",func = "GROUPLEAVLE",admin = false,hide = false},
	{command = prefix.."group info",help = "Кто работает. "..prefix.."group info",func = "GROUPINFO",admin = false,hide = false},
	{command = prefix.."group worked",help = "Кто работает. "..prefix.."group worked",func = "MYGROUP",admin = false,hide = false},
	{command = prefix.."group ingroup",help = "Кто работает. "..prefix.."group ingroup [name]",func = "INGROUPPLAYERS",admin = false,hide = false,group = true},
	{command = prefix.."group kick",help = "Кто работает. "..prefix.."group kick [group_name] [player_name]",func = "KICKGROUP",admin = false,hide = false,group = true},
	{command = prefix.."group up",help = "Кто работает. "..prefix.."group up [group_name] [player_name]",func = "ADMINADDTOGROUP",admin = false,hide = false,group = true},
	{command = prefix.."group remove yes",help = "Кто работает. "..prefix.."group remove yes [group_name]",func = "DELETGROUP",admin = false,hide = false,group = true},
	{command = prefix.."group create",help = "Кто работает. "..prefix.."group create [group_name] [value]",func = "CREATEGROUP",admin = true,hide = false,group = false},
	{command = prefix.."group alist",help = "Кто работает. "..prefix.."group alist",func = "ADMINLISTGROUP",admin = false,hide = false,group = true},
	{command = prefix.."group edit GaZ",help = "Кто работает. "..prefix.."group edit GaZ [group_name] [param] [value]",func = "GROUPEDIT",admin = false,hide = false,group = true},
	{command = prefix.."group addto",help = "Добавить в группу"..prefix.."group addto [group_name] [name]",func = "ADDPLAYERTOGROUP",admin = false,hide=false,group=true},
	{command = prefix.."group add req",help = "Добваить зависимые фракции "..prefix.."gruop add req [name_group] [req_group] [0|1]",func = "ADDREUER",admin = false,hide=false,group=true}
}

function M.load() 
	MP.CancelEventTimer("PAYDAY_T") 
	MP.RegisterEvent("PAYDAY_T", "PAYDAY_TIMER")
	local times= M.config.TIMER
	MP.CreateEventTimer("PAYDAY_T", times*1000*60)
	M.command = RegEvent(M.command)
	MP.RegisterEvent("onPlayerConnecting","AddtoList")
	MP.RegisterEvent("onPlayerDisconnect","EXITPLAYER")
end

function M.unload()
	eco:save()
end

return M
 