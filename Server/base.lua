local M = {logs = true, debugs = true}
-- Фикс русского языка
os.execute( "chcp 65001 > nul" )
inspect = require "lib/inspect"
M.pluginName = "Economic_Plugin"
function log(message, weight)
	if message == nil or message == "" then goto zcontinue end
	local message = inspect(message)
    weight = weight or 1 -- если вес не указан, используем 0
    
    -- таблица цветов
    local colors = {
		[1] = "\27[0m", -- other
        [2] = "\27[32m", -- зеленый цвет для веса 2, debug
        --[3] = "\27[34m",
		[3] = "\27[36m",  -- синий цвет для веса 3 info
        [4] = "\27[33m", -- желтый цвет для веса 4 warning
        [5] = "\27[31m"  -- красный цвет для веса 5 ERROR
    }
	
	local type = {
		[1] = " LUA",
		[2] = "DEBUG",
		[3] = "INFO",
		[4] = "WARN",
		[5] = "ERROR"
	}
    local color = colors[weight] or "" -- выбираем цвет по весу или пустую строку
    local type = type[weight] or ""
	if weight == 2 and M.debugs == false then 
	else
		--print(debug.traceback())
		local info = debug.getinfo(2,'n')
		local funcname = info.name or debug.getinfo(1,'n').name
		printRaw("["..M.pluginName.."] ["..type.."] ["..funcname.."] ".. color .. message .. "\27[0m")
	end
	::zcontinue::
    end

local pluginPath = debug.getinfo(1).source:gsub("\\","/")
local pluginPath = pluginPath:sub(1,(pluginPath:find("base.lua"))-2)
package.path = package.path .. ";;" .. pluginPath .. "/?.lua;;".. pluginPath .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.dll;;" .. pluginPath .. "/lib/?.dll"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.so;;" .. pluginPath .. "/lib/?.so"
M.pluginPath = pluginPath
log(pluginPath,4)
smallfunc = require "lib/other"
HeventTimer = require("lib/EventTimer")
files = require "lib/io"
files.pluginPath = M.pluginPath
timer = require "lib/timer"
config = load_config("settings/base")
log("Время сервера с учётом коррекции: "..get_hour().." ч. | Коррекция: "..config.corrector.." ч.",4)
--permission = require "lib/permission"
M.onShut = {}

function ThisIsAdmin(Name)
	if Name == "CMD" then return true end
	local admin = load_database("admin.ixt")
	for i,case in ipairs(admin) do
		if case == Name then
			return true
		end
	end
	return false
end

function uptime(sender_id, sender_name, message)
    local EGG = timer.runnig()
	if EGG/3600> 1 then
        SendMessage(sender_id,"Время работы сервера: "..tostring(round(EGG/3600,2)).." ч.")
    elseif EGG/60 > 2 then --Если минуты
        SendMessage(sender_id,"Время работы сервера: "..tostring(round(EGG/60,0)).." мин.")
    else
        SendMessage(sender_id,"Время работы сервера: "..tostring(EGG).." сек.")
    end
end

-- Чат + Консолька

function MyChatMessageHandler(sender_id, sender_name, message)
	return handlers(sender_id, sender_name, message)
end
 
function MyCmdHandler(message)
	return handlers(-2,"CMD",message)
end

function SendMessage(id,message)
	if message == nil then
		message = id
		id = -2
	end
	if id == nil then
		return nil
	end
	if id == -2 or id == "CMD" then -- консолька
		printRaw("["..M.pluginName.."] Message to Console: "..message)
	else
		if type(id) == "string" then
			id = tonumber(id)
		end
		if type(message) ~= "string" then
			message = tostring(message)
		end
		message = split(message,"\n")
        for i,messages in ipairs(message) do
            MP.SendChatMessage(id, messages)
        end
	end
end

MP.SendMessage = SendMessage

function run(case,sender_id,sender_name,message)
	local message = message or ""
	log(case.command.." "..case.func.." "..message.." "..sender_name,2)
	if sender_name ~= "CMD" then
		local permms = permission.decorator(case.roles)
		ret = permms(MP.TriggerLocalEvent,case.reg,sender_id,sender_name,message)
	else
		local ret = MP.TriggerLocalEvent(case.reg,sender_id,sender_name,message)
	end
	return
end

