local M = {}
local DB = require "lib.database"
M.info = "Экономическая система"

M.ver = "2.0"

online_player = {}
local Player = require "lib.player"

local shablon = {money = config.startmoney, work = {name = config.starworkname,money = config.startworkmoney,on_works = false}, drivelicence = config.drivelicence,perm = 1}
--
local Eco = {}
extended(Eco,DB)

function Eco:getOnline()
    local ret = {}
    for i,data in pairs(database_player) do
        if data["online"] == true then
            ret[i] = data
        end
    end
    return ret
end

function Eco:join(id)
    if self.database[MP.GetPlayerName(id)] == nil then
        self.database[MP.GetPlayerName(id)] = {money = config.startmoney, work = {name = config.starworkname,money = config.startworkmoney,on_works = false}, drivelicence = table.shallow_copy(config.drivelicence),perm = 1}
        eco.database[MP.GetPlayerName(id)]["drivelicence"]["A"] = true
        self:save()
    end
end

function Eco:joinOnServer(id)
    print("joinOnServer",id)
    if self.database[MP.GetPlayerName(id)]["online"] == true and self.database[MP.GetPlayerName(id)]["work"]["on_works"] == true then
        Eco:add(MP.GetPlayerName(id),"money",(self.database[MP.GetPlayerName(id)]["work"]["money"]/4))
        SendMessage(id,"Вам начислена компенсация в размере"..(self.database[MP.GetPlayerName(id)]["work"]["money"]/4).." "..config.currency)
        self.database[MP.GetPlayerName(id)]["work"]["on_works"] = false
    end
    self.database[MP.GetPlayerName(id)]["online"] = true
    if online_player == nil then
        online_player = {}
    end
    online_player[id] = MP.GetPlayerName(id)
    self:save()
end

function Eco:exit(id)
    self.database[MP.GetPlayerName(id)]["online"] = false
    if online_player[id] ~= nil then
        local name = online_player[id]
        work:stop(name)
        online_player[id] = nil
        CTS[name] = nil
    end
    self:save()
end


