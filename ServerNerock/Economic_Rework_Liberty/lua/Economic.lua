local M = {}
M.promoCodes = {
    ADMINSPECIAL = 100000,
    SCAM = -5000,
    SECRETIK = 10000,
    MIKELOX = -5000,
    MONEYBAG = 25000,
    FREEMONEY = 5000
}
local workEnabled = true
M.info = "Экономическая система"
M.ver = "1.6"

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
function SET(sender_id, sender_name, message)
    local cur = M.config.currency
    local case = split(message, " ")
    case[1] = erors(case[1], 2)
    case[3] = tonumber(case[3])

    -- Проверяем, является ли третий параметр работой или заработной платой
    if case[3] == 5 then
        log("Установить название работы игроку: " .. case[1] .. " в размере " .. case[2])
        eco:set(case[1], 5, case[2])  -- Устанавливаем работу
        local ret = case[1] .. ": " .. eco:bal(case[1], 5)
        SendMessage(sender_id, ret)
    elseif case[3] == 3 then
        log("Установить заработную плату игроку: " .. case[1] .. " в размере " .. case[2])
        eco:set(case[1], 3, tonumber(case[2]))  -- Устанавливаем заработную плату
        local ret = case[1] .. ": " .. eco:bal(case[1], 3)
        SendMessage(sender_id, ret)
    else
        SendMessage(sender_id, "Неверный параметр для установки.")
    end
end

function ADD(sender_id, sender_name, message)
    local cur = M.config.currency
    local case = split(message, " ")
    case[1] = erors(case[1], 2)
    case[3] = tonumber(case[3])

    if case[3] == 2 then 
        if eco.world_balans.money <= 0 then
            SendMessage(sender_id, "Денег нет, но вы держитесь")
        else
            if eco.world_balans.money - tonumber(case[2]) <= 0 then 
                SendMessage(sender_id, "В мире нет столько денег") 
                return 1
            else
                eco:add(case[1], case[3], tonumber(case[2]))
                eco.world_balans.money = eco.world_balans.money - tonumber(case[2])
                local ret = case[1] .. ": " .. eco:bal(case[1], case[3])
                SendMessage(sender_id, ret)
                

                log("Начисление на счет: " .. case[1] .. " в размере " .. case[2], 3)
                
                return 1
            end
        end
    elseif case[3] == 3 then
        eco:add(case[1], case[3], tonumber(case[2]))
        local ret = case[1] .. ": " .. eco:bal(case[1], case[3])
        SendMessage(sender_id, ret)
        return 1
    elseif case[3] == 4 then  
        eco:add(case[1], case[3], tonumber(case[2]))
        local ret = case[1] .. ": " .. eco:bal(case[1], case[3])
        log("Начисление в банк: " .. case[1] .. " в размере " .. case[2], 3)
        SendMessage(sender_id, ret)
        return 1
    elseif case[3] == 1 then  
        SendMessage(sender_id, "У вас нет прав редактировать этот параметр") 
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
working = {}

function START_WORK(sender_id, sender_name, message)
    if not workEnabled then
        SendMessage(sender_id, "Возможность начать работу выключена.")
        return
    end

    local playerCount = MP.GetPlayerCount()
    if playerCount >= M.config.PLAYERMIN then
        if working[sender_name] == nil then
            working[sender_name] = {work = sender_id, Stime = timer:Get()}
            SendMessage(sender_id, "💼 Вы начали работать. Ваша работа: " .. eco:bal(sender_name, 5))
            
            -- Логирование начала работы
            local log_message = "START_WORK - Игрок: " .. sender_name .. " начал работать"
            log(log_message, 3)
        else
            SendMessage(sender_id, "💼 Вы уже работаете.")
        end
    else
        SendMessage(sender_id, "Для работы слишком мало игроков")
    end
end

