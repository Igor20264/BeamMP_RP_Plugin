local M = {}

function onPlayerAuth(name,role,is_guest)
	log("Проверка "..name.." на банлист.",2)
	for i,case in ipairs(DB_BAN) do
		if case[1] == name then
			return "Узнать подробности можно в Дискорде. "..M.config.url
		end
	end
	return 0
end

function onConnectPlayer(id)  
	local Id = MP.GetBeamId(MP.GetPlayerName(id))
	for i,case in ipairs(DB_BAN) do
		if Id == case[2] then -- -- Список запретов
			MP.DropPlayer(id,"Узнать подробности можно в Дискорде. "..M.config.url)
			return "Узнать подробности можно в Дискорде. "..M.config.url
		end
	end
end 
 
function unban(sender_id, sender_name, message)
	local name = split(message," ")[1]
	for i,case in ipairs(DB_BAN) do 
		if case[1] == name then 
			table.remove(DB_BAN,i) 
			local mess = ""..name.." был разбанен"
			SendMessage(sender_id,mess)
			save_database("BANLIST.IXT",DB_BAN)
			return 1
		end 
	end
	local mess = ""..name.." не находится в бане"
	SendMessage(sender_id,mess)
	return 1
	end

function kick(sender_id, sender_name, message)
	local qt = split(message,'#')
	MP.DropPlayer(MP.GetId(qt[1]),qt[2])
	SendMessage(sender_id,qt[1].." был кикнут с причиной "..qt[2])
 end
 
function fast_ban(sender_id, sender_name, message)
	local name = erors(split(message," ")[1],2)
	local reaseon = "Узнать подробности можно в Дискорде. "..M.config.url
	if MP.check_in_online(name) == true then
		MP.DropPlayer(MP.GetId(name),reaseon)
		DB_BAN[#DB_BAN+1]={name,MP.GetBeamId(name)}
		save_database("BANLIST.IXT",DB_BAN)
		local mess = name.." был забанен"
		SendMessage(-1,mess)
		return mess
	else 
		local mess = "Проверьте написание"
		SendMessage(sender_id,mess)
	end
end
M.config = load_config("settings/ban")
command = {
	{command =M.config.prefix.."unban", help ="Разбан игрока. "..M.config.prefix.."unban [name]",func ="unban",admin = true,hide = false},
	{command =M.config.prefix.."kick", help ="Кик Игрока. "..M.config.prefix.."kick [name]#[reason]",func ="kick",admin = true,hide = false},
	{command =M.config.prefix.."fban", help ="Бан со ссылкой на сервер. "..M.config.prefix.."fban [name]",func ="fast_ban",admin = true,hide = false}
	}
M.command = command
function M.load()
	DB_BAN = load_database("BANLIST.IXT")
	--prefix = load_file()['prefix']
	M.command=RegEvent(M.command)
	MP.RegisterEvent("onPlayerAuth","onPlayerAuth")
	MP.RegisterEvent("onPlayerConnecting","onConnectPlayer")
end

function M.unload()
	save_database("BANLIST.IXT",DB_BAN)
end

return M