function handlers(sender_id, sender_name, message)
	if message:sub(1,1) ~= "!" then return 0 end -- если сообщение не начинается с "!", возвращаем 0
	local cmd, args = message:match("!([^%s]+)%s*(.*)") -- ищем команду и аргументы в сообщении
	if not cmd then return 0 end -- если команда не найдена, возвращаем 0
	local cmd = "!"..cmd -- bal -> !bal
	for i, case in ipairs(M.command) do -- проходим по массиву команд
	    cmd = cmd:gsub("!", "")
	    if case.category == cmd then
            local cases = split(args," ")
            if cases[1] == case.command then
                local message = args:sub(#case.command+2,#args) -- обрезаем аргументы до нужной длины
                log((case.admin and "Admin" or "NonAdmin") .. "Func_" .. message, 2)
                run(case, sender_id, sender_name, message) -- выполняем команду
                return 1
            end
        else
            if cmd == case.command and case.category == nil then
                --local message = args:sub(1, case.admin and -2 or #args) -- обрезаем аргументы до нужной длины
                --local args = args:sub(#case.command+1,#args)
                log((case.admin and "Admin" or "NonAdmin") .. "Func_" .. message, 2)
                run(case, sender_id, sender_name, args) -- выполняем команду
                return 1
            end
	    end
	end

	return 0 -- если команда не найдена, возвращаем 0
end

-- Import
function import(NameModule, com, adver)
	local status, Mods = pcall(require, NameModule)
	com = com or true
	adver = adver or true

	if(status) then
		M.onShut[#M.onShut+1] = Mods.unload
		Mods.pluginPath = M.pluginPath
		Mods.group = Group
		Mods.parrent = M
		Mods.load()
		local data = RegEvent(Mods.command)
		if com then
			if Mods.command == nil then log("Нету комманд для base [M.command]",5) end
			M.command = table.merge(M.command,data)
		end
		if adver then
			log("Модуль ["..NameModule.."] Успешно Импортировано",3)
		end
		return Mods
	else
		log(Mods,5)
		log("У вас отсутствует Плагин "..NameModule..". Обратитесть к [КиШ] Хлебушек Игорь#8603",4)
	end
end

function ProxyRun(sender_id, sender_name, message)
	local name = split(message," ")[1]
	message = message:sub(#name+2,#message)
	log(message,3)
	handlers(-2, name, message)
end

function string:is_integer()
	local status, result = pcall(tonumber,self)
	if not status or result == nil then
		return false
	end
	return self == tostring(math.floor(result))
end

function HELP(sender_id, sender_name, message)
	local page = 0
	local line = 10
	local category_target = ""
	local text_message = ""
	if message == "" then
		page = 10
	elseif message:is_integer() then
		page = tonumber(message)*line
	else
		local all_category = {}
		local cleared = {}
		for i,case in ipairs(M.command) do
			if case.category ~= nil then
				all_category[case.category] = true
			end
		end
		for i,case in ipairs(all_category) do
			if case.category == message then
				cleared[i] = case
			end
		end
		message = levi(message,cleared,2)
		category_target = message
	end

	if category_target ~= "" then
		for i,case in ipairs(M.command) do
			if case.category == category_target and (case.hide == false or case.hide == nil) then
				text_message = text_message..(permissions:role_in_roles('admin',case.roles) and "[A]" or "")..config.prefix..""..case.category.." "..case.command.." "..case.args.." |\t "..case.help.."\n"
			end
		end
	else
		local trues = {}
		for i,case in ipairs(M.command) do
			if (page-10 < i and i <= page) and case.hide == false then
				if trues[case.roles] == true or permissions:roles_in_roles(case.roles,sender_name) then
					trues[case.roles] = true
					if permissions:role_in_roles('admin',case.roles) then
						if case.category == nil then
							text_message = text_message.. '[A]'..config.prefix..""..case.command.." "..case.args.." |\t "..case.help.."\n"
						else
							text_message = text_message.. '[A]'..config.prefix..""..case.category.." "..case.command.." "..case.args.." |\t "..case.help.."\n"
						end
					else
						if case.category == nil then
							text_message = text_message..config.prefix..""..case.command.." "..case.args.." |\t "..case.help.."\n"
						else
							text_message = text_message..config.prefix..""..case.category.." "..case.command.." "..case.args.." |\t "..case.help.."\n"
						end
					end
				end
			end
		end
	end

	if text_message ~= "" and category_target == "" then
		text_message = text_message.."-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_\n"
		text_message = text_message.."!help "..round((page/10)+1,0).." | Для просмотра следующей страницы напишите"
		if page == 10 then
			text_message = text_message.."\n!help [Название категории] | Для просмотра всех комманд по категориям (car,eco,roles,time,geo,work,prava,whitelist,env)\n"
		end
	end
	page = page/10
	if text_message == "" and page < 20 then
		text_message = "Дальше ничего нет :("
	elseif text_message == "" and page == 314 then
		text_message = "Думаешь ты самый умный?"
	elseif text_message == "" and page == 777 then
		text_message = "Ого пасхалка, но где?"
	elseif text_message == "" and page == 666 then
		text_message = "А мы не ангелы, парень!\nНет, мы не ангелы\nТёмные твари, и сорваны планки нам\nЕсли нас спросят\nЧего мы хотели бы?\nМы бы взлетели\nМы бы взлетели\nМы не ангелы, парень!"
	elseif text_message == "" and page == 1488 then
		text_message = "Мы сообщим в соответствующие органы!\nА может и не сообщаем :)"
	elseif text_message == "" and page < 100 and page >= 20 then
		text_message = "Ничего нет :("
	elseif text_message == "" and page < 1000 and page >= 100 then
		text_message = "Ты думаешь я вру ??"
	elseif text_message == "" and page < 10000 and page >= 1000 then
		text_message = "Ну ну"
	elseif text_message == "" and page < 100000 and page >= 10000 then
		text_message = "Пусто"
	elseif text_message == "" and page < 100000 and page >= 10000 then
		text_message = "Ну тут реально ничего нету :("
	elseif text_message == "" and page < 1000000 and page >= 100000 then
		text_message = "Интересно когда тебе надоест"
	elseif text_message == "" and page < 10000000 and page >= 1000000 then
		text_message = "Ну ладно ищи дальше"
	elseif text_message == "" and page < 100000000 and page >= 10000000 then
		text_message = "."
	elseif text_message == "" and page < 1000000000 and page >= 100000000 then
		text_message = ".."
	elseif text_message == "" and page < 10000000000 and page >= 100000000 then
		text_message = "..."
	elseif text_message == "" and page < 100000000000 and page >= 1000000000 then
		text_message = "."
	elseif text_message == "" and page < 1000000000000 and page >= 10000000000 then
		text_message = ".."
	elseif text_message == "" and page < 10000000000000 and page >= 10000000000 then
		text_message = "ДАЛЬШЕ НИЧЕГО НЕТУ"
	elseif text_message == "" and page < 100000000000000 and page >= 100000000000 then
		text_message = "..."
	elseif text_message == "" and page < 1000000000000000 and page >= 1000000000000 then
		text_message = "ТЕБЕ НАСТОЛЬКО НЕХЕР ДЕЛАТЬ? НУ ИДИ ДОЕБИСЬ ДО БЛИЖАЙШЕГО ИГРОКА"
	elseif text_message == "" and page < 10000000000000000 and page >= 10000000000000 then
		text_message = "Ты доказал свою верность!\nДавай поиграем в игру.\nОставь хештег в nrp '#ЯНЕЛОХ'\nСмысл игры прост, узнать как скоро большинство на сервере узнает о этой игре.\nПравил всего 3\n 1) Кто первый расскажет откуда узнал о этой штуке получит обнуление аккаунта. \n 2) Не давай намёков другим что знаешь!\n 3) Не порть интерес другим игрокам, не будь сукой :)\n Ну что игра началась? :)\nП.С. Можно не играть,просто не отправляй сообщение"
	elseif text_message == "" then
		text_message = "НИКОМУ НЕ РАССКАЗЫВАЙ ;)"
	end
	SendMessage(sender_id,text_message)
	return "pass"
end

-- End Import
M.config = config.prefix
M.command = {
{command = "help",help = "Показать команды.",func = "HELP"},
{command = "uptime",help = "Получить время работы сервера.",func = "uptime"},
{command = "PROXY",help = "", args = "[от чьего лица] [args1] [args2] [argsN]",func = "ProxyRun",roles = {"admin"}},
}

function OPTIMIZATOR()
	local c1 = collectgarbage("count") -- получаем текущий размер памяти
	collectgarbage("collect") -- выполняем сбор мусора
	local count2 = collectgarbage("count") -- получаем размер памяти после сбора
	log("Освобождено памяти: " .. (round(((c1 - count2)),2)).. " кб",5)
end

function onInit()
    log("base.lua",2)
	M.command = RegEvent(M.command)
	Economic = import("Economic")
	permission = import "Permission"
	TimeCounter = import("CountPlaydTime")
	Gps = import("Geo")
	Work = import("Works")
	Cars = import("Cars")
	ban = import("ban")
	Promos = import("PromoCode")
	D2S = import("D2S")
	AutoPrava = import("AutoDrive")
	Sblocker = import("S2C",true,true)  --Назввание файла, Добавлять ли команды в хелп, Оповестить о импорте
	RolePlay = import("RolePlay")
    EnvSync = import("EnvSync")

	HeventTimer.addFunc(check_request_save_database, 5) -- 10 секунд иногда слишком долго
	HeventTimer.addFunc(OPTIMIZATOR,600) -- раз в 10 минут
	HeventTimer.addFunc(SaveCarEveryXsec, 1) --, MP.CallStrategy.Precise

	MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
	MP.RegisterEvent("onConsoleInput", "MyCmdHandler")
	MP.RegisterEvent("STOP", "onShutdown")
end

function onShutdown()
	for _,case in pairs(M.onShut) do
		log("Выключение подсистемы",3)
		case()
	end
	exit()
end 
return M
