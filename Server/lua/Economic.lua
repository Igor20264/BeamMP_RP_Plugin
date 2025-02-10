local M = {}
local DB = require "lib.database"
M.info = "Экономическая система"

M.ver = "2.0"

online_player = {}

local Eco = {}
Eco.__index = Eco
setmetatable(Eco, { __index = DB }) -- Наследуем методы из DB

function Eco:init(path)
    local db_instance = DB:init(path) -- Инициализация DB

    -- Копируем поля из db_instance в self
    for key, value in pairs(db_instance) do
        self[key] = value
    end

    return self
end

function Eco:getOnline()
    local ret = {}
    for i,data in pairs(database_player) do
        if data["online"] == true then
            ret[i] = data
        end
    end
    return ret
end

function Eco:player_in_game(name)
    if self.database[name] == nil then
        return false
    else
        return true
    end
end

function Eco:join(id)
    if self.database[MP.GetPlayerName(id)] == nil then
        self.database[MP.GetPlayerName(id)] = {money = config.startmoney, work = {name = config.starworkname,money = config.startworkmoney,metr = config.P4M,on_works = false,time_work = false, time_minute = 0}, drivelicence = shallow_copy(config.drivelicence)}
        self.database[MP.GetPlayerName(id)]["drivelicence"]["A"] = true
        print(self.database[MP.GetPlayerName(id)])
        self:save()
    end
end

function Eco:joinOnServer(id)
    if self.database[MP.GetPlayerName(id)]["online"] == true and self.database[MP.GetPlayerName(id)]["work"]["on_works"] == true then
        self:add(MP.GetPlayerName(id),"money",(self.database[MP.GetPlayerName(id)]["work"]["money"]/4))
        SendMessage(id,"Вам начислена компенсация в размере"..(self.database[MP.GetPlayerName(id)]["work"]["money"]/4).." "..config.currency)
        MP.TriggerClientEvent(id, "PacketbalanceUpdate", self.database[MP.GetPlayerName(id)]["money"]);
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
        work:stop(name,id)
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
    table.remove(case,1)
	local type = case[3]
	local value = case[2]
	--case[3] = tonumber(case[3])

	if case[1] ~= "work" and value == "name" then
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
	SendMessage(sender_id,inspect(eco:value(name,type)))
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
        old_work = false
        ret1 = eco:value(sender_name,"work","metr") or 0
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
    money = tonumber(money[1]) or "Error"
    if money == "Error" then
        SendMessage(sender_id, "Неверное значение")
        return
    end
    money = round(math.abs(money),1)
    local money_nds = money*(config.nds or 0.05)
	local currency = config.currency
    if money_nds == 0 then
        SendMessage(sender_id, "Сумма перевода не может быть равна 0")
        return
    end
	if p2 == "CMD" or MP.check_in_online(p2) == true then
		if (eco:value(sender_name,"money")-(money+money_nds) >= 0) then
            local p1 = eco:add(sender_name,"money",-(money+money_nds))
            if p2 == "CMD" then
                SendMessage(-1,"Игрок "..sender_name.." перевел деньги в CMD в размере "..money.." "..currency)
            else
                local pm2 = eco:add(p2,"money",money)
                SendMessage(MP.GetId(p2), "Игрок " .. sender_name .." перевёл вам деньги 💵 в размере " .. money .. " "..currency)
            end
            SendMessage(sender_id, "Вы перевели деньги игроку "..p2.." в размере "..money.." "..currency.." Комиссия: "..(money_nds).." "..currency)
		else
			SendMessage(sender_id, "У вас не хватает денег 💵")
		end
	else 
		SendMessage(sender_id, "Проверьте написание."..p2)
	end
	return 1
end

function WIPE(sender_id,sender_name, message)
    eco.database[message] = {money = config.startmoney, work = {name = config.starworkname,money = config.startworkmoney,metr = config.P4M,on_works = false}, drivelicence = shallow_copy(config.drivelicence)}
    eco.database[message]["drivelicence"]["A"] = true
    permissions:set_roles(message, {"player"})
    local carss = cars:get_all(sender_name)
    if carss ~= nil then
        for i,_ in pairs(carss) do
            cars:transfer(message,"CMD",i)
        end
    end
    SendMessage(sender_id, "Вы вайпнули игрока "..message)
    SendMessage(message, "Администратор "..sender_name.." вайпнул вас")
    eco:save()
end

-- Функция для обработки ставки
function ROLL(sender_id, sender_name, message)
    local money = tonumber(message)
    if not money then
        SendMessage(sender_id, "Неверное значение")
        return
    end
    money = math.abs(money)
    if money < 1000 then
        SendMessage(sender_id, "Минимальная ставка 1000")
        return
    end
    if money > 5000000 then
        SendMessage(sender_id, "Максимальная ставка 5000000")
        return
    end
    if eco.database[sender_name]["money"] == nil or eco.database[sender_name]["money"] < money then
        SendMessage(sender_id, "У вас не хватает денег 💵")
        return
    end
    if math.random() < config.winChance then
        -- Выигрыш
        local win = money * config.winMultiplier
        local commission = win * config.commissionRate
        local netWin = win - commission
        eco:add(sender_name,"money",netWin)
        SendMessage(sender_id, "Вы выиграли " .. win .. " денег. После вычета комиссии " .. commission .. " денег, ваш выигрыш составляет " .. netWin .. " денег.")
    else
        -- Проигрыш
        local loss = money
        eco:add(sender_name,"money",-money)
        SendMessage(sender_id, "Вы проиграли " .. loss .. " "..config.currency )
    end
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
    for category,ovn in pairs(eco.database[sender_name]["drivelicence"]) do
        if ovn then
            ret = ret..category.." | "
        end

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
    for category,ovn in pairs(eco.database[name]["drivelicence"]) do
        if ovn then
            ret = ret..category.." | "
        end

    end
    SendMessage(sender_id,ret)
