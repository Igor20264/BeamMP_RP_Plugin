local M = {logs = true, debugs = true}
-- Фикс русского языка
os.setlocale( "C", "ctype" );
os.execute( "chcp 65001 > nul" )

math.randomseed(os.clock()*os.clock())

inspect = require "lib/inspect"

function log(message, weight)
	if message == nil or message == "" then goto zcontinue end
	message = inspect(message,unpack)
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

function table:extended(parent)
    setmetatable(self,{__index = parent})
end

function extended(child, parent)
    setmetatable(child,{__index = parent})
end


local pluginPath = debug.getinfo(1).source:gsub("\\","/")
pluginPath = pluginPath:sub(1,(pluginPath:find("base.lua"))-2)
package.path = package.path .. ";;" .. pluginPath .. "/?.lua;;".. pluginPath .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.dll;;" .. pluginPath .. "/lib/?.dll"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.so;;" .. pluginPath .. "/lib/?.so"
M.pluginName = "Economic_Plugin"
M.pluginPath = pluginPath
M.onShut = {}
M.command = {}

log(pluginPath,4)
smallfunc = require "lib/other"
HeventTimer = require("lib/EventTimer")
files = require "lib/io"
files.pluginPath = M.pluginPath
notify = require "lib/notify"
timer = require "lib/timer"
config = load_config("settings/base")
log("Время сервера с учётом коррекции: "..get_hour().." ч. | Коррекция: "..config.corrector.." ч.",4)

-- Чат + Консолька

function MyChatMessageHandler(sender_id, sender_name, message)
	return handlers(sender_id, sender_name, message)
end
 
function MyCmdHandler(message)
	return handlers(-2,"CMD",message)
end
-- @param text string
-- @param playerId number
-- @param category string
-- @param icon string
--[[ maybi text
ServerNotify(0,'lox','instability', "warning")
 5, "bullettime"
 0, 'MINIMAP_HELP'
 6, "refueling"
 5, "replay"
]]
function ServerNotify(playerId,text,category,icon)
	MP.SendNotification(playerId, text, category, icon)
end

--MP.TriggerClientEvent(0, "PacketNotify", Util.JsonEncode({color="yellow", title="LOX", text="PIDOR"}))
function SendNotify(playerId, color, title, text)
    --'yellow': notification.type === 'yellow',
    -- 'red': notification.type === 'red',
    -- 'green': notification.type === 'green'
    if color == "yellow" then
        MP.TriggerClientEvent(playerId, "PacketNotify", Util.JsonEncode({color="yellow", title=title, text=text}))
    elseif color == "red" then
        MP.TriggerClientEvent(playerId, "PacketNotify", Util.JsonEncode({color="red", title=title, text=text}))
    elseif color == "green" then
        MP.TriggerClientEvent(playerId, "PacketNotify", Util.JsonEncode({color="green", title=title, text=text}))
    else
        log("Неизвестный цвет уведомления: " .. color,3)
    end
end

function SendMessage(id,message) --todo add support notification by offline
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
		if type(message) ~= "string" then
			message = tostring(message)
		end
		if is_integer(id) then
			id = tonumber(id)
		elseif MP.GetId(id) == nil then
			-- SaveOffline
			notify:addNotification(id,message)
			return
		end

		if #message <= 200 then
			SendNotify(id, "yellow", "Оповещение", message)
		end
		message = split(message,"\n")
        for _,messages in ipairs(message) do
            MP.SendChatMessage(id, messages)
        end
	end
end

MP.SendMessage = SendMessage

function run(case,sender_id,sender_name,message)
	message = message or ""
	log(case.command.." "..case.func.." "..message.." "..sender_name,2)
	if sender_name ~= "CMD" then
		local permms = permission.decorator(case.roles)
		permms(MP.TriggerLocalEvent,case.reg,sender_id,sender_name,message)
	else
		MP.TriggerLocalEvent(case.reg,sender_id,sender_name,message)
	end
	if sender_id ~= -2 then
        MP.TriggerClientEvent(sender_id, "PacketbalanceUpdate", tostring(eco:value(sender_name,"money")))
    end
	return
end

function handlers(sender_id, sender_name, message)
	if message:sub(1,1) ~= "!" then return 0 end -- если сообщение не начинается с "!", возвращаем 0
	local cmd, args = message:match("!([^%s]+)%s*(.*)") -- ищем команду и аргументы в сообщении
	if not cmd then return 0 end -- если команда не найдена, возвращаем 0
	cmd = "!"..cmd -- bal -> !bal
	for _, case in ipairs(M.command) do -- проходим по массиву команд
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
		if Mods == nil then
			log("Вероятно вы ввели неправильное имя модуля [ "..NameModule.." ] или не возвращаете переменную",5)
			return
		end
		M.onShut[#M.onShut+1] = Mods.unload
		Mods.pluginPath = M.pluginPath
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

function OPTIMIZATOR()
	local c1 = collectgarbage("count") -- получаем текущий размер памяти
	collectgarbage("collect") -- выполняем сбор мусора
	local count2 = collectgarbage("count") -- получаем размер памяти после сбора
	log("Освобождено памяти: " .. round((c1 - count2), 2) .. " кб", 5)
end

function onInit()
    log("base.lua",2)
	CoreCommands = import("Core_Commands")--M.command = RegEvent(M.command)
	Economic = import("Economic")
	permission = import "Permission"
	TimeCounter = import("CountPlaydTime")
	Gps = import("Geo")
	Work = import("Works")
	Cars = import("Cars")
	--testDrive = import("TestDrive")
	ban = import("ban")
	--Promos = import("PromoCode")
	D2S = import("D2S")
	AutoPrava = import("AutoDrive")
	Sblocker = import("S2C",true,true)  --Назввание файла, Добавлять ли команды в хелп, Оповестить о импорте
	RolePlay = import("RolePlay")
    EnvSync = import("EnvSync")
	--TEST = import("Test")
	--CheakCheaters = import("CheckCheater")
	HeventTimer.addFunc(check_request_save_database, 5) -- 10 секунд иногда слишком долго
	HeventTimer.addFunc(OPTIMIZATOR,60*60) -- раз в 10 минут
	HeventTimer.addFunc(SaveCarEveryXsec, 1) --, MP.CallStrategy.Precise

	MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
	MP.RegisterEvent("onConsoleInput", "MyCmdHandler")
	--MP.RegisterEvent("onShutdown", "STOP")
end

function onShutdown()
	exit()
end 
return M
