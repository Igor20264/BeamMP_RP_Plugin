local M = {logs = true, debugs = true}
-- Фикс русского языка
os.execute( "chcp 65001 > nul" )
inspect = require "lib/inspect"

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
print(pluginPath)
M.pluginName = "Economic_Rework_BeamMP_RP_Plugin_Ver"
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
-- -2 вернуть в консоль
function DiscordApiHandler(sender_name,message)
	return handlers(-3,sender_name,message)
end

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

function handlers(sender_id, sender_name, message) --Create by OpenGPT 
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

function HELP(sender_id, sender_name, message)
	local trues = {}
	for i,case in ipairs(M.command) do
		if case.hide ~= true then
			if trues[case.roles] == true or permissions:roles_in_roles(case.roles,sender_name) then
				trues[case.roles] = true
				if permissions:role_in_roles('admin',case.roles) then
					if case.category == nil then
						SendMessage(sender_id, '[A]'..config.prefix..""..case.command.." "..case.args.." |\t "..case.help)
					else
						SendMessage(sender_id,'[A]'..config.prefix..""..case.category.." "..case.command.." "..case.args.." |\t "..case.help)
					end
				else
					if case.category == nil then
						SendMessage(sender_id,config.prefix..""..case.command.." "..case.args.." |\t "..case.help)
					else
						SendMessage(sender_id,config.prefix..""..case.category.." "..case.command.." "..case.args.." |\t "..case.help)
					end
				end
			end
		--[[
		if case.category == nil then
			if case.admin == true and ta == true then
				SendMessage(sender_id,"[A]:\t"..Color.purple(config.prefix..""..case.command).." "..case.args.." |\t "..case.help)
			elseif case.admin ~= true then
				SendMessage(sender_id,Color.cyan(config.prefix..""..case.command).." "..case.args.." |\t "..case.help)
			end
		else
			if case.admin == true and ta == true then
				SendMessage(sender_id,"[A]:\t"..Color.purple(config.prefix..""..case.category.." "..case.command).." "..case.args.." |\t "..case.help)
			elseif case.admin ~= true then
				SendMessage(sender_id,Color.cyan(config.prefix..""..case.category.." "..case.command).." "..case.args.." |\t "..case.help)
			end
		end
		--]]
		end
	end
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
	local c2 = collectgarbage("count")
	local alpha = ((c1-c2))
	collectgarbage("collect") -- выполняем сбор мусора
	local count2 = collectgarbage("count") -- получаем размер памяти после сбора
	log("Освобождено памяти: " .. (round(((c1 - count2)-(alpha*3)),2)).. " кб",5)
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
	HeventTimer.addFunc(OPTIMIZATOR,60) -- раз в 10 минут
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
