local M = {logs = true, debugs = true}

-- Фикс русского языка
os.execute( "chcp 65001 > nul" )

inspect = require "lib/inspect"

function log(message, weight)
    if message == nil or message == "" then
        return
    end

    local message = inspect(message)
    weight = weight or 1 -- если вес не указан, используем 0
    
    -- таблица цветов
    local colors = {
        [1] = "\27[0m", -- other
        [2] = "\27[32m", -- зеленый цвет для веса 1, debug
        --[3] = "\27[34m", -- синий цвет для веса 2 info 
        [3] = "\27[36m",
        [4] = "\27[33m", -- желтый цвет для веса 4 warning
        [5] = "\27[31m"  -- красный цвет для веса 5 ERROR
    }
    
    local type_names = {
        [1] = " LUA",
        [2] = "DEBUG",
        [3] = "INFO",
        [4] = "WARN",
        [5] = "ERROR"
    }

    local color = colors[weight] or "" -- выбираем цвет по весу или пустую строку
    local type_name = type_names[weight] or ""
    
    if weight == 2 and not M.debugs then 
        return
    end

    local info = debug.getinfo(2, 'n')
    local funcname = info.name or debug.getinfo(1, 'n').name
    
    -- Получаем текущую дату и время
    local current_datetime = os.date("%Y-%m-%d %H:%M:%S", os.time() + 3600)

    local log_message = "[" .. current_datetime .. "] [" .. M.pluginName .. "] [" .. type_name .. "] [" .. funcname .. "] " .. color .. message .. "\27[0m"

    local file = io.open("log.txt", "a")  -- "a" режим для добавления в файл
    if file then
        file:write(log_message .. "\n")
        file:close()
    else
        print("Error opening log file")
    end
    printRaw(log_message)
end

local pluginPath = debug.getinfo(1).source:gsub("\\","/")
local pluginPath = pluginPath:sub(1,(pluginPath:find("base.lua"))-2)
package.path = package.path .. ";;" .. pluginPath .. "/?.lua;;".. pluginPath .. "/lua/?.lua"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.dll;;" .. pluginPath .. "/lib/?.dll"
package.cpath = package.cpath .. ";;" .. pluginPath .. "/?.so;;" .. pluginPath .. "/lib/?.so"
M.pluginPath = pluginPath 
M.pluginName = "Economic_Rework"
smallfunc = require "lib/other"
reg = require "lib/RegEvent"
files = require "lib/io"
timer = require "lib/timer"
files.pluginPath = M.pluginPath
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
		local id = tonumber(id)
		local message = tostring(message)
		MP.SendChatMessage(id, message)
	end
end

MP.SendMessage = SendMessage

function run(case,sender_id,sender_name,message)
	--local message = message:sub(#case.command+2,#message)
	local message = message or ""
	log(case.command.." "..case.func.." "..message.." "..sender_name,2)
	local ret = MP.TriggerLocalEvent(case.reg,sender_id,sender_name,message)
	return 1
end

function handlers(sender_id, sender_name, message)
    if message:sub(1, 1) ~= "!" then 
        return 0 -- если сообщение не начинается с "!", возвращаем 0
    end
    
    local cmd, args = message:match("!([^%s]+)%s*(.*)") -- ищем команду и аргументы в сообщении
    if not cmd then 
        SendMessage(sender_id, "^lДанной команды не существует, список команд можно посмотреть в !help")
        return 1 -- возвращаем 1, чтобы указать, что обработка была выполнена
    end
    
    cmd = cmd:lower() -- преобразование команды к нижнему регистру
    local cmd = "!" .. cmd
    local commandExists = false
    for i, case in ipairs(M.command) do -- проходим по массиву команд
        if cmd == case.command:lower() then -- если нашли нужную команду
            commandExists = true
            if case.admin and not ThisIsAdmin(sender_name) then -- если команда требует прав администратора, но отправитель не является администратором
                SendMessage(sender_id, "У вас отсутствуют нужные полномочия")
                return 1 -- возвращаем 1, чтобы указать, что обработка была выполнена
            end
            local message = message:sub(#case.command + 1, #message)
            log((case.admin and "Admin" or "NonAdmin") .. "Func_" .. message, 2)
            run(case, sender_id, sender_name, message) -- выполняем команду
            return 1 -- возвращаем 1, чтобы указать, что обработка была выполнена
        end
    end

    if not commandExists then
        SendMessage(sender_id, "^lДанной команды не существует, список команд можно посмотреть в !help")
        return 1 -- возвращаем 1, чтобы указать, что обработка была выполнена
    end

    return 0 -- если команда не найдена, возвращаем 0
end

--small func
--file:///S:\Desktop\BeamMPGit\BeamMP\Resources\Server\Economic_Rework\lib\other.lua
Group = require "Group"
-- Import
function import(NameModule,com,adver)
	local status, Mods = pcall(require, NameModule)
	if com == nil then com = true end
	if adver == nil then adver = true end
	if(status) then
		M.onShut[#M.onShut+1] = Mods.unload
		Mods.pluginPath = M.pluginPath
		Mods.group = Group
		Mods.load() 
		log("[PostLoad] OK",2)
		if com then
			if Mods.command == nil then log("Нету комманд для base [M.command]",5) end
			M.command = table.merge(M.command,Mods.command)
		end
		if adver then
			log("Модуль ["..NameModule.."] Успешно Импортированно",3)
		end
		return Mods
	else
		log(Mods,5)
		log("У вас отсутствует Плагин "..NameModule..". Обратитесть к [КиШ] Хлебушек Игорь#8603",4)
	end
end

function HELP(sender_id, sender_name, message)

	local ta = ThisIsAdmin(sender_name) 
	for i,case in ipairs(M.command) do
		if case.hide ~= true then
			if case.admin == true and ta == true then
				SendMessage(sender_id,"[A]: "..case.help)
			elseif case.admin ~= true then
				SendMessage(sender_id,case.help)
			end
		end
	end
	return "pass"
end

-- End Import 
M.config = "!"
M.command = {{command = M.config.."help",help = "^3^l!help^r - Показать команды. ",func = "HELP",admin = false,hide = false}}

function onInit()  
	M.command = RegEvent(M.command)
	Economic = import("Economic") --Назввание файла, Добавлять ли команды в хелп, Оповестить о импорте
	reiting = import("Reit")
	ban = import("ban")
	Kazik = import("Kazik")
	Sblocker = import("S2C",true,true)
	MP.RegisterEvent("onChatMessage", "MyChatMessageHandler")
	MP.RegisterEvent("onConsoleInput", "MyCmdHandler")
	MP.RegisterEvent("STOP", "onShutdown") 
end

function onShutdown()
	for i,case in pairs(M.onShut) do
		log("Выключение подсистемы",3)
		case()
	end
	exit()
end 
return M