end

function COINFLIP(sender_id, sender_name, message)
    local case = split(message, " ")
    if case[1] == nil or case[2] == nil then
        SendMessage(sender_id, "Неверная команда.")
        return
    end
    local opponent_name = erors(case[1], 2)
    local bet_amount = tonumber(case[2]) or 0
    local currency = config.currency

    bet_amount = math.abs(bet_amount)
    bet_amount = round(bet_amount, 2)

    if not MP.check_in_online(opponent_name) then
        SendMessage(sender_id, "Игрок " .. opponent_name .. " не в сети.")
        return
    end

    if opponent_name == sender_name then
        SendMessage(sender_id, "Нельзя вызывать самого себя.")
        return
    end

    if bet_amount <= 0 then
        SendMessage(sender_id, "Неверная ставка.")
        return
    end

    if eco:value(sender_name, "money") < bet_amount then
        SendMessage(sender_id, "У вас не хватает денег для этой ставки.")
        return
    end

    local opponent_id = MP.GetId(opponent_name)
    SendMessage(opponent_id, "Игрок " .. sender_name .. " вызывает вас на бросок монетки на сумму " .. bet_amount .. " " .. currency .. ". Примите вызов с помощью команды !accept " .. sender_name)
    SendMessage(sender_id, "Вызов игрока " .. opponent_name .. " на бросок монетки на сумму " .. bet_amount .. " " .. currency .. " отправлен.")

    -- Store the coin flip challenge in a table
    coin_flips[sender_name] = {opponent_name = opponent_name, bet_amount = bet_amount}
end

function ACCEPT_COINFLIP(sender_id, sender_name, message)
    local case = split(message, " ")
    local challenger_name = erors(case[1], 2)
    local bet_amount = coin_flips[challenger_name].bet_amount

    if not coin_flips[challenger_name] or coin_flips[challenger_name].opponent_name ~= sender_name then
        SendMessage(sender_id, "Нет активного вызова на бросок монетки от игрока " .. challenger_name .. ".")
        return
    end

    if eco:value(sender_name, "money") < bet_amount then
        SendMessage(sender_id, "У вас не хватает денег для этой ставки.")
        return
    end

    -- Randomly select a winner
    local winner_name = math.random() < 0.5 and challenger_name or sender_name
    local loser_name = winner_name == challenger_name and sender_name or challenger_name

    local commission = bet_amount * config.commissionFlip

    -- Transfer the bet amount from the loser to the winner
    eco:add(winner_name, "money", bet_amount-commission)
    eco:add(loser_name, "money", -bet_amount)

    local currency = config.currency
    SendMessage(-1, "Игрок " .. winner_name .. " выиграл бросок монетки у игрока " .. loser_name .. " и получил " .. bet_amount-commission .. " " .. currency .. ".")

    -- Remove the coin flip challenge from the table
    coin_flips[challenger_name] = nil
end

-- Initialize the coin_flips table
coin_flips = {}

-- LOAD PEREMENNI
eco = Eco:init("players.ixt")
M.eco = eco
M.command = {
	{command = "bal", help = "💵 Узнать баланс. ",func = "BAL"},
	{command = "pay", help = "📨 Перевод денег. ",args = "[name] [money] ",func = "PAY"},
	{category = "eco",command = "add",    help = "💵 Добавить значение.",args = "[name] [path] [value]",func = "ADD",roles = {"admin"}},
	{category = "eco",command = "set",    help = "Установить значение.",args="[name] [path] [value]",func = "SET",roles = {"admin"}},
	{category = "eco",command = "chek",   help = "Узнать баланс игрока. ",args= "[name] [type]", func = "CHEK",roles = {"admin","moder"}},
	{category = "eco",command = "getalltype", help = " Вывести все типы ",func = "GET_ALL_TYPE",roles = {"admin","moder"}},
	{command = "info", help = "Узнать информацию о себе, или предоставить ее другому игроку. ", args = "[name]",func = "MYINFO"},
    {command = "getinfo", help = "Узнать информацию о другом игроке. ", args = "[name]",func = "GETINFO",roles = {"moder","admin"}},
    {command = "coinflip", help = "Вызвать игрока на бросок монетки.", args = "[name] [bet_amount]", func = "COINFLIP"},
    {command = "accept", help = "Принять вызов на бросок монетки.", args = "[name]", func = "ACCEPT_COINFLIP"},
    {command = "roll", help = "Крутить рулетку", args = "[count money]",func = "ROLL"},
    {command = "wipe", help = "Очистить баланс и машину.", args = "[name]",func = "WIPE",roles = {"admin"}},
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