function STOP_WORK(sender_id, sender_name, message)
    if working[sender_name] then
        local EGG = timer:Get() - working[sender_name].Stime
        local pay = eco:bal(sender_name, 3) * round(EGG / 3600)
        eco:add(sender_name, 4, pay)
        working[sender_name] = nil

        local log_message = "STOP_WORK - Игрок: " .. sender_name .. " | Работал: " .. round(EGG / 3600, 2) .. " ч. | Заплатили: " .. pay .. " " .. M.config.currency
        log(log_message, 3) -- Логирование информации о завершении работы и выплате заработанных средств

        SendMessage(sender_id, "Вы закончили работать. Вам заплатили: " .. pay .. " " .. M.config.currency)
    else
        local log_message = "STOP_WORK - Игрок: " .. sender_name .. " | Не работает"
        log(log_message, 4) -- Логирование информации о попытке завершения работы, когда игрок не работает
        SendMessage(sender_id, "Вы не работаете.")
    end
end

function STAT_WORK(sender_id, sender_name, message)
    if working[sender_name] then
        local EGG = timer:Get() - working[sender_name].Stime
        local earned = round(eco:bal(sender_name, 3) * (EGG / 3600), 0)
        local time_message = ""
        
        if EGG / 60 > 2 then
            time_message = tostring(round(EGG / 60, 0)) .. " мин."
        elseif EGG / 3600 > 1 then
            time_message = tostring(round(EGG / 3600, 0)) .. " ч."
        else
            time_message = tostring(EGG) .. " сек."
        end

        local log_message = "STAT_WORK - Игрок: " .. sender_name .. " | Работает: " .. time_message .. " | Заработано: " .. earned .. " " .. M.config.currency
        log(log_message, 3) -- Логирование информации о времени работы и заработке

        SendMessage(sender_id, "💼 " .. "Вы работали: " .. time_message .. " | Заработано: " .. earned .. " " .. M.config.currency)
    else
        local log_message = "STAT_WORK - Игрок: " .. sender_name .. " | Не работает"
        log(log_message, 4) -- Логирование информации о неработающем игроке
        SendMessage(sender_id, "💼 " .. "Вы не работаете.")
    end
end

function WORKON(sender_id, sender_name, message)
    workEnabled = true
    SendMessage(sender_id, "Возможность начать работу включена.")
end

function WORKOUT(sender_id, sender_name, message)
    workEnabled = false
    SendMessage(sender_id, "Возможность начать работу выключена.")
end

function WHY_WORK(sender_id, sender_name, message)
    log(working, 2)
    for case, data in pairs(working) do
        local player_name = case
        local work_time = timer:Get() - data.Stime

        local work_info = "💼 "..player_name.." работает"

        if work_time / 60 > 2 then
            work_info = work_info.." "..tostring(round(work_time / 60, 0)).." мин."
        elseif work_time / 3600 > 1 then
            work_info = work_info.." "..tostring(round(work_time / 3600, 0)).." ч."
        else
            work_info = work_info.." "..tostring(work_time).." сек."
        end

        -- Получаем ID игрока по его имени
        local id_list = eco:getId(player_name)
        if id_list then
            work_info = work_info.." | Работа: "..eco.s[id_list][5]
        end

        SendMessage(sender_id, work_info)
    end
end

function WHY_WORKS(sender_id, sender_name, message)
    log(working, 2)
    for case, data in pairs(working) do
        local player_name = case

        local work_info = "💼 "..player_name.." "

        -- Получаем ID игрока по его имени
        local id_list = eco:getId(player_name)
        if id_list then
            work_info = work_info.." | Работает: "..eco.s[id_list][5]
        end

        SendMessage(sender_id, work_info)
    end
end

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
function BAL(sender_id, sender_name, message)
    local cur = M.config.currency
    local id_list = eco:getId(sender_name)

    if id_list then
        local balanceInfo = "Баланс игрока "..sender_name.."💵: "..eco.s[id_list][2].." "..cur.." | Зарплата💸: "..eco.s[id_list][3].." "..cur.." за работу💼 "..eco.s[id_list][5].." | В банке🏦: "..eco.s[id_list][4].." "..cur
        SendMessage(sender_id, balanceInfo)
        
        -- Записываем сообщение в лог
        log(balanceInfo, 3, "Message to Console")
    else
        local errorMessage = "Ошибка при получении информации о балансе для игрока "..sender_name
        SendMessage(sender_id, errorMessage)
        
        -- Записываем сообщение об ошибке в лог
        log(errorMessage, 5, "Message to Console")
    end
    
    return 1