-- ADMIN COMMAND
function SET(sender_id,sender_name,message)
	local cur = config.currency
	local case = split(message," ")
	local name = erors(case[1],2)
	case[1] = nil
	local type = case[3]
	local value = case[2]
	--case[3] = tonumber(case[3])

	if value == "name" then
	    SendMessage(sender_id,"У вас нет прав редактировать этот параметр")
    else
		log("Установлено значение "..case[#case-1].." игроку "..name.." в размере ".. case[#case])
		SendMessage(sender_id,name..": "..tostring(eco:set(name,table.unpack(case))))
	end
end

function GET_ALL_TYPE(sender_id,sender_name,message)
    local ret = ""
    for i,data in pairs(eco.database[sender_name]) do
        ret = ret ..""..i..": "..type(data).."\n"
    end
    SendMessage(sender_id,ret)
end

function ADD(sender_id,sender_name, message)   -- name,$,payday,bank$,WorkName,taxIP
	local cur = config.currency
	local case = split(message," ")
	local name = erors(case[1],2)
	case[1] = nil
	local type = case[2]
	local value = tonumber(case[3]) or case[3]
	if value == "name" then
        SendMessage(sender_id,"У вас нет прав редактировать этот параметр")
        return 1
	else
		log("Добавить значение "..case[#case-1].." игроку "..name.." в размере ".. case[#case])
		SendMessage(sender_id,name..": "..tostring(eco:add(name,table.unpack(case))))
		return 1
	end
end

function CHEK(sender_id,sender_name, message)
	local cur = config.currency
	local case = split(message," ")
	local name = erors(case[1],2)
	local type = case[2]
	SendMessage(sender_id,eco:value(name,type))
end

-- System Commands [[
function EXITPLAYER(player_id)
	eco:exit(player_id)
end

function JOINPLAYER(player_id)
    eco:joinOnServer(player_id)
end

function AddtoList(id)
	eco:join(id)
end

-- USER COMMAND [[
function BAL(sender_id,sender_name, message)
	local cur = config.currency
	local ret = eco:value(sender_name,"money")
	local ret1 = eco:value(sender_name,"work","money")
    local old_work = true
    if ret1 == 0 then
        old_work = true
        ret1 = eco:value(sender_name,"work","metr")
    end
	local ret2 = eco:value(sender_name,"work","name")
    if old_work then
        SendMessage(sender_id, "Ваш Баланс💵: "..ret.." "..cur.." | Зарплата💸: "..ret1.." "..cur.." за работу💼 "..ret2)
    else
        SendMessage(sender_id, "Ваш Баланс💵: "..ret.." "..cur.." | Плата за километр 💸: "..(ret1*1000).." "..cur.." за работу💼 "..ret2)
    end

	return 1
end

function PAY(sender_id,sender_name, message) -- Перевод от одного к другому
	local p2,money = MessageParser(message," ",2) -- имя и колл-во денег
    local p2 = p2
	local money = tonumber(money[1]) or "Error"
    if money == "Error" then
        SendMessage(sender_id, "Неверное значение")
        return
    end
    money = math.abs(money)
    money = round(money,1)
	local currency = config.currency

	if MP.check_in_online(p2) == true or p2 == "CMD" then
		if (eco:value(sender_name,"money")-money >= 0) then
            local p1 = eco:add(sender_name,"money",-money)
            local pm2 = eco:add(p2,"money",money)
            if p2 == "CMD" then
                SendMessage(-1,"Игрок "..sender_name.." перевел деньги в CMD в размере "..money.." "..currency)
            else
                SendMessage(MP.GetId(p2), "Игрок " .. sender_name .." перевёл вам деньги 💵 в размере " .. money .. " "..currency)
            end
            SendMessage(sender_id, "Вы перевели деньги игроку "..p2.." в размере "..money.." "..currency)
		else
			SendMessage(sender_id, "У вас не хватает денег 💵")
		end
	else 
		SendMessage(sender_id, "Проверьте написание."..p2)
	end 
	return 1
end

function MYINFO(sender_id,sender_name, message)
    local case = split(message," ")
    local name = MP.GetId(case[1]) or sender_id
    local ret = sender_name.." предоставил данные о себе вам.\n"
    ret = ret.."Имя: "..sender_name.."\n"
    ret = ret.."Работа: "..eco:value(sender_name,"work","name").."\n"

    local data
    if eco:value(sender_name,"work","on_works") == true then
        data = "Да"
    else
        data = "Нет"
    end
    ret = ret.."Работает: "..data.."\n"
    ret = ret.."Текущие права: | "
    local data
    for category,ovn in pairs(eco.database[sender_name]["drivelicence"]) do
        if ovn then
            ret = ret..category.." | "
        end

    end
    ret = ret.."\n"
    if Cars.lastCar[sender_name] then
        ret = ret.."Текущая машина: "..Cars.lastCar[sender_name].name.."\n"
    else
        ret = ret.."Текущая машина: нет\n"
    end
    SendMessage(name,ret)
end

function GETINFO(sender_id,sender_name, message)
    local case = split(message," ")
    local name = erors(case[1],2)
    local ret = ""
    ret = ret.."Имя: "..name.."\n"
    ret = ret.."Работа: "..eco:value(name,"work","name").."\n"

    local data
    if eco:value(name,"work","on_works") == true then
        data = "Да"
    else
        data = "Нет"
    end
    ret = ret.."Работает: "..data.."\n"
    ret = ret.."Текущие права: | "
    local data
    for category,ovn in pairs(eco.database[name]["drivelicence"]) do
        if ovn then
            ret = ret..category.." | "
        end

    end
    ret = ret.."\n"
    if Cars.lastCar[name] then
        ret = ret.."Текущая машина: "..Cars.lastCar[name].name.."\n"
    else
        ret = ret.."Текущая машина: нет\n"
    end
    SendMessage(sender_id,ret)
end

-- LOAD PEREMENNI
eco = Eco:init("players.ixt")
M.eco = eco
M.command = {
	{command = "bal", help = "💵 Узнать баланс. ",func = "BAL"},
	{command = "pay", help = "📨 Перевод денег. ",args = "[name] [money] ",func = "PAY"},
	{category = "eco",command = "add",    help = "💵 Добавить значение.",args = "[name] [path] [value]",func = "ADD",roles = {"admin"}},
	{category = "eco",command = "set",    help = "Установить значение.",args="[name] [path] [value]",func = "SET",roles = {"admin"}},
	{category = "eco",command = "chek",   help = "Узнать баланс игрока. ",args= "[name] [type]", func = "CHEK",roles = {"admin"}},
	{category = "eco",command = "getalltype", help = " Вывести все типы ",func = "GET_ALL_TYPE",roles = {"admin"}},
	{command = "info", help = "Узнать информацию о себе, или предоставить ее другому игроку. ", args = "[name]",func = "MYINFO"},
    {command = "getinfo", help = "Узнать информацию о другом игроке. ", args = "[name]",func = "GETINFO",roles = {"moderator","admin"}},
}

function M.load()
	--M.command = RegEvent(M.command)
	MP.RegisterEvent("onPlayerConnecting","AddtoList")
    MP.RegisterEvent("onPlayerJoin","JOINPLAYER")
	MP.RegisterEvent("onPlayerDisconnect","EXITPLAYER")
end

function M.unload()
	eco:save()
end

return M