end

function formatMoney(amount)
    local formatted = tostring(amount)
    local k = 0
    local len = #formatted
    while k ~= len and (len > k + 3) do
        len = len - 3
        formatted = formatted:sub(1, len) .. '.' .. formatted:sub(len + 1)
    end
    return formatted
end

function BANKPAY(sender_id, sender_name, message)
    local p2, case = MessageParser(message, " ", 2) -- имя и колл-во денег
    local currency = M.config.currency
    
    -- Проверяем, существует ли аккаунт у p2, если p2 не равно "CMD"
    if p2 ~= "CMD" and not eco:inList(p2) then
        SendMessage(sender_id, "Игрок " .. p2 .. " не найден.")
        return 1
    end

    local amount = math.abs(tonumber(case[1]))
    if not amount then
        SendMessage(sender_id, "Некорректная сумма перевода.")
        return 1
    end

    -- Проверяем, достаточно ли денег у отправителя
    if eco:bal(sender_name, 4) >= amount then
        log("Начало передачи денег")
        eco:replaci(sender_name, eco:bal(sender_name, 4) - amount, 4)
        
        if p2 == "CMD" then
            eco.world_balans.money = eco.world_balans.money + amount
			eco:save()	
            local formattedAmount = formatMoney(amount)
            local mess = "Игрок " .. sender_name .. " перевёл в CMD деньги 💵 в размере " .. formattedAmount .. " " .. currency
            log(mess, 3)
            SendMessage(sender_id, mess)
        else
            eco:replaci(p2, eco:bal(p2, 4) + amount, 4)
            eco:save()
            local formattedAmount = formatMoney(amount)
            local mess = "Игрок " .. sender_name .. " перевёл игроку " .. p2 .. " деньги 💵 в размере " .. formattedAmount .. " " .. currency
            log(mess, 3)
            SendMessage(sender_id, mess)
            
            -- Оповещаем получателя, если он онлайн
            if MP.check_in_online(p2) then
                SendMessage(MP.GetId(p2), mess)
            end
        end
    else
        SendMessage(sender_id, "У вас не хватает денег 💵 в банке | Положить деньги в банк !put [money]")
    end
    return 1
end

function PAY(sender_id, sender_name, message) -- Перевод от одного к другому
    local p2, case = MessageParser(message, " ", 2) -- имя и колл-во денег
    local currency = M.config.currency
    local limit = M.config.limit_pay

    -- Проверяем, существует ли аккаунт у p2, если p2 не равно "CMD"
    if p2 ~= "CMD" and not eco:inList(p2) then
        SendMessage(sender_id, "Игрок " .. p2 .. " не найден.")
        return 1
    end

    local amount = math.abs(tonumber(case[1]))
    if not amount then
        SendMessage(sender_id, "Некорректная сумма перевода.")
        return 1
    end

    -- Проверяем, достаточно ли денег у отправителя
    if eco:bal(sender_name, 2) >= amount then
        if amount <= limit then
            log("Начало передачи денег")
            eco:replaci(sender_name, eco:bal(sender_name, 2) - amount, 2)

            if p2 == "CMD" then
                eco.world_balans.money = eco.world_balans.money + amount
                eco:save()
                local formattedAmount = formatMoney(amount)
                local mess = "Игрок " .. sender_name .. " перевёл в CMD деньги 💵 в размере " .. formattedAmount .. " " .. currency
                log(mess, 3)
                SendMessage(sender_id, mess)
            elseif MP.check_in_online(p2) then
                eco:replaci(p2, eco:bal(p2, 2) + amount, 2)
                eco:save()
                local formattedAmount = formatMoney(amount)
                local mess = "Игрок " .. sender_name .. " передал игроку " .. p2 .. " деньги 💵 в размере " .. formattedAmount .. " " .. currency
                log(mess, 3)
                SendMessage(sender_id, mess)
                
                -- Оповещаем получателя, если он онлайн
                SendMessage(MP.GetId(p2), mess)
            else
                -- Возвращаем средства, если p2 не онлайн и не CMD
                eco:replaci(sender_name, eco:bal(sender_name, 2) + amount, 2)
                eco:save()
                SendMessage(sender_id, "Игрок " .. p2 .. " не в сети. Перевод не выполнен.")
            end
        else
            SendMessage(sender_id, "Превышен лимит передачи денег | лимит " .. formatMoney(limit) .. " | Используйте команду !bpay [name] [money]")
        end
    else
        SendMessage(sender_id, "У вас не хватает денег 💵")
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
        local log_message = "REM - Игрок: " .. sender_name .. " | Снял из банка: " .. tonumber(message) .. " " .. currency
        log(log_message, 3) -- Логирование информации о времени работы и заработке		
		SendMessage(sender_id, mess)
	else
		SendMessage(sender_id, "У вас не хватает денег 💵")
	end
	return 1
end

function STOP_WORK_FOR_PLAYER(admin_id, admin_name, message)
    local target_name = message:gsub("^%s*(.-)%s*$", "%1")  -- Имя игрока, чью работу нужно завершить

    print("Target name: [" .. target_name .. "]")  -- Добавьте эту строку для отладки

    if working[target_name] then
        local EGG = timer:Get() - working[target_name].Stime
        local pay = eco:bal(target_name, 3) * round(EGG / 3600)
        eco:add(target_name, 4, pay)
        working[target_name] = nil
        SendMessage(admin_id, "Работа игрока " .. target_name .. " завершена. Ему заплачено: " .. pay .. " " .. M.config.currency)
    else
        SendMessage(admin_id, "Игрок " .. target_name .. " не работает.")
    end
end

function PROMO(sender_id, sender_name, message)
    local promoCode = message:upper():gsub("^%s*(.-)%s*$", "%1")  -- Извлекаем промокод из сообщения и преобразуем в верхний регистр

    -- Загружаем информацию о использованных промокодах из файла IXT
    local usedPromoCodes = load_database("USED_PROMO_CODES.IXT") or {}

    if M.promoCodes[promoCode] == nil then
        SendMessage(sender_id, "Неверный промокод.")
    elseif M.promoCodes[promoCode] then
        -- Проверяем, не использовался ли промокод ранее текущим пользователем
        if usedPromoCodes[sender_name] and usedPromoCodes[sender_name][promoCode] then
            SendMessage(sender_id, "Вы уже использовали этот промокод.")
            return
        end

        -- Промокод не использовался
        local currencyAmount = M.promoCodes[promoCode]
        eco:add(sender_name, 2, currencyAmount)  -- Начисление валюты игроку
        SendMessage(sender_id, "Промокод успешно активирован! Вам начислено " .. currencyAmount .. " валюты.")

        -- Записываем ник игрока и использованный промокод в таблицу использованных промокодов
        if not usedPromoCodes[sender_name] then
            usedPromoCodes[sender_name] = {}
        end
        usedPromoCodes[sender_name][promoCode] = true

        -- Сохраняем данные в файле IXT
        save_database("USED_PROMO_CODES.IXT", usedPromoCodes)
    else
        SendMessage(sender_id, "Промокод уже был использован.")
    end
end

function CHECKBAL(sender_id, sender_name, message)
    local cur = M.config.currency
    local playerName = message:gsub("^%s*(.-)%s*$", "%1")  -- Извлекаем имя игрока из сообщения
    local id_list = eco:getId(playerName)  -- Получаем ID игрока по его имени

    -- Проверяем, существует ли такой игрок
    if id_list then
        local balanceInfo = "Баланс игрока "..playerName.."💵: "..eco.s[id_list][2].." "..cur.." | Зарплата💸: "..eco.s[id_list][3].." "..cur.." за работу💼 "..eco.s[id_list][5].." | В банке🏦: "..eco.s[id_list][4].." "..cur
        SendMessage(sender_id, balanceInfo)
        
        -- Записываем сообщение в лог
        log(balanceInfo, 3, "Message to Console")
    else
        local errorMessage = "Игрок с именем "..playerName.." не найден."
        SendMessage(sender_id, errorMessage)
        
        -- Записываем сообщение об ошибке в лог
        log(errorMessage, 5, "Message to Console")
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
        local log_message = "PUT - Игрок: " .. sender_name .. " | Положил в банк: " .. tonumber(message) .. " " .. currency
        log(log_message, 3) -- Логирование информации о времени работы и заработке				
		SendMessage(sender_id, mess)
	else
		SendMessage(sender_id, "У вас не хватает денег 💵")
	end
	return 1
end

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
	{command = prefix.."bal", help = "^3^l!bal^r - 💵 Узнать баланс. ", func = "BAL",admin = false,hide = false},
	{command = prefix.."check", help = "^3^l!checkbal^r [Игрок] - 💵 Проверить баланс игрока. ", func = "CHECKBAL", admin = true, hide = false},
	{command = prefix.."pay", help = "^3^l!pay^r [name] [money] - 📨 Перевод денег. ",func = "PAY",admin = false,hide = false},
	{command = prefix.."payday", help = "^3^l!payday^r - Начисление зарплат. ", func = "PAYDAY",admin = true,hide = false},
	{command = prefix.."add", help = "^3^l!add^r [name] [money] [type] |-,$,payday,-,Work| 💵 Добавить денег из бюджета. ",func = "ADD",admin = true,hide = false},
	{command = prefix.."set", help = "^3^l!set^r [name] [money] [type] |-,$,payday,-,Work| Установить значение. ",func = "SET",admin = true,hide = false},
	{command = prefix.."rem", help = "^3^l!rem^r [money] - 🏦 Снять деньги из банка. ",func = "REM",admin = false,hide = false},
	{command = prefix.."put", help = "^3^l!put^r [money] - 🏦 Положить деньги в банк. ",func = "PUT",admin = false,hide = false},
	{command = prefix.."bpay", help = "^3^l!bpay^r [name] [money] - 📨 Перевод денег из банка в банк. ", func = "BANKPAY",admin = false,hide = false},
	{command = prefix.."chek", help = "^3^l!chek^r [name] [type] |name,$,payday,bank,Work,tax| Узнать баланс игрока. ", func = "CHEK",admin = true,hide = false},
	{command = prefix.."workstart", help = "^3^l!workstart^r - 💼 Начать работу ",func = "START_WORK",admin = false,hide = false},
	{command = prefix.."workstop", help = "^3^l!workstop^r - 💼 Закончить работу ",func = "STOP_WORK",admin = false,hide = false},
	{command = prefix.."workinfo", help = "^3^l!workinfo^r - 💼 Сколько я работал? ",func = "STAT_WORK",admin = false,hide = false},
	{command = prefix.."workoff", help = "^3^l!workoff^r [name] - Завершить работу игрока. ", func = "STOP_WORK_FOR_PLAYER", admin = true, hide = false},
	{command = prefix.."workwhy", help = "^3^l!workwhy^r - 💼 Кто работает. ",func = "WHY_WORK",admin = true,hide = false},
	{command = prefix.."works", help = "^3^l!works^r - 💼 Кто работает. ",func = "WHY_WORKS",admin = false,hide = false},	
	{command = prefix.."promo", help = "^3^l!promo^r [промокод] - Активировать промокод. ", func = "PROMO", admin = false, hide = false},
	{command = prefix.."workon", help = "^3^l!workon^r - Включить возможность начать работу", func = "WORKON", admin = true, hide = false},
	{command = prefix.."workout", help = "^3^l!workout^r - Выключить возможность начать работу", func = "WORKOUT", admin = true, hide = false}
}

function M.load() 
    usedPromoCodes = load_database("USED_PROMO_CODES.IXT") or {}
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
	save_database("USED_PROMO_CODES.IXT", usedPromoCodes)
end